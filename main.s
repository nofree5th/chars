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
    .lcomm cur_termios, 60

.text
#=======================
#-----------------------
# entrance
_start:
    # open tty
    open $term, $O_RDWR
    movl %eax, term_fd

    # setup tty
    ioctl term_fd, $TCGETS, $cur_termios
    andl $TTY_MODE, cur_termios + termios_lflag
    movb $0, cur_termios + termios_cc_VTIME
    movb $0, cur_termios + termios_cc_VMIN
    ioctl term_fd, $TCSETS, $cur_termios

    call hide_cursor
    call clear_screen
    movl $1, %ax
    movl $1, %bx
    call set_cursor_pos
    call game_loop

    exit $0

#-----------------------
# func game_loop
.type game_loop, @function
game_loop:
    mov $100, %eax
    call msleep

    call getch
    cmpb $0, %al
    je game_loop
    call red
    write term_fd, $msg, $len

    jmp game_loop
    ret

