jal_test.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    li x7, 2
    li x6, 0
    jal x8, done
test_jal_neg:
    addi x6, x6, 1
test_jal_pos:
    jal x9, branch
    beq x6, x7, branch
    jal x9, test_jal_neg
branch:
    blt x6, x7, done
    srl x3, x3, x7
    sra x5, x3, x2
    or x3, x3, x6
    and x3, x3, x6
    addi x7, x7, 1
    la x11, branch
    la x14, test
    sw x11, 0(x14)
    jalr x10, x11, 0
    jalr x10, x11, 0
    sw x11, 0(x14)
    jalr x11, x11, 0
    
done:
    li  t0, 1
    la  t1, tohost
    sw  t0, 0(t1)
    sw  x0, 4(t1)
halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt  # from trying to execute the data below.
                      # Your own programs should also make use
                      # of an infinite loop at the end.

deadend:
    lw x8, bad     # X8 <= 0xdeadbeef
deadloop:
    beq x8, x8, deadloop

.section .rodata

bad:        .word 0xdeadbeef
threshold:  .word 0x00000040
result:     .word 0x00000000
good:       .word 0x600d600d
test:       .word 0x12345678

.section ".tohost"
.globl tohost
tohost: .dword 0
.section ".fromhost"
.globl fromhost
fromhost: .dword 0
