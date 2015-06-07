.include "macro-inl.s"
.include "consts-inl.s"

.global term_fd
.global _start

.data
#=======================
    term_fd: .int 1
    term   : .asciz "/dev/tty"

    .p2align 1,,
    echo_char_row: .word BORDER_START_ROW
    echo_char_col: .word BORDER_START_COL + AREA_WIDTH / 2

    now_elem_row: .word ELEM_START_ROW
    now_elem_col: .word ELEM_START_COL
    now_elem_style: .long elem_style1

    now_speed: .word FPS
    now_speed_counter: .word 0

    elem_style1:
        .word 1
        .word 0, 0
    elem_style2:
        .word 2
        .word 0, 0   #
        .word 0, 1   # Oo
    elem_style3_1:
        .word 3
        .word 0, -1  #
        .word 0, 0   #
        .word 0, 1   # oOo
    elem_style3_2:
        .word 3
        .word 0, 0   #
        .word -1, 1  # o
        .word 0, 1   # Oo
    elem_style4_1:
        .word 4
        .word 0, 0   #
        .word 0, -1  #
        .word 0, 1   #
        .word 0, 2   # oOoo
    elem_style4_2:
        .word 4
        .word 0, 0   #
        .word 0, -1  #
        .word 0, 1   #  o
        .word -1, 0  # oOo
    elem_style4_3:
        .word 4
        .word 0, 0   #
        .word 0, -1  #
        .word -1, -1 # oo
        .word -1, 0  # oO
    elem_style4_4:
        .word 4
        .word 0, 0   #
        .word 0, 1   #
        .word 0, 2   # o
        .word -1, 0  # Ooo
    elem_style_list: .long elem_style1
                     .long elem_style2
                     .long elem_style3_1, elem_style3_2
                     .long elem_style4_1, elem_style4_2, elem_style4_3, elem_style4_4
    # NOTE: ELEM_STYLE_COUNT should not be confict with rand
    .equiv ELEM_STYLE_COUNT, (. - elem_style_list) / 4

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

    movb last_char, %cl
    call putchar
    ret

#-----------------------
# func next_elem_style
# next_elem_style_pointer: edx & now_elem_style
.type next_elem_style, @function
next_elem_style:
    call rand
    xor %dx, %dx
    mov $ELEM_STYLE_COUNT, %bx
    # dx:ax / bx = ax ... dx
    div %bx
    movzwl %dx, %ebx
    movl elem_style_list(, %ebx, 4), %edx
    movl %edx, now_elem_style
    ret
#-----------------------
# func clear_now_elem
.type clear_now_elem, @function
clear_now_elem:
    movl now_elem_style, %edx
    movw now_elem_row, %ax
    movw now_elem_col, %bx
    movb $CLEAR_CHAR, %cl
    call draw_elem
    ret

#-----------------------
# func render_now_elem
.type render_now_elem, @function
render_now_elem:
    movl now_elem_style, %edx
    movw now_elem_row, %ax
    movw now_elem_col, %bx
    movb last_char, %cl
    call draw_elem
    ret

#-----------------------
# func game_loop
.type game_loop, @function
game_loop:
    call next_elem_style
    call clear_screen
game_loop_again:

    call render_border
    call render_now_elem

    mov $(1000 / FPS), %eax
    call msleep
    incw now_speed_counter

    # check input
    call getchar
#cmpb $0, %al
#je game_loop_again
    cmpb $'q', %al
    je quit

    # check game timer
    movw now_speed, %cx
    cmpw %cx, now_speed_counter
    jnge game_loop_again

    # process_game_frame
    movw $0, now_speed_counter

    call clear_now_elem
    incw now_elem_row
    movw $(BORDER_START_ROW + AREA_HEIGHT - 1), %ax
    cmpw %ax, now_elem_row
    jnge game_loop_again

    # generate next
    movw $ELEM_START_ROW, now_elem_row
    call next_elem_style
    jmp game_loop_again

quit:
    ret

