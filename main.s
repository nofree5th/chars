.include "sys_call-inl.s"
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

    .lcomm now_elem, ELEM_MAX_SIZE
    .lcomm buf_elem, ELEM_MAX_SIZE

    .lcomm map_item, CONTENT_WIDTH * CONTENT_HEIGHT

.text
#=======================
#-----------------------
# entrance
_start:
  # init
    # open tty
    open $term, $O_RDWR
    movl %eax, term_fd

    # setup env
    #   get original
    ioctl term_fd, $TCGETS, $old_termios

    # make copy
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

  # fini (recover env)
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
# func map_now_elem
.type map_now_elem, @function
map_now_elem:
    lea now_elem, %esi
    movw ELEM_OFFSET_ROW(%esi), %ax
    movw ELEM_OFFSET_COL(%esi), %bx
    movw ELEM_OFFSET_COUNT(%esi), %di
    movw ELEM_OFFSET_COUNT(%esi), %cx
    movzwl %cx, %ecx
    # skip to item
    addl $ELEM_OFFSET_ITEM, %esi
map_item_again:
    push %ax
    push %bx
    addw (%esi), %ax
    addw 2(%esi), %bx

    push %ecx
    push %esi
    call row_col_to_index
    pop %esi
    pop %ecx
    movb $'$', map_item(%eax)

    pop %bx
    pop %ax
    # skip row/col offset
    addl $4, %esi
    loop map_item_again
    ret

#-----------------------
# func next_elem_style
# -> now_elem
.type next_elem_style, @function
next_elem_style:
    call rand
    xor %dx, %dx
    mov $ELEM_STYLE_COUNT, %bx
    # dx:ax / bx = ax ... dx
    div %bx
    movzwl %dx, %ebx
    movl elem_style_list(, %ebx, 4), %esi
    movw $ELEM_START_ROW, now_elem + ELEM_OFFSET_ROW
    movw $ELEM_START_COL, now_elem + ELEM_OFFSET_COL
    lea now_elem + ELEM_OFFSET_COUNT, %edi
    movl (%esi), %ecx
    sall %ecx
    inc %ecx
    rep movsw
    ret

#-----------------------
# func clear_now_elem
.type clear_now_elem, @function
clear_now_elem:
    lea now_elem, %esi
    movb $CLEAR_CHAR, %cl
    call draw_elem
    ret

#-----------------------
# func render_now_elem
.type render_now_elem, @function
render_now_elem:
    lea now_elem, %esi
    movb last_char, %cl
    call draw_elem
    ret

#-----------------------
# func render_item_map
.type render_item_map, @function
render_item_map:
    lea now_elem, %esi

    mov $BORDER_START_ROW, %ax
    mov $AREA_HEIGHT - 2, %ecx
    mov $-1, %esi
render_row_again:
    push %ecx
    inc %ax

    mov $BORDER_START_COL, %bx
    mov $AREA_WIDTH - 2, %ecx
render_col_again:
    inc %bx
    inc %esi
    cmpb $0, map_item(%esi)
    je empty_item
    push %ax
    push %bx
    push %esi
    push %ecx
    movb map_item(%esi), %cl
    call putchar
    pop %ecx
    pop %esi
    pop %bx
    pop %ax
empty_item:
    loop render_col_again
    pop %ecx
    loop render_row_again
    ret

#-----------------------
# func row_col_to_index
# row(ax), col(bx)
# -> ax(index)
.type row_col_to_index, @function
row_col_to_index:
    # calc map index = (row - start_row) * width + (col - start_col)
    sub $BORDER_START_ROW + 1, %ax
    sub $BORDER_START_COL + 1, %bx
    # * width
    mov $CONTENT_WIDTH, %dx
    mul %dx
    add %bx, %ax
    movzwl %ax, %eax
    ret

#-----------------------
# func check_elem_pos
# elem pointer(%edi)
# -> al(0: leage, 1: out of range, 2: dead)
.equiv POS_OK, 0
.equiv POS_OUT_OF_RANGE, 1
.equiv POS_DEAD, 2
.type check_elem_pos, @function
check_elem_pos:
    movw ELEM_OFFSET_ROW(%edi), %ax
    movw ELEM_OFFSET_COL(%edi), %bx
    movw ELEM_OFFSET_COUNT(%edi), %cx
    movzwl %cx, %ecx
    # skip to item
    addl $ELEM_OFFSET_ITEM, %edi
check_elem_pos_again:
    push %ax
    push %bx
    addw (%edi), %ax
    addw 2(%edi), %bx
  # check is pos out of range
    # row
    cmpw $BORDER_START_ROW, %ax
    jng out_of_range
    cmpw $(BORDER_START_ROW + AREA_HEIGHT - 1), %ax
    jge pos_not_leage

    # col
    cmpw $BORDER_START_COL, %bx
    jng out_of_range
    cmpw $(BORDER_START_COL + AREA_WIDTH - 1), %bx
    jge out_of_range

  # check is pos mapped item
    push %ecx
    push %edi
    call row_col_to_index
    pop %edi
    pop %ecx
    cmpb $0, map_item(%eax)
    jne pos_not_leage

    pop %bx
    pop %ax

    # skip row/col offset
    addl $4, %edi
    loop check_elem_pos_again
    mov $POS_OK, %al
    ret
out_of_range:
    add $4, %esp # discard %bx/ax
    mov $POS_OUT_OF_RANGE, %al
    ret
pos_not_leage:
    add $4, %esp # discard %bx/ax
    mov $POS_DEAD, %al
    ret

#-----------------------
# func process_cmd
# cmd_char(%al)
.type process_cmd, @function
process_cmd:
    push %ax
    call clear_now_elem
    pop %ax

    # make copy
    leal now_elem, %esi
    leal buf_elem, %edi
    movl $ELEM_MAX_SIZE, %ecx
    cld
    rep movsb

    leal buf_elem, %edi

    cmpb $CHAR_LEFT, %al
    je turn_left
    cmpb $CHAR_RIGHT, %al
    je turn_right
    cmpb $CHAR_DOWN, %al
    je go_down
    # TODO MORE
    ret
go_down:
    incw ELEM_OFFSET_ROW(%edi)
    jmp try_execute
turn_left:
    decw ELEM_OFFSET_COL(%edi)
    jmp try_execute
turn_right:
    incw ELEM_OFFSET_COL(%edi)
    #jmp try_execute

try_execute:
    call check_elem_pos
    cmpb $POS_OK, %al
    je do_execute
    cmpb $POS_DEAD, %al
    je generate_next
    # else POS_OUT_OF_RANGE
    ret
do_execute:
    # copy to now
    lea buf_elem, %esi
    lea now_elem, %edi
    movl $ELEM_MAX_SIZE, %ecx
    cld
    rep movsb
    ret
generate_next:
    call map_now_elem
    call next_elem_style
    ret

#-----------------------
# func game_loop
.type game_loop, @function
game_loop:
    call next_elem_style
    call clear_screen
game_loop_again:

  # render
    call render_border
    call render_now_elem
    call render_item_map

    mov $(1000 / FPS), %eax
    call msleep
    incw now_speed_counter

  # process input
    call getchar
    cmpb $0, %al
    je 1f
    call process_cmd
1:
    cmpb $'q', %al
    je quit

  # process timer(game auto down)
    movw now_speed, %cx
    cmpw %cx, now_speed_counter
    jnge game_loop_again
    movw $0, now_speed_counter
    movb $CHAR_DOWN, %al
    call process_cmd
    jmp game_loop_again

quit:
    ret

