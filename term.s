.include "macro-inl.s"

.extern term_fd

.global last_char # variable

.global getchar
.global putchar
.global clear_screen

.global hide_cursor
.global show_cursor
.global set_cursor_pos

.global set_color_red
.global set_color_green

.data
#=======================
    code_clear_screen: .ascii "\033[2J"
    .equiv code_clear_screen_len, . - code_clear_screen

    code_hide_cursor: .ascii "\033[?25l"
    .equiv code_hide_cursor_len, . - code_hide_cursor

    code_show_cursor: .ascii "\033[?25h"
    .equiv code_show_cursor_len, . - code_show_cursor

    .equiv code_color_len, 5
    code_color_red: .ascii "\033[31m"
    code_color_green: .ascii "\033[32m"

    last_char: .byte '?'

.text
#=======================
#-----------------------
# func getchar()
#  -> %al(0: get nothing, others: get a char)
.type getchar, @function
getchar:
    read term_fd, $last_char, $1
    cmpl $0, %eax
    jle getchar_fail
    # succ
    mov last_char, %al
    jmp getchar_end
getchar_fail:
    mov $0, %al
getchar_end:
    ret

#-----------------------
# func putchar
# row/y(%ax), col/x(%bx)
# char to put(%cl)
.type putchar, @function
.bss
    .lcomm putchar_buf, 1
.text
putchar:
    pushw %cx
    call set_cursor_pos
    popw %cx

    movb %cl, putchar_buf
    write term_fd, $putchar_buf, $1
    ret

#-----------------------
# func clear_screen
.type clear_screen, @function
clear_screen:
    write term_fd, $code_clear_screen, $code_clear_screen_len
    ret

#-----------------------
# func hide_cursor
.type hide_cursor, @function
hide_cursor:
    write term_fd, $code_hide_cursor, $code_hide_cursor_len
    ret

#-----------------------
# func show_cursor
.type show_cursor, @function
show_cursor:
    write term_fd, $code_show_cursor, $code_show_cursor_len
    ret

#-----------------------
# func set_color_red
.type set_color_red, @function
set_color_red:
    write term_fd, $code_color_red, $code_color_len
    ret

#-----------------------
# func set_color_green
.type set_color_green, @function
set_color_green:
    write term_fd, $code_color_green, $code_color_len
    ret

#-----------------------
# func set_cursor_pos
# row/y(%ax), col/x=%bx
.type set_cursor_pos, @function
.bss
    .lcomm set_cursor_pos_buf, 20
.text
set_cursor_pos:
    # \033
    movb $0x1B, set_cursor_pos_buf
    # [
    movb $'[', set_cursor_pos_buf + 1 # [
    # y
    movl $(set_cursor_pos_buf + 2), %edi
    pushw %bx
    pushl %edi
    call itoa
    popl %edi
    popw %bx
    addl %ecx, %edi
    # ;
    movb $';', (%edi)
    incl %edi
    # x
    movw %bx, %ax
    pushl %edi
    call itoa
    popl %edi
    addl %ecx, %edi
    # H
    movb $'H', (%edi)
    incl %edi

    # edi as len
    subl $set_cursor_pos_buf, %edi
    write term_fd, $set_cursor_pos_buf, %edi
    ret
