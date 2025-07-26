.section .text
.globl _start

_start:
    li t0,  10        # a = 10
    li t1,  3         # b = 3

    # ADD
    add t2, t0, t1    # t2 = t0 + t1

    # SUB
    sub t3, t0, t1    # t3 = t0 - t1

    # AND
    and t4, t0, t1    # t4 = t0 & t1

    # OR
    or  t5, t0, t1    # t5 = t0 | t1

    # XOR
    xor t6, t0, t1    # t6 = t0 ^ t1

    # SLL
    sll a0, t0, t1    # a0 = t0 << t1

    # SRL
    srl a1, t0, t1    # a1 = t0 >> t1 (logical)

    # SRA
    li  t0, -16       # a = -16
    li  t1, 2         # b = 2
    sra a2, t0, t1    # a2 = a >> 2 (arith)

    # SLT (signed less than)
    li t0, 5
    li t1, 9
    slt a3, t0, t1    # a3 = (5 < 9) => 1

    # SLTU (unsigned less than)
    li t0, -1         # 0xFFFFFFFF = large unsigned
    li t1, 1
    sltu a4, t0, t1   # a4 = (0xFFFFFFFF < 1) => 0 (false)
    j _exit

_exit:
    nop
