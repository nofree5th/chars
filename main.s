.include "macro-inl.s"
.include "consts-inl.s"

.global term_fd
.global _start

.data
#=======================
    term_fd: .int 1
    term   : .asciz "/dev/tty"
    echo_char: .byte '?'
    echo_char_row: .word BORDER_START_ROW
    echo_char_col: .word BORDER_START_COL + AREA_WIDTH / 2

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

    # run
    call game_loop

    # recover env
    call clear_screen
    call show_cursor
    ioctl term_fd, $TCSETS, $old_termios
    exit $0

#-----------------------
# func render_border
.type render_border, @function
render_border:
    call set_color_red
    movw $BORDER_START_ROW, %ax
    movw $BORDER_START_COL, %bx
    movb $AREA_WIDTH, %cl
    movb $AREA_HEIGHT, %ch
    movb $BORDER_ROW_CHAR, %dl
    movb $BORDER_COL_CHAR, %dh
    call draw_rect

    movw $BORDER_START_ROW, %ax
    movw $BORDER_START_COL, %bx
    movb $BORDER_CORNER_CHAR, %cl
    call putchar

    movw $BORDER_START_ROW, %ax
    movw $(BORDER_START_COL + AREA_WIDTH - 1), %bx
    movb $BORDER_CORNER_CHAR, %cl
    call putchar
    ret

#-----------------------
# func game_loop
.type game_loop, @function
game_loop:
    call clear_screen
game_loop_again:
    call render_border

    call set_color_green
    # move echo char
    movw $BORDER_START_ROW, %si
    movw $BORDER_START_COL, %di
    movb $AREA_WIDTH, %cl
    movb $AREA_HEIGHT, %ch
    movw echo_char_row, %ax
    movw echo_char_col, %bx
    call next_rect_pos
    movw %ax, echo_char_row
    movw %bx, echo_char_col

    movb echo_char, %cl
    call putchar

    mov $50, %eax
    call msleep

    call getchar

    cmpb $'q', %al
    je quit

    cmpb $0, %al
    je game_loop_again

    movb %al, echo_char
    jmp game_loop_again
quit:
    ret

