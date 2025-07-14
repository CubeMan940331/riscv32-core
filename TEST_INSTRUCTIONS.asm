_start:
    ################################################################
    # 0. Set SP and initialize base values
    ################################################################
    li   x2, 0x1000        # SP = 0x1000, for memory tests
    li   x3, 0xAABBCCDD    # sample word
    li   x4, 0x1122        # sample half
    li   x5, 0xFF          # sample byte
    li   x6, -4            # signed test

    ################################################################
    # 1. Store values
    ################################################################
    sw   x3, 0(x2)         # store word
    sh   x4, 4(x2)         # store half
    sb   x5, 6(x2)         # store byte

    ################################################################
    # 2. Load + signed/unsigned check
    ################################################################
    lw   x7,  0(x2)        # x7 = 0xAABBCCDD
    lh   x8,  4(x2)        # x8 = 0x1122 (signed)
    lhu  x9,  4(x2)        # x9 = 0x1122 (unsigned)
    lb   x10, 6(x2)        # x10 = 0xFFFFFFFF
    lbu  x11, 6(x2)        # x11 = 0x000000FF

    ################################################################
    # 3. R-type test
    ################################################################
    add  x12, x7, x1       # x12 = x7 + 1
    sub  x13, x12, x1      # x13 = x12 - 1 = x7
    sll  x14, x1, x1       # x14 = 1 << 1 = 2
    slt  x15, x6, x1       # x15 = 1
    sltu x16, x1, x6       # x16 = 1 (1 < -4 unsigned)
    xor  x17, x14, x15     # x17 = 2 ^ 1 = 3
    srl  x18, x17, x1      # x18 = 3 >> 1 = 1
    sra  x19, x6, x1       # x19 = -4 >> 1 = -2
    or   x20, x18, x19     # x20 = OR of signed values
    and  x21, x17, x1      # x21 = 1

    ################################################################
    # 4. I-type ALU test
    ################################################################
    addi x22, x1, 8        # 9
    andi x23, x22, 7       # 1
    ori  x24, x23, 0x10    # 0x11
    xori x25, x24, 0xFF    # 0xEE
    slli x26, x1, 4        # 0x10
    srli x27, x26, 1       # 0x08
    srai x28, x6, 1        # -4 >> 1 = -2
    slti x29, x6, -1       # 1
    sltu x30, x1, x6      # 1 (1 < -4 unsigned)

    ################################################################
    # 5. AUIPC / LUI / Jumps
    ################################################################
    lui    x8, 0x10000     # x8 = 0x10000000
    auipc  x9, 0x00010     # x9 = PC + 0x1000
    jal    x10, jump_here
    addi   x11, x0, 0xFF   # skipped
jump_here:
    #     jalr   x0, x10, 0      # PC = x10 (return to next)

    ################################################################
    # 6. Branch hazards
    ################################################################
    beq  x1, x1, skip1     # taken
    addi x1, x0, 0x99    # skipped
skip1:
    bne  x1, x0, skip2     # taken
    addi x2, x0, 0x88    # skipped
skip2:
    blt  x6, x1, skip3     # -4 < 1 → taken
    addi x3, x0, 0x77    # skipped
skip3:
    bge  x1, x6, skip4     # 1 ≥ -4 → taken
    addi x4, x0, 0x66    # skipped
skip4:
    bltu x1, x6, skip5     # 1 < -4 (unsigned) → taken
    addi x5, x0, 0x55    # skipped
skip5:
    bgeu x6, x1, skip6     # -4 > 1 unsigned → taken
    addi x6, x0, 0x44    # skipped
skip6:

    ################################################################
    # 7. Loop forever (no .data, no output)
    ################################################################
done:
    j done

