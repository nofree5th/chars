.include "macro-inl.s"

.globl term_fd
.globl _start

.data
#=======================
    term_fd: .int 1
    term   : .asciz "/dev/tty"
    msg    : .asciz "hello world\n"
    .equiv len, . - msg

.bss
#=======================
    .equiv termios_lflag, 12
    .equiv termios_cc_VMIN, 17 + 6
    .equiv termios_cc_VTIME, 17 + 5
    .lcomm old_termios, 60
    .lcomm cur_termios, 60

.text
#=======================
#-----------------------
# entrance
_start:
    # open tty
    open $term, $O_RDWR
    movl %eax, term_fd

    # setup env
    #   get original
    ioctl term_fd, $TCGETS, $old_termios

    #   make copy
    movl $old_termios, %esi
    movl $cur_termios, %edi
    movl $60 / 4, %ecx
    rep movsl

    andl $TTY_MODE, cur_termios + termios_lflag
    movb $0, cur_termios + termios_cc_VTIME
    movb $0, cur_termios + termios_cc_VMIN
    ioctl term_fd, $TCSETS, $cur_termios



    call hide_cursor
    call clear_screen
    movw $1, %ax
    movw $1, %bx
    call set_cursor_pos

    # run
    call game_loop

    # recover env
    call show_cursor
    ioctl term_fd, $TCSETS, $old_termios
    exit $0

#-----------------------
# func game_loop
.type game_loop, @function
game_loop:
    mov $100, %eax
    call msleep

    call getch
    cmpb $'q', %al
    je quit
    cmpb $0, %al
    je game_loop

    call red
    write term_fd, $msg, $len


    jmp game_loop
quit:
    ret

