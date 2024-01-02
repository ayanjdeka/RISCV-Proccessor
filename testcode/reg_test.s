
reg_test.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    li x5, 10
    li x3, 12
    li x2, 24
    li x7, 40
    add x4, x5, x3
    addi x4, x3, 4
    mul x6, x4, x4
    sub x5, x3, x5
    sll x6, x5, x2
    slt x5, x5, x3
    sltu x3, x3, x5
    xor x3, x3, x4
    srl x3, x3, x7
    sra x5, x3, x2
    or x3, x3, x6
    and x3, x3, x6
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

.section ".tohost"
.globl tohost
tohost: .dword 0
.section ".fromhost"
.globl fromhost
fromhost: .dword 0