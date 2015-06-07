.include "macro-inl.s"
.include "consts-inl.s"

.global term_fd
.global _start

.data
#=======================
    term_fd: .int 1
    term   : .asciz "/dev/tty"
    echo_char: .byte '?'

    .p2align 1,,
    echo_char_row: .word BORDER_START_ROW
    echo_char_col: .word BORDER_START_COL + AREA_WIDTH / 2

    now_elem_row: .word ELEM_START_ROW
    now_elem_col: .word ELEM_START_COL
    selected_elem_style: .long elem_style1

    elem_style1:
        .word 1
        .word 0, 0
    elem_style2:
        .word 2
        .word 0, 0   # O
        .word -1, 0  # O
    elem_style2_1:
        .word 2
        .word 0, 0   #
        .word 0, 1   # OO
    elem_style3_1:
        .word 3
        .word -1, 0  # O
        .word 0, 0   # O
        .word 1, 0   # O
    elem_style3_2:
        .word 3
        .word 0, 0   #
        .word 0, 1   # OO
        .word 1, 0   # O
    .equiv ELEM_STYLE_COUNT, 5
    elem_style_list: .long elem_style1, elem_style2, elem_style2_1, elem_style3_1, elem_style3_2

.bss
#=======================
    .equiv termios_lflag, 12
    .equiv termios_cc_VMIN, 17 + 6
    .equiv termios_cc_VTIME, 17 + 5
    .p2align 2,,
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

    # init rand
    time
    call srand

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

    # render echo char
    call set_color_green
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
    ret
#-----------------------
# func render_elem
# elem row : ax
# elem col : bx
# elem char: cl
# elem style pointer: edx
.type render_elem, @function
render_elem:
    # %di as count
    movw (%edx), %di
    # %esi as pos pointer
    mov %edx, %esi
    # skip count
    addl $2, %esi
render_elem_again:
    push %ax
    push %bx
    push %cx
    push %esi
    push %di
    addw (%esi), %ax
    addw 2(%esi), %bx
    call putchar
    pop %di
    pop %esi
    pop %cx
    pop %bx
    pop %ax

    # skip row/col offset
    addl $4, %esi
    dec %di
    jnle render_elem_again
    ret

#-----------------------
# func next_elem_style
# next_elem_style_pointer: edx
.type next_elem_style, @function
next_elem_style:
    call rand
    xor %dx, %dx
    mov $ELEM_STYLE_COUNT, %bx
    # dx:ax / bx = ax ... dx
    div %bx
    movzwl %dx, %ebx
    movl elem_style_list(, %ebx, 4), %edx
    ret

#-----------------------
# func game_loop
.type game_loop, @function
game_loop:
    call clear_screen
game_loop_again:

    # clear last
    movl selected_elem_style, %edx
    movw now_elem_row, %ax
    movw now_elem_col, %bx
    movb $CLEAR_CHAR, %cl
    call render_elem

    call next_elem_style
    movl %edx, selected_elem_style

    movl selected_elem_style, %edx
    movw now_elem_row, %ax
    movw now_elem_col, %bx
    movb echo_char, %cl
    call render_elem

    call render_border

    mov $(1000 / FPS), %eax
    call msleep

    # check input
    call getchar

    cmpb $'q', %al
    je quit

    cmpb $0, %al
    je game_loop_again

    movb %al, echo_char
    jmp game_loop_again
quit:
    ret

