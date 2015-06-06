.include "macro-inl.s"

.global msleep
.global itoa
.global next_rect_pos

.text
#=======================
#-----------------------
# func msleep(%eax ms)
# ms(%eax): ms to sleep
.bss
    .lcomm timespec, 8
    .lcomm rem, 8
.text
.type msleep, @function
msleep:
    movl $1000000, %ecx
    mull %ecx
    movl %eax, timespec + 4
    nanosleep $timespec, $rem
    ret

#-----------------------
# func itoa
# number(%ax, int), buf(%edi, char*) -> count(%ecx)
.data
    decimal_map: .ascii "0123456789"
.text
.type itoa, @function
itoa:
    xorl %ecx, %ecx
    movb $10, %bl
itoa_mod_again:
    div %bl
    movzbl %ah, %edx
    movb decimal_map(, %edx, 1),%bh
    movb %bh, (%edi, %ecx, 1)
    incl %ecx
    xorb %ah, %ah
    cmpb $0, %al
    jnz itoa_mod_again

    # reverse [edi, esi]
    movl %edi, %esi
    addl %ecx, %esi
    decl %esi
itoa_reverse_again:
    cmpl %edi, %esi
    jbe itoa_exit
    movb (%esi), %al
    xchgb %al, (%edi)
    movb %al, (%esi)
    decl %esi
    incl %edi
    jmp itoa_reverse_again
itoa_exit:
    ret

#-----------------------
# func next_rect_pos
# start   : row(%si), col(%di)
# width   : %cl
# height  : %ch
# current : row(%ax), col(%bx)
# -> next : row(%ax), col(%bx)
.type next_rect_pos, @function
next_rect_pos:
    cmpw %si, %ax
    je next_rect_pos_at_top
    cmp %di, %bx
    je next_rect_pos_at_left

    # %dx as bottom row
    mov %si, %dx
    pushw %cx
    movzbw %ch, %cx
    add %cx, %dx
    dec %dx
    popw %cx

    cmp %dx, %si
    je next_rect_pos_at_bottom

next_rect_pos_at_right:
    inc %ax
    cmp %dx, %ax
    jbe next_rect_pos_end
    # out of range
    mov %dx, %ax
    dec %bx
    jmp next_rect_pos_end

next_rect_pos_at_top:
    incw %bx
    movzbw %cl, %cx
    addw %cx, %di
    cmpw %di, %bx
    jb next_rect_pos_end
    # out of range
    incw %ax
    movw %di, %bx
    decw %bx
    jmp next_rect_pos_end

next_rect_pos_at_left:
    decw %ax
    cmpw %si, %ax
    jae next_rect_pos_end
    # out of range
    movw %si, %ax
    movw %di, %bx
    incw %bx
    jmp next_rect_pos_end

next_rect_pos_at_bottom:
    decw %bx
    cmpw %di, %bx
    jae next_rect_pos_end
    # out of range
    decw %ax
    movw %di, %bx

next_rect_pos_end:
    ret
