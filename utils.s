.include "macro-inl.s"

.global msleep
.global itoa

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
