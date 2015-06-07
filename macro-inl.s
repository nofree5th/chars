.equiv SYS_CALL, 0x80

# see /usr/include/asm/unistd_32.h
.equiv __NR_exit,       1
.equiv __NR_read,       3
.equiv __NR_write,      4
.equiv __NR_open,       5
.equiv __NR_close,      6
.equiv __NR_nanosleep,  162
.equiv __NR_ioctl,      54
.equiv __NR_time,       13

.equiv O_RDWR, 2
.equiv TCGETS, 0x5401
.equiv TCSETS, 0x5402
.equiv ICANON, 0x2
.equiv ECHO  , 0x8
.equiv ECHOE , 0x10
.equiv TTY_MODE, 0xFFFFFFE5 # ~(ICANON | ECHO | ECHOE)


.macro __check_error
    cmpl $0, %eax
    jns 1f
    exit $1
1:
.endm

.macro __call1 nr, arg1
    movl \arg1, %ebx
    movl \nr, %eax
    int $SYS_CALL
.endm

.macro __call2 nr, arg1, arg2
    movl \arg2, %ecx
    movl \arg1, %ebx
    movl \nr, %eax
    int $SYS_CALL
    __check_error
.endm

.macro __call3_no_check nr, arg1, arg2, arg3
    movl \arg3, %edx
    movl \arg2, %ecx
    movl \arg1, %ebx
    movl \nr, %eax
    int $SYS_CALL
.endm

.macro __call3 nr, arg1, arg2, arg3
    __call3_no_check \nr, \arg1, \arg2, \arg3
    __check_error
.endm

.macro exit code
    movl \code, %ebx
    movl $__NR_exit, %eax
    int $SYS_CALL
.endm

.macro open pathname, flags
    __call2 $__NR_open, \pathname, \flags
.endm

.macro write fd, buf, count
    __call3 $__NR_write, \fd, \buf, \count
.endm

.macro read fd, buf, count
    __call3_no_check $__NR_read, \fd, \buf, \count
.endm

.macro nanosleep req, rem
    __call2 $__NR_nanosleep, \req, \rem
.endm

.macro ioctl fd, type, request
    __call3 $__NR_ioctl, \fd, \type, \request
.endm

.macro time
    __call1 $__NR_time, $0
.endm

.macro ADD_POS offset_row, offset_col
.endm

