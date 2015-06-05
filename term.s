.include "macro-inl.s"

.extern term_fd

.global getch
.global clear_screen

.global hide_cursor
.global show_cursor
.global set_cursor_pos

.global red

.data
#=======================
    code_clear_screen: .ascii "\033[2J"
    .equiv code_clear_screen_len, . - code_clear_screen

    code_hide_cursor: .ascii "\033[?25l"
    .equiv code_hide_cursor_len, . - code_hide_cursor

    code_show_cursor: .ascii "\033[?25h"
    .equiv code_show_cursor_len, . - code_show_cursor

    code_color_red: .ascii "\033[31m"
    .equiv code_color_len, . - code_color_red

.text
#=======================
#-----------------------
# func getch()
#  -> %al(0: get nothing, others: get a char)
.type getch, @function
.bss
    .lcomm getch_buf, 1
.text
getch:
    read term_fd, $getch_buf, $1
    cmpl $0, %eax
    jle 1f
    # succ
    mov getch_buf, %al
    jmp 2f
1: # fail
    mov $0, %al
2: # end
    ret

#-----------------------
# func clear_screen
.type clear_screen, @function
clear_screen:
    pushl %ebx
    write term_fd, $code_clear_screen, $code_clear_screen_len
    popl %ebx
    ret

#-----------------------
# func hide_cursor
.type hide_cursor, @function
hide_cursor:
    pushl %ebx
    write term_fd, $code_hide_cursor, $code_hide_cursor_len
    popl %ebx
    ret

#-----------------------
# func show_cursor
.type show_cursor, @function
show_cursor:
    pushl %ebx
    write term_fd, $code_show_cursor, $code_show_cursor_len
    popl %ebx
    ret

#-----------------------
# func red
.type red, @function
red:
    pushl %ebx
    write term_fd, $code_color_red, $code_color_len
    popl %ebx
    ret

#-----------------------
# func set_cursor_pos
# row/y(%ax), col/x=%bx
.type set_cursor_pos, @function
.bss
    .lcomm set_cursor_pos_buf, 20
.text
set_cursor_pos:
    pushl %edi
    # \033
    movb $0x1B, set_cursor_pos_buf
    # [
    movb $'[', set_cursor_pos_buf + 1 # [
    # y
    movl $set_cursor_pos_buf + 2, %edi
    pushw %bx
    call itoa
    popw %bx
    addl %ecx, %edi
    # ;
    movb $';', (%edi)
    incl %edi
    # x
    movw %bx, %ax
    call itoa
    addl %ecx, %edi
    # H
    movb $'H', (%edi)
    incl %edi
    subl $set_cursor_pos_buf, %edi
    write term_fd, $set_cursor_pos_buf, %edi
    popl %edi
    ret
