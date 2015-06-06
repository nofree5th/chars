.include "macro-inl.s"

.global term_fd
.global _start

.data
#=======================
    term_fd: .int 1
    term   : .asciz "/dev/tty"

    .equiv area_width, 32
    .equiv area_height, 16
    .equiv border_row_char, '.'
    .equiv border_col_char, ':'
    .equiv border_start_row, 4
    .equiv border_start_col, 25

    .equiv echo_char_row, border_start_row
    .equiv echo_char_col, border_start_col + area_width / 2

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

    call render_border

    # run
    call game_loop

    # recover env
    call show_cursor
    ioctl term_fd, $TCSETS, $old_termios
    exit $0

#-----------------------
# func render_border
.type render_border, @function
render_border:
    call red
    movw $border_start_row, %ax
    movw $border_start_col, %bx
    movb $area_width, %cl
    movb $area_height, %ch
    movb $border_row_char, %dl
    movb $border_col_char, %dh
    call draw_rect
    ret

#-----------------------
# func game_loop
.type game_loop, @function
game_loop:
game_loop_idle:
    movb $'?', %al
game_loop_again:
    # echo to screen
    movb %al, %cl
    movl $echo_char_row, %ax
    movl $echo_char_col, %bx
    call putchar

    mov $100, %eax
    call msleep

    call getchar

    cmpb $'q', %al
    je quit

    cmpb $0, %al
    je game_loop_idle


    jmp game_loop_again
quit:
    ret

