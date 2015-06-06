.include "macro-inl.s"

.extern putchar
.global draw_col_line
.global draw_row_line
.global draw_rect

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
    decl %ax
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
    decl %bx
    movzbl %ch, %ecx
    movb %dh, %dl
    call draw_col_line
    popw %dx
    popw %cx
    popw %bx
    popw %ax

    ret
