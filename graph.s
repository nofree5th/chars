.include "macro-inl.s"
.include "consts-inl.s"

.extern putchar
.global draw_col_line
.global draw_row_line
.global draw_rect
.global draw_elem

.text
#=======================
#-----------------------
# func draw_col_line
# char_to_draw: %dl
# start : row/y1(%ax), col/x1=%bx
# count : %ecx (y1 + i, x1)
.type draw_col_line, @function
draw_col_line:
1:
    pushl %ecx
    pushw %ax
    pushw %bx
    pushw %dx
    movb %dl, %cl
    call putchar
    popw %dx
    popw %bx
    popw %ax
    popl %ecx

    incw %ax
    loop 1b
    ret

#-----------------------
# func draw_row_line
# char_to_draw: %dl
# start: row/y1(%ax), col/x1=%bx
# count: %cx (y1, x1 + i)
.type draw_row_line, @function
draw_row_line:
1:
    pushl %ecx
    pushw %ax
    pushw %bx
    pushw %dx
    movb %dl, %cl
    call putchar
    popw %dx
    popw %bx
    popw %ax
    popl %ecx

    incw %bx
    loop 1b
    ret

#-----------------------
# func draw_rect
# start   : row(%ax),  col(%bx)
# width   : %cl
# height  : %ch
# row char: %dl
# col char: %dh
.type draw_rect, @function
draw_rect:
    # top
    pushw %ax
    pushw %bx
    pushw %cx
    pushw %dx
    movzbl %cl, %ecx
    call draw_row_line
    popw %dx
    popw %cx
    popw %bx
    popw %ax

    # bottom
    pushw %ax
    pushw %bx
    pushw %cx
    pushw %dx
    movzbw %ch, %si
    addw %si, %ax
    dec %ax
    movzbl %cl, %ecx
    call draw_row_line
    popw %dx
    popw %cx
    popw %bx
    popw %ax

    # left
    pushw %ax
    pushw %bx
    pushw %cx
    pushw %dx
    movzbl %ch, %ecx
    movb %dh, %dl
    call draw_col_line
    popw %dx
    popw %cx
    popw %bx
    popw %ax

    # right
    pushw %ax
    pushw %bx
    pushw %cx
    pushw %dx
    movzbw %cl, %si
    addw %si, %bx
    dec %bx
    movzbl %ch, %ecx
    movb %dh, %dl
    call draw_col_line
    popw %dx
    popw %cx
    popw %bx
    popw %ax

    ret

#-----------------------
# func draw_elem
# elem char: cl
# elem pointer: esi
.type draw_elem, @function
draw_elem:
    movw ELEM_OFFSET_ROW(%esi), %ax
    movw ELEM_OFFSET_COL(%esi), %bx
    movw ELEM_OFFSET_COUNT(%esi), %di
    # skip to item
    addl $ELEM_OFFSET_ITEM, %esi
draw_elem_again:
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
    jnle draw_elem_again
    ret

