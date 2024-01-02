
mult_test.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    li x5, 2
    li x3, 3
    li x8, -50
    li x2, 3
    mul x6, x5, x3
    mulh x3, x6, x6
    mulhsu x5, x6, x6
    mulhu x6, x8, x2

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