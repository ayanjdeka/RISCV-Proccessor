branch_test.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    li x2, 15
    li x3, 15
blt_test:
    addi x2, x2, -1
    blt x2, x3, bne_test
bne_test:
    andi x3, x3, 1
    li x4, 20
    li x5, 21
    bne x4, x5, bge_test
bge_test:
    addi x4, x4, 2
    bge x4, x5, bgeu_test
bgeu_test:
    addi x4, x4, 0
    bgeu x4, x5, bltu_test
bltu_test:
    addi x4, x4, -4
    bltu x4, x5, beq_test
beq_test:
    addi x4, x4, 1
    beq x4, x5, done
done:
    andi x2, x2, 0
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
