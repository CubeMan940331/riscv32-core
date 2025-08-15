#include <iostream>
#include <vector>
#include <cstdint>
#include <cmath>
#include <iomanip>

// Verilator header
#include "verilated.h"
#include "verilated_vcd_c.h"

// FPU Top module header
#include "VFPU_Top.h"

// helper function
uint32_t i32_to_u32(int32_t i) {
    union { int32_t i; uint32_t u; } converter = {i};
    return converter.u;
}

int32_t u32_to_i32(uint32_t u) {
    union { uint32_t u; int32_t i; } converter = {u};
    return converter.i;
}

uint32_t f32_to_u32(float f) {
    union { float f; uint32_t u; } converter = {f};
    return converter.u;
}
uint64_t f64_to_u64(double d) {
    union { double d; uint64_t u; } converter = {d};
    return converter.u;
}
float u32_to_f32(uint32_t u) {
    union { uint32_t u; float f; } converter = {u};
    return converter.f;
}
double u64_to_f64(uint64_t u) {
    union { uint64_t u; double d; } converter = {u};
    return converter.d;
}

// --- Opcode Definitions (Must match FPU_Top.v) ---
// func7
const uint8_t OP_FADD_S  = 0b0000000, OP_FADD_D  = 0b0000001;
const uint8_t OP_FSUB_S  = 0b0000100, OP_FSUB_D  = 0b0000101;
const uint8_t OP_FMUL_S  = 0b0001000, OP_FMUL_D  = 0b0001001;
const uint8_t OP_FDIV_S  = 0b0001100, OP_FDIV_D  = 0b0001101;
const uint8_t OP_FSQRT_S = 0b0101100, OP_FSQRT_D = 0b0101101;
const uint8_t OP_FCMP_S  = 0b1010000, OP_FCMP_D  = 0b1010001;

const uint8_t OP_FCVT_D_S  = 0b0100001;
const uint8_t OP_FCVT_W_S  = 0b1100000;
const uint8_t OP_FCVT_D_W  = 0b1101001;

const uint8_t OP_FCVT_S_D  = 0b0100000;
const uint8_t OP_FCVT_W_D  = 0b1100001;
const uint8_t OP_FCVT_S_W  = 0b1101000;

// func3
const uint8_t CMP_EQ = 0b010;
const uint8_t CMP_LT = 0b001;
const uint8_t CMP_LE = 0b000;

const uint8_t RNE = 0b000;
const uint8_t RTZ = 0b001;
const uint8_t RDN = 0b010;
const uint8_t RUP = 0b011;
const uint8_t RMM = 0b100;
const uint8_t DYN = 0b111;

// rs2
const uint8_t CVT_NN = 0b00000;
const uint8_t CVT_W  = 0b00000;
const uint8_t CVT_WU = 0b00001;

// --- Test Case Result Type ---
enum ResultType {
    FP32, FP64, INT, UINT
};

// define testcase
struct TestCase {
    std::string name;
    uint8_t  func7;
    uint8_t  func3;
    uint8_t  rs2;
    ResultType result_type;

    uint64_t operand_a;
    uint64_t operand_b;
    uint64_t expected_result;

    uint8_t  expected_fflags;
};

// simulate clock
vluint64_t main_time = 0;
double sc_time_stamp() {
    return main_time;
}

// run one testcase
bool run_test(VFPU_Top* top, VerilatedVcdC* tfp, const TestCase& test) {
    // setting inputs
    top->func7 = test.func7;
    top->func3 = test.func3;
    top->rs2 = test.rs2;
    top->operand_a = test.operand_a;
    top->operand_b = test.operand_b;

    // simulate one clock
    top->clk = 0;
    top->eval();
    main_time++;
    if (tfp) tfp->dump(main_time);
    
    top->clk = 1;
    top->eval();
    main_time++;
    if (tfp) tfp->dump(main_time);

    // output check
    bool pass = true;
    switch (test.result_type) {
        case UINT:
            if (top->result_out != test.expected_result) {
                 pass = false;
                 std::cout << "    \033[31m[FAIL]\033[0m Result mismatch (UINT). Got: " << std::dec << (uint32_t)top->result_out << ", Expected: " << (uint32_t)test.expected_result << std::endl;
            }
            break;
        
        case INT:
            if (top->result_out != test.expected_result) {
                 pass = false;
                 std::cout << "    \033[31m[FAIL]\033[0m Result mismatch (INT). Got: " << std::dec << (int32_t)top->result_out << ", Expected: " << (int32_t)test.expected_result << std::endl;
            }
            break;

        case FP32:
            if ((top->result_out & 0xFFFFFFFF) != (test.expected_result & 0xFFFFFFFF)) {
                 pass = false;
                 std::cout << "    \033[31m[FAIL]\033[0m Result mismatch (FP32). Got: 0x" << std::hex << (top->result_out & 0xFFFFFFFF) << " (" << u32_to_f32(top->result_out & 0xFFFFFFFF) 
                           << "), Expected: 0x" << (test.expected_result & 0xFFFFFFFF) << " (" << u32_to_f32(test.expected_result & 0xFFFFFFFF) << ")" << std::dec << std::endl;
            }
            break;

        case FP64:
             if (top->result_out != test.expected_result) {
                 pass = false;
                 std::cout << "    \033[31m[FAIL]\033[0m Result mismatch (FP64). Got: 0x" << std::hex << top->result_out << " (" << u64_to_f64(top->result_out)
                           << "), Expected: 0x" << test.expected_result << " (" << u64_to_f64(test.expected_result) << ")" << std::dec << std::endl;
            }
            break;
    }

    // flag check
    if (top->fflags != test.expected_fflags) {
        pass = false;
        std::cout << "    \033[31m[FAIL]\033[0m fflags mismatch. Got: " << std::bitset<5>(top->fflags) << ", Expected: " << std::bitset<5>(test.expected_fflags) << std::endl;
    }
    
    return pass;
}

int main(int argc, char** argv, char** env) {
    // initialize Verilator
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    // initialize FPU
    VFPU_Top* top = new VFPU_Top;

    // initialize vcd
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("waveform.vcd");

    // Testcases
    std::vector<TestCase> test_suite = {
        //  { Name },                                        { func7 },   { func3 },  {IntType}, {ResultType}, {OpA},                           {OpB},              {ExpectedResult},       {Invalid, DivByZero, Overflow, Underflow, Inexact,  cmp_result}

        // // --- Adder Tests ---
        // // SP_Adder
        //     {"FADD.S: 1.5 + 2.75",                           OP_FADD_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(1.5f),                  f32_to_u32(2.75f),                f32_to_u32(4.25f),                0b00000},
        //     {"FADD.S: 123.55 + 0.375",                       OP_FADD_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(123.55f),               f32_to_u32(0.375f),               f32_to_u32(123.925f),             0b00000},
        //     {"FSUB.S: 10.0 - 5.5",                           OP_FSUB_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(10.0f),                 f32_to_u32(5.5f),                 f32_to_u32(4.5f),                 0b00000},
        //     {"FSUB.S: 1.0 - 0.5625",                         OP_FSUB_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(1.0f),                  f32_to_u32(0.5625f),              f32_to_u32(0.4375f),              0b00000},
        //     {"FADD.S: 1.0 + NAN -> Invalid NaN",             OP_FADD_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(1.0f),                  f32_to_u32(NAN),                  f32_to_u32(NAN),                  0b10000},//
        //     {"FSUB.S: 1.0 - NAN -> Invalid NaN",             OP_FSUB_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(1.0f),                  f32_to_u32(NAN),                  f32_to_u32(NAN),                  0b10000},
        //     {"FADD.S: NAN + 1.0 -> Invalid NaN",             OP_FADD_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(NAN),                   f32_to_u32(1.0f),                 f32_to_u32(NAN),                  0b10000},
        //     {"FSUB.S: NAN - 1.0 -> Invalid NaN",             OP_FSUB_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(NAN),                   f32_to_u32(1.0f),                 f32_to_u32(NAN),                  0b10000},
        //     {"FADD.S: NAN + NAN -> Invalid NaN",             OP_FADD_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(NAN),                   f32_to_u32(NAN),                  f32_to_u32(NAN),                  0b10000},
        //     {"FSUB.S: NAN - NAN -> Invalid NaN",             OP_FSUB_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(NAN),                   f32_to_u32(NAN),                  f32_to_u32(NAN),                  0b10000},
        //     {"FADD.S: Inf + 3.0 -> Inf",                     OP_FADD_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(INFINITY),              f32_to_u32(3.0f),                 f32_to_u32(INFINITY),             0b00000},
        //     {"FADD.S: 3.0 + Inf -> Inf",                     OP_FADD_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(3.0f),                  f32_to_u32(INFINITY),             f32_to_u32(INFINITY),             0b00000},
        //     {"FSUB.S: Inf - 3.0 -> Inf",                     OP_FSUB_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(INFINITY),              f32_to_u32(3.0f),                 f32_to_u32(INFINITY),             0b00000},
        //     {"FSUB.S: 3.0 - Inf -> Inf",                     OP_FSUB_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(3.0f),                  f32_to_u32(INFINITY),             f32_to_u32(-INFINITY),            0b00000},
        //     {"FSUB.S: Inf - Inf -> Invalid NaN",             OP_FSUB_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(INFINITY),              f32_to_u32(INFINITY),             f32_to_u32(NAN),                  0b10000},
        //     {"FADD.S: 2.75 + 0.0",                           OP_FADD_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(2.75f),                 f32_to_u32(0.0f),                 f32_to_u32(2.75f),                0b00000},
        //     {"FSUB.S: 0.0 - 5.5",                            OP_FSUB_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(0.0f),                  f32_to_u32(5.5f),                 f32_to_u32(-5.5f),                0b00000},
        //     {"FADD.S: Min_Normal + Min_Denormal",            OP_FADD_S,      RNE,       CVT_NN,    FP32,    0x00800000,                        0x00000001,                       0x00800001,                       0b00000},//
        //     {"FSUB.S: Min_Normal - Min_Denormal",            OP_FSUB_S,      RNE,       CVT_NN,    FP32,    0x00800000,                        0x00000001,                       0x007FFFFF,                       0b00010},
        //     {"FADD.S: MAX_FLOAT + MAX_FLOAT -> Overflow",    OP_FADD_S,      RNE,       CVT_NN,    FP32,    0x7F7FFFFF,                        0x7F7FFFFF,                       f32_to_u32(INFINITY),             0b00101},
        // // DP_Adder        
        //     {"FADD.D: 1.5 + 2.75",                           OP_FADD_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(1.5),                   f64_to_u64(2.75),                 f64_to_u64(4.25),                 0b00000},
        //     {"FADD.D: 123.55 + 0.375",                       OP_FADD_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(123.55),                f64_to_u64(0.375),                f64_to_u64(123.925),              0b00000},
        //     {"FSUB.D: 10.0 - 5.5",                           OP_FSUB_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(10.0),                  f64_to_u64(5.5),                  f64_to_u64(4.5),                  0b00000},
        //     {"FSUB.D: 1.0 - 0.5625",                         OP_FSUB_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(1.0),                   f64_to_u64(0.5625),               f64_to_u64(0.4375),               0b00000},
        //     {"FADD.D: 1.0 + NAN -> Invalid NaN",             OP_FADD_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(1.0),                   f64_to_u64(NAN),                  f64_to_u64(NAN),                  0b10000},//
        //     {"FSUB.D: 1.0 - NAN -> Invalid NaN",             OP_FSUB_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(1.0),                   f64_to_u64(NAN),                  f64_to_u64(NAN),                  0b10000},
        //     {"FADD.D: NAN + 1.0 -> Invalid NaN",             OP_FADD_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(NAN),                   f64_to_u64(1.0),                  f64_to_u64(NAN),                  0b10000},
        //     {"FSUB.D: NAN - 1.0 -> Invalid NaN",             OP_FSUB_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(NAN),                   f64_to_u64(1.0),                  f64_to_u64(NAN),                  0b10000},
        //     {"FADD.D: NAN + NAN -> Invalid NaN",             OP_FADD_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(NAN),                   f64_to_u64(NAN),                  f64_to_u64(NAN),                  0b10000},
        //     {"FSUB.D: NAN - NAN -> Invalid NaN",             OP_FSUB_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(NAN),                   f64_to_u64(NAN),                  f64_to_u64(NAN),                  0b10000},
        //     {"FADD.D: Inf + 3.0 -> Inf",                     OP_FADD_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(INFINITY),              f64_to_u64(3.0),                  f64_to_u64(INFINITY),             0b00000},
        //     {"FADD.D: 3.0 + Inf -> Inf",                     OP_FADD_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(3.0),                   f64_to_u64(INFINITY),             f64_to_u64(INFINITY),             0b00000},
        //     {"FSUB.D: Inf - 3.0 -> Inf",                     OP_FSUB_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(INFINITY),              f64_to_u64(3.0),                  f64_to_u64(INFINITY),             0b00000},
        //     {"FSUB.D: 3.0 - Inf -> Inf",                     OP_FSUB_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(3.0),                   f64_to_u64(INFINITY),             f64_to_u64(-INFINITY),            0b00000},
        //     {"FSUB.D: Inf - Inf -> Invalid NaN",             OP_FSUB_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(INFINITY),              f64_to_u64(INFINITY),             f64_to_u64(NAN),                  0b10000},
        //     {"FADD.D: 2.75 + 0.0",                           OP_FADD_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(2.75),                  f64_to_u64(0.0),                  f64_to_u64(2.75),                 0b00000},
        //     {"FSUB.D: 0.0 - 5.5",                            OP_FSUB_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(0.0),                   f64_to_u64(5.5),                  f64_to_u64(-5.5),                 0b00000},
        //     {"FADD.D: Min_Normal + Min_Denormal",            OP_FADD_D,      RNE,       CVT_NN,    FP64,    0x0010000000000000,                0x0000000000000001,               0x0010000000000001,               0b00000},//
        //     {"FSUB.D: Min_Normal - Min_Denormal",            OP_FSUB_D,      RNE,       CVT_NN,    FP64,    0x0010000000000000,                0x0000000000000001,               0x000FFFFFFFFFFFFF,               0b00010},
        //     {"FADD.D: MAX_FLOAT + MAX_FLOAT -> Overflow",    OP_FADD_D,      RNE,       CVT_NN,    FP64,    0x7FEFFFFFFFFFFFFF,                0x7FEFFFFFFFFFFFFF,               f64_to_u64(INFINITY),             0b00101},
        // // --- Compare Tests ---    
        // // SP_Compare    
            {"FCMP.S: -2.0 < -1.0",                          OP_FCMP_S,      CMP_LT,    CVT_NN,    INT,     0x7fffffff,                 0,                0,               0b10000},
            // {"FCMP.S: -2.0 < -1.0",                          OP_FCMP_S,      CMP_LT,    CVT_NN,    INT,     f32_to_u32(-2.0f),                 f32_to_u32(-1.0f),                0x0000000000000001,               0b00000},
        //     {"FCMP.S: 2.0 = 2.0",                            OP_FCMP_S,      CMP_EQ,    CVT_NN,    INT,     f32_to_u32(2.0f),                  f32_to_u32(2.0f),                 0x0000000000000001,               0b00000},
        //     {"FCMP.S: 1.0 <= 2.0",                           OP_FCMP_S,      CMP_LE,    CVT_NN,    INT,     f32_to_u32(1.0f),                  f32_to_u32(2.0f),                 0x0000000000000001,               0b00000},
        //     {"FCMP.S: 0.0 < -1.0",                           OP_FCMP_S,      CMP_LT,    CVT_NN,    INT,     f32_to_u32(0.0f),                  f32_to_u32(-1.0f),                0x0000000000000000,               0b00000},
        //     {"FCMP.S: 3.0 = 2.0",                            OP_FCMP_S,      CMP_EQ,    CVT_NN,    INT,     f32_to_u32(3.0f),                  f32_to_u32(2.0f),                 0x0000000000000000,               0b00000},
        //     {"FCMP.S: 2.0 <= 1.0",                           OP_FCMP_S,      CMP_LE,    CVT_NN,    INT,     f32_to_u32(2.0f),                  f32_to_u32(1.0f),                 0x0000000000000000,               0b00000},
        //     {"FCMP.S: +0 = -0",                              OP_FCMP_S,      CMP_EQ,    CVT_NN,    INT,     f32_to_u32(0.0f),                  f32_to_u32(-0.0f),                0x0000000000000001,               0b00000},
        //     {"FCMP.S: NaN = 2.0",                            OP_FCMP_S,      CMP_EQ,    CVT_NN,    INT,     f32_to_u32(NAN),                   f32_to_u32(2.0f),                 0x0000000000000000,               0b00000},
        //     {"FCMP.S: SNaN = 2.0",                           OP_FCMP_S,      CMP_EQ,    CVT_NN,    INT,     0x7f800001,                        f32_to_u32(2.0f),                 0x0000000000000000,               0b10000},
        //     {"FCMP.S: Normal <= Denormal",                   OP_FCMP_S,      CMP_LE,    CVT_NN,    INT,     0x00800000,                        0x00000001,                       0x0000000000000000,               0b00000},
        //     {"FCMP.S: Denormal <= Normal",                   OP_FCMP_S,      CMP_LE,    CVT_NN,    INT,     0x00000001,                        0x00800000,                       0x0000000000000001,               0b00000},
        // // DP_Compare
        //     {"FCMP.D: -2.0 < -1.0",                          OP_FCMP_D,      CMP_LT,    CVT_NN,    INT,     f64_to_u64(-2.0),                  f64_to_u64(-1.0),                 0x0000000000000001,               0b00000},
        //     {"FCMP.D: 2.0 = 2.0",                            OP_FCMP_D,      CMP_EQ,    CVT_NN,    INT,     f64_to_u64(2.0),                   f64_to_u64(2.0),                  0x0000000000000001,               0b00000},
        //     {"FCMP.D: 1.0 <= 2.0",                           OP_FCMP_D,      CMP_LE,    CVT_NN,    INT,     f64_to_u64(1.0),                   f64_to_u64(2.0),                  0x0000000000000001,               0b00000},
        //     {"FCMP.D: 0.0 < -1.0",                           OP_FCMP_D,      CMP_LT,    CVT_NN,    INT,     f64_to_u64(0.0),                   f64_to_u64(-1.0),                 0x0000000000000000,               0b00000},
        //     {"FCMP.D: 3.0 = 2.0",                            OP_FCMP_D,      CMP_EQ,    CVT_NN,    INT,     f64_to_u64(3.0),                   f64_to_u64(2.0),                  0x0000000000000000,               0b00000},
        //     {"FCMP.D: 2.0 <= 1.0",                           OP_FCMP_D,      CMP_LE,    CVT_NN,    INT,     f64_to_u64(2.0),                   f64_to_u64(1.0),                  0x0000000000000000,               0b00000},
        //     {"FCMP.D: +0 = -0",                              OP_FCMP_D,      CMP_EQ,    CVT_NN,    INT,     f64_to_u64(0.0),                   f64_to_u64(-0.0),                 0x0000000000000001,               0b00000},
        //     {"FCMP.D: NaN = 2.0",                            OP_FCMP_D,      CMP_EQ,    CVT_NN,    INT,     f64_to_u64(NAN),                   f64_to_u64(2.0),                  0x0000000000000000,               0b00000},
        //     {"FCMP.D: SNaN = 2.0",                           OP_FCMP_D,      CMP_EQ,    CVT_NN,    INT,     0xfff0000000000001,                f64_to_u64(2.0),                  0x0000000000000000,               0b10000},
        //     {"FCMP.D: Normal <= Denormal",                   OP_FCMP_D,      CMP_LE,    CVT_NN,    INT,     0x0010000000000000,                0x0000000000000001,               0x0000000000000000,               0b00000},
        //     {"FCMP.D: Denormal <= Normal",                   OP_FCMP_D,      CMP_LE,    CVT_NN,    INT,     0x0000000000000001,                0x0010000000000000,               0x0000000000000001,               0b00000},
        // // --- Conversion Tests ---    
        // // SP_Convert    
        //     {"FCVT.D.S: NaN -> NaN",                         OP_FCVT_D_S,    RNE,       CVT_NN,    FP64,    f32_to_u32(NAN),                   0,                                f64_to_u64(NAN),                  0b10000},
        //     {"FCVT.D.S: Inf -> Inf",                         OP_FCVT_D_S,    RNE,       CVT_NN,    FP64,    f32_to_u32(INFINITY),              0,                                f64_to_u64(INFINITY),             0b00000},
        //     {"FCVT.WU.S: NaN -> Max uint",                   OP_FCVT_W_S,    RNE,       CVT_WU,    UINT,    f32_to_u32(NAN),                   0,                                4294967295U,                      0b10000},
        //     {"FCVT.WU.S: Inf -> Max uint",                   OP_FCVT_W_S,    RNE,       CVT_WU,    UINT,    f32_to_u32(INFINITY),              0,                                4294967295U,                      0b10100},
        //     {"FCVT.WU.S: -Inf -> 0",                         OP_FCVT_W_S,    RNE,       CVT_WU,    UINT,    f32_to_u32(-INFINITY),             0,                                0U,                               0b10000},
        //     {"FCVT.W.S: NaN -> Max uint",                    OP_FCVT_W_S,    RNE,       CVT_W,     INT,     f32_to_u32(NAN),                   0,                                i32_to_u32(INT32_MIN),            0b10000},
        //     {"FCVT.W.S: Inf -> Max uint",                    OP_FCVT_W_S,    RNE,       CVT_W,     INT,     f32_to_u32(INFINITY),              0,                                i32_to_u32(INT32_MAX),            0b10100},
        //     {"FCVT.W.S: -Inf -> 0",                          OP_FCVT_W_S,    RNE,       CVT_W,     INT,     f32_to_u32(-INFINITY),             0,                                i32_to_u32(INT32_MIN),            0b10100},
        //     {"FCVT.D.S: float(0.0) -> double",               OP_FCVT_D_S,    RNE,       CVT_NN,    FP64,    f32_to_u32(0.0f),                  0,                                f64_to_u64(0.0),                  0b00000},//
        //     {"FCVT.D.S: float(3.75) -> double",              OP_FCVT_D_S,    RNE,       CVT_NN,    FP64,    f32_to_u32(3.75f),                 0,                                f64_to_u64(3.75),                 0b00000},
        //     {"FCVT.D.S: float(-3.75) -> double",             OP_FCVT_D_S,    RNE,       CVT_NN,    FP64,    f32_to_u32(-3.75f),                0,                                f64_to_u64(-3.75),                0b00000},
        //     {"FCVT.D.S: Max float -> double",                OP_FCVT_D_S,    RNE,       CVT_NN,    FP64,    0x7f7fffff,                        0,                                0x47EFFFFFE0000000,               0b00000},
        //     {"FCVT.D.S: Min Denormal -> double",             OP_FCVT_D_S,    RNE,       CVT_NN,    FP64,    0x00000001,                        0,                                0x36A0000000000000,               0b00000},
        //     {"FCVT.WU.S: float(0.0) -> uint",                OP_FCVT_W_S,    RUP,       CVT_WU,    UINT,    f32_to_u32(0.0f),                  0,                                0U,                               0b00000},//
        //     {"FCVT.WU.S: float(0.75) -> uint",               OP_FCVT_W_S,    RUP,       CVT_WU,    UINT,    f32_to_u32(0.75f),                 0,                                1U,                               0b00001},
        //     {"FCVT.WU.S: float(2.0) -> uint",                OP_FCVT_W_S,    RNE,       CVT_WU,    UINT,    f32_to_u32(2.0f),                  0,                                2U,                               0b00000},
        //     {"FCVT.WU.S: float(3.75) -> uint",               OP_FCVT_W_S,    RNE,       CVT_WU,    UINT,    f32_to_u32(3.75f),                 0,                                4U,                               0b00001},
        //     {"FCVT.WU.S: float(-3.75) -> uint",              OP_FCVT_W_S,    RNE,       CVT_WU,    UINT,    f32_to_u32(-3.75f),                0,                                0U,                               0b10000},
        //     {"FCVT.WU.S: float(31457280.0) -> uint",         OP_FCVT_W_S,    RNE,       CVT_WU,    UINT,    f32_to_u32(31457280.0f),           0,                                31457280U,                        0b00000},
        //     {"FCVT.WU.S: float(2.1) -> uint (RNE)",          OP_FCVT_W_S,    RNE,       CVT_WU,    UINT,    f32_to_u32(2.1f),                  0,                                2U,                               0b00001},
        //     {"FCVT.WU.S: float(2.1) -> uint (RTZ)",          OP_FCVT_W_S,    RTZ,       CVT_WU,    UINT,    f32_to_u32(2.1f),                  0,                                2U,                               0b00001},
        //     {"FCVT.WU.S: float(2.1) -> uint (RUP)",          OP_FCVT_W_S,    RUP,       CVT_WU,    UINT,    f32_to_u32(2.1f),                  0,                                3U,                               0b00001},
        //     {"FCVT.WU.S: float(2.1) -> uint (RDN)",          OP_FCVT_W_S,    RDN,       CVT_WU,    UINT,    f32_to_u32(2.1f),                  0,                                2U,                               0b00001},
        //     {"FCVT.WU.S: float(2.1) -> uint (RMM)",          OP_FCVT_W_S,    RMM,       CVT_WU,    UINT,    f32_to_u32(2.1f),                  0,                                3U,                               0b00001},
        //     {"FCVT.W.S: float(0.0) -> int",                  OP_FCVT_W_S,    RUP,       CVT_W,     INT,     f32_to_u32(0.0f),                  0,                                i32_to_u32(0),                    0b00000},//
        //     {"FCVT.W.S: float(0.75) -> int",                 OP_FCVT_W_S,    RUP,       CVT_W,     INT,     f32_to_u32(0.75f),                 0,                                i32_to_u32(1),                    0b00001},
        //     {"FCVT.W.S: float(-0.75) -> int",                OP_FCVT_W_S,    RDN,       CVT_W,     INT,     f32_to_u32(-0.75f),                0,                                i32_to_u32(-1),                   0b00001},
        //     {"FCVT.W.S: float(3.75) -> int",                 OP_FCVT_W_S,    RNE,       CVT_W,     INT,     f32_to_u32(3.75f),                 0,                                i32_to_u32(4),                    0b00001},
        //     {"FCVT.W.S: float(-3.75) -> int",                OP_FCVT_W_S,    RNE,       CVT_W,     INT,     f32_to_u32(-3.75f),                0,                                i32_to_u32(-4),                   0b00001},
        //     {"FCVT.W.S: float(31457280.0) -> int",           OP_FCVT_W_S,    RNE,       CVT_W,     INT,     f32_to_u32(31457280.0f),           0,                                i32_to_u32(31457280),             0b00000},
        //     {"FCVT.W.S: float(-31457280.0) -> int",          OP_FCVT_W_S,    RNE,       CVT_W,     INT,     f32_to_u32(-31457280.0f),          0,                                i32_to_u32(-31457280),            0b00000},
        //     {"FCVT.W.S: float(2147483648.0) -> int",         OP_FCVT_W_S,    RUP,       CVT_W,     INT,     f32_to_u32(2147483648.0f),         0,                                i32_to_u32(INT32_MAX),            0b10101},
        //     {"FCVT.W.S: float(-2147483648.0) -> int",        OP_FCVT_W_S,    RDN,       CVT_W,     INT,     f32_to_u32(-2147483648.0f),        0,                                i32_to_u32(INT32_MIN),            0b00000},
        //     {"FCVT.W.S: float(2.1) -> int (RNE)",            OP_FCVT_W_S,    RNE,       CVT_W,     INT,     f32_to_u32(2.1f),                  0,                                i32_to_u32(2),                    0b00001},
        //     {"FCVT.W.S: float(2.1) -> int (RTZ)",            OP_FCVT_W_S,    RTZ,       CVT_W,     INT,     f32_to_u32(2.1f),                  0,                                i32_to_u32(2),                    0b00001},
        //     {"FCVT.W.S: float(2.1) -> int (RUP)",            OP_FCVT_W_S,    RUP,       CVT_W,     INT,     f32_to_u32(2.1f),                  0,                                i32_to_u32(3),                    0b00001},
        //     {"FCVT.W.S: float(2.1) -> int (RDN)",            OP_FCVT_W_S,    RDN,       CVT_W,     INT,     f32_to_u32(2.1f),                  0,                                i32_to_u32(2),                    0b00001},
        //     {"FCVT.W.S: float(2.1) -> int (RMM)",            OP_FCVT_W_S,    RMM,       CVT_W,     INT,     f32_to_u32(2.1f),                  0,                                i32_to_u32(3),                    0b00001},
        //     {"FCVT.W.S: float(-2.1) -> int (RNE)",           OP_FCVT_W_S,    RNE,       CVT_W,     INT,     f32_to_u32(-2.1f),                 0,                                i32_to_u32(-2),                   0b00001},
        //     {"FCVT.W.S: float(-2.1) -> int (RTZ)",           OP_FCVT_W_S,    RTZ,       CVT_W,     INT,     f32_to_u32(-2.1f),                 0,                                i32_to_u32(-2),                   0b00001},
        //     {"FCVT.W.S: float(-2.1) -> int (RUP)",           OP_FCVT_W_S,    RUP,       CVT_W,     INT,     f32_to_u32(-2.1f),                 0,                                i32_to_u32(-2),                   0b00001},
        //     {"FCVT.W.S: float(-2.1) -> int (RDN)",           OP_FCVT_W_S,    RDN,       CVT_W,     INT,     f32_to_u32(-2.1f),                 0,                                i32_to_u32(-3),                   0b00001},
        //     {"FCVT.W.S: float(-2.1) -> int (RMM)",           OP_FCVT_W_S,    RMM,       CVT_W,     INT,     f32_to_u32(-2.1f),                 0,                                i32_to_u32(-3),                   0b00001},
        //     {"FCVT.D.W: int(0) -> double",                   OP_FCVT_D_W,    RNE,       CVT_W,     FP64,    i32_to_u32(0),                     0,                                f64_to_u64(0.0),                  0b00000},//
        //     {"FCVT.D.W: int(3) -> double",                   OP_FCVT_D_W,    RNE,       CVT_W,     FP64,    i32_to_u32(3),                     0,                                f64_to_u64(3.0),                  0b00000},
        //     {"FCVT.D.W: int(-3) -> double",                  OP_FCVT_D_W,    RNE,       CVT_W,     FP64,    i32_to_u32(-3),                    0,                                f64_to_u64(-3.0),                 0b00000},
        //     {"FCVT.D.W: int(2147483647) -> double",          OP_FCVT_D_W,    RNE,       CVT_W,     FP64,    i32_to_u32(2147483647),            0,                                f64_to_u64(2147483647.0),         0b00000},
        //     {"FCVT.D.W: int(-2147483648) -> double",         OP_FCVT_D_W,    RNE,       CVT_W,     FP64,    i32_to_u32(-2147483648),           0,                                f64_to_u64(-2147483648.0),        0b00000},
        //     {"FCVT.D.WU: uint(0) -> double",                 OP_FCVT_D_W,    RNE,       CVT_WU,    FP64,    0U,                                0,                                f64_to_u64(0.0),                  0b00000},//
        //     {"FCVT.D.WU: uint(3) -> double",                 OP_FCVT_D_W,    RNE,       CVT_WU,    FP64,    3U,                                0,                                f64_to_u64(3.0),                  0b00000},
        //     {"FCVT.D.WU: uint(2147483647) -> double",        OP_FCVT_D_W,    RNE,       CVT_WU,    FP64,    2147483647U,                       0,                                f64_to_u64(2147483647.0),         0b00000},
        //     {"FCVT.D.WU: uint(4294967295) -> double",        OP_FCVT_D_W,    RNE,       CVT_WU,    FP64,    4294967295U,                       0,                                f64_to_u64(4294967295.0),         0b00000},
        // // DP_Convert    
        //     {"FCVT.S.D: NaN -> NaN",                         OP_FCVT_S_D,    RNE,       CVT_NN,    FP32,    f64_to_u64(NAN),                   0,                                f32_to_u32(NAN),                  0b10000},
        //     {"FCVT.S.D: Inf -> Inf",                         OP_FCVT_S_D,    RNE,       CVT_NN,    FP32,    f64_to_u64(INFINITY),              0,                                f32_to_u32(INFINITY),             0b00000},
        //     {"FCVT.WU.D: NaN -> Max uint",                   OP_FCVT_W_D,    RNE,       CVT_WU,    UINT,    f64_to_u64(NAN),                   0,                                4294967295U,                      0b10000},
        //     {"FCVT.WU.D: Inf -> Max uint",                   OP_FCVT_W_D,    RNE,       CVT_WU,    UINT,    f64_to_u64(INFINITY),              0,                                4294967295U,                      0b10100},
        //     {"FCVT.WU.D: -Inf -> 0",                         OP_FCVT_W_D,    RNE,       CVT_WU,    UINT,    f64_to_u64(-INFINITY),             0,                                0U,                               0b10000},
        //     {"FCVT.W.D: NaN -> Max uint",                    OP_FCVT_W_D,    RNE,       CVT_W,     INT,     f64_to_u64(NAN),                   0,                                i32_to_u32(INT32_MIN),            0b10000},
        //     {"FCVT.W.D: Inf -> Max uint",                    OP_FCVT_W_D,    RNE,       CVT_W,     INT,     f64_to_u64(INFINITY),              0,                                i32_to_u32(INT32_MAX),            0b10100},
        //     {"FCVT.W.D: -Inf -> 0",                          OP_FCVT_W_D,    RNE,       CVT_W,     INT,     f64_to_u64(-INFINITY),             0,                                i32_to_u32(INT32_MIN),            0b10100},
        //     {"FCVT.S.D: double(0.0) -> float",               OP_FCVT_S_D,    RNE,       CVT_NN,    FP32,    f64_to_u64(0.0),                   0,                                f32_to_u32(0.0f),                 0b00000},//
        //     {"FCVT.S.D: double(3.75) -> float",              OP_FCVT_S_D,    RNE,       CVT_NN,    FP32,    f64_to_u64(3.75),                  0,                                f32_to_u32(3.75f),                0b00000},
        //     {"FCVT.S.D: double(-3.75) -> float",             OP_FCVT_S_D,    RNE,       CVT_NN,    FP32,    f64_to_u64(-3.75),                 0,                                f32_to_u32(-3.75f),               0b00000},
        //     {"FCVT.S.D: double(around 2^127) -> float",      OP_FCVT_S_D,    RNE,       CVT_NN,    FP32,    0x47EE000000000000,                0,                                0x7f700000,                       0b00000},
        //     {"FCVT.S.D: double(around -2^127) -> float",     OP_FCVT_S_D,    RNE,       CVT_NN,    FP32,    0xC7EE000000000000,                0,                                0xff700000,                       0b00000},
        //     {"FCVT.S.D: double(max float) -> float",         OP_FCVT_S_D,    RNE,       CVT_NN,    FP32,    0x47EFFFFFE0000000,                0,                                0x7f7fffff,                       0b00000},
        //     {"FCVT.S.D: double(min float) -> float",         OP_FCVT_S_D,    RNE,       CVT_NN,    FP32,    0xC7EFFFFFE0000000,                0,                                0xff7fffff,                       0b00000},
        //     {"FCVT.S.D: double(2e115) -> Inf",               OP_FCVT_S_D,    RNE,       CVT_NN,    FP32,    f64_to_u64(2e115),                 0,                                f32_to_u32(INFINITY),             0b10100},
        //     {"FCVT.S.D: double(-2e115) -> -Inf",             OP_FCVT_S_D,    RNE,       CVT_NN,    FP32,    f64_to_u64(-2e115),                0,                                f32_to_u32(-INFINITY),            0b10100},
        //     {"FCVT.S.D: double(max denormal) -> float",      OP_FCVT_S_D,    RNE,       CVT_NN,    FP32,    0x3800000000000000,                0,                                0x00400000,                       0b00000},
        //     {"FCVT.S.D: double(min denormal) -> float",      OP_FCVT_S_D,    RNE,       CVT_NN,    FP32,    0x36A0000000000000,                0,                                0x00000001,                       0b00000},
        //     {"FCVT.WU.D: double(0.0) -> uint",               OP_FCVT_W_D,    RNE,       CVT_WU,    UINT,    f64_to_u64(0.0),                   0,                                0U,                               0b00000},//
        //     {"FCVT.WU.D: double(0.75) -> uint",              OP_FCVT_W_D,    RUP,       CVT_WU,    UINT,    f64_to_u64(0.75),                  0,                                1U,                               0b00001},
        //     {"FCVT.WU.D: double(-0.75) -> uint",             OP_FCVT_W_D,    RNE,       CVT_WU,    UINT,    f64_to_u64(-0.75),                 0,                                0U,                               0b10000},
        //     {"FCVT.WU.D: double(3.75) -> uint",              OP_FCVT_W_D,    RNE,       CVT_WU,    UINT,    f64_to_u64(3.75),                  0,                                4U,                               0b00001},
        //     {"FCVT.WU.D: double(-3.75) -> uint",             OP_FCVT_W_D,    RNE,       CVT_WU,    UINT,    f64_to_u64(-3.75),                 0,                                0U,                               0b10000},
        //     {"FCVT.WU.D: double(31457280.0) -> uint",        OP_FCVT_W_D,    RNE,       CVT_WU,    UINT,    f64_to_u64(31457280.0),            0,                                31457280U,                        0b00000},
        //     {"FCVT.WU.D: double(-31457280.0) -> uint",       OP_FCVT_W_D,    RNE,       CVT_WU,    UINT,    f64_to_u64(-31457280.0),           0,                                0U,                               0b10000},
        //     {"FCVT.WU.D: double(4294967295.0) -> uint",      OP_FCVT_W_D,    RNE,       CVT_WU,    UINT,    0x41EFFFFFFFE00000,                0,                                4294967295U,                      0b00000},
        //     {"FCVT.WU.D: double(2.1) -> uint (RNE)",         OP_FCVT_W_D,    RNE,       CVT_WU,    UINT,    f64_to_u64(2.1),                   0,                                2U,                               0b00001},
        //     {"FCVT.WU.D: double(2.1) -> uint (RTZ)",         OP_FCVT_W_D,    RTZ,       CVT_WU,    UINT,    f64_to_u64(2.1),                   0,                                2U,                               0b00001},
        //     {"FCVT.WU.D: double(2.1) -> uint (RUP)",         OP_FCVT_W_D,    RUP,       CVT_WU,    UINT,    f64_to_u64(2.1),                   0,                                3U,                               0b00001},
        //     {"FCVT.WU.D: double(2.1) -> uint (RDN)",         OP_FCVT_W_D,    RDN,       CVT_WU,    UINT,    f64_to_u64(2.1),                   0,                                2U,                               0b00001},
        //     {"FCVT.WU.D: double(2.1) -> uint (RMM)",         OP_FCVT_W_D,    RMM,       CVT_WU,    UINT,    f64_to_u64(2.1),                   0,                                3U,                               0b00001},
        //     {"FCVT.W.D: double(0.0) -> int",                 OP_FCVT_W_D,    RNE,       CVT_W,     INT,     f64_to_u64(0.0),                   0,                                0U,                               0b00000},//
        //     {"FCVT.W.D: double(0.75) -> int",                OP_FCVT_W_D,    RUP,       CVT_W,     INT,     f64_to_u64(0.75),                  0,                                1U,                               0b00001},
        //     {"FCVT.W.D: double(-0.75) -> int",               OP_FCVT_W_D,    RDN,       CVT_W,     INT,     f64_to_u64(-0.75),                 0,                                -1U,                              0b00001},
        //     {"FCVT.W.D: double(3.75) -> int",                OP_FCVT_W_D,    RNE,       CVT_W,     INT,     f64_to_u64(3.75),                  0,                                4U,                               0b00001},
        //     {"FCVT.W.D: double(-3.75) -> int",               OP_FCVT_W_D,    RNE,       CVT_W,     INT,     f64_to_u64(-3.75),                 0,                                -4U,                              0b00001},
        //     {"FCVT.W.D: double(31457280.0) -> int",          OP_FCVT_W_D,    RNE,       CVT_W,     INT,     f64_to_u64(31457280.0),            0,                                31457280U,                        0b00000},
        //     {"FCVT.W.D: double(-31457280.0) -> int",         OP_FCVT_W_D,    RNE,       CVT_W,     INT,     f64_to_u64(-31457280.0),           0,                                -31457280U,                       0b00000},
        //     {"FCVT.W.D: double(2147483647.0) -> int",        OP_FCVT_W_D,    RNE,       CVT_W,     INT,     0x41DFFFFFFFC00000,                0,                                2147483647U,                      0b00000},
        //     {"FCVT.W.D: double(-2147483648.0) -> int",       OP_FCVT_W_D,    RNE,       CVT_W,     INT,     0xC1E0000000000000,                0,                                -2147483648U,                     0b00000},
        //     {"FCVT.W.D: double(2.1) -> int (RNE)",           OP_FCVT_W_D,    RNE,       CVT_W,     INT,     f64_to_u64(2.1),                   0,                                2U,                               0b00001},
        //     {"FCVT.W.D: double(2.1) -> int (RTZ)",           OP_FCVT_W_D,    RTZ,       CVT_W,     INT,     f64_to_u64(2.1),                   0,                                2U,                               0b00001},
        //     {"FCVT.W.D: double(2.1) -> int (RUP)",           OP_FCVT_W_D,    RUP,       CVT_W,     INT,     f64_to_u64(2.1),                   0,                                3U,                               0b00001},
        //     {"FCVT.W.D: double(2.1) -> int (RDN)",           OP_FCVT_W_D,    RDN,       CVT_W,     INT,     f64_to_u64(2.1),                   0,                                2U,                               0b00001},
        //     {"FCVT.W.D: double(2.1) -> int (RMM)",           OP_FCVT_W_D,    RMM,       CVT_W,     INT,     f64_to_u64(2.1),                   0,                                3U,                               0b00001},
        //     {"FCVT.S.W: int(0) -> float",                    OP_FCVT_S_W,    RNE,       CVT_W,     FP32,    i32_to_u32(0),                     0,                                f32_to_u32(0.0),                  0b00000},//
        //     {"FCVT.S.W: int(3) -> float",                    OP_FCVT_S_W,    RNE,       CVT_W,     FP32,    i32_to_u32(3),                     0,                                f32_to_u32(3.0),                  0b00000},
        //     {"FCVT.S.W: int(-3) -> float",                   OP_FCVT_S_W,    RNE,       CVT_W,     FP32,    i32_to_u32(-3),                    0,                                f32_to_u32(-3.0),                 0b00000},
        //     {"FCVT.S.W: int(2147483647) -> float",           OP_FCVT_S_W,    RNE,       CVT_W,     FP32,    i32_to_u32(2147483647),            0,                                f32_to_u32(2147483648.0),         0b00001},
        //     {"FCVT.S.W: int(-2147483648) -> float",          OP_FCVT_S_W,    RNE,       CVT_W,     FP32,    i32_to_u32(-2147483648),           0,                                f32_to_u32(-2147483648.0),        0b00000},
        //     {"FCVT.S.WU: uint(0) -> float",                  OP_FCVT_S_W,    RNE,       CVT_WU,    FP32,    0U,                                0,                                f32_to_u32(0.0),                  0b00000},//
        //     {"FCVT.S.WU: uint(3) -> float",                  OP_FCVT_S_W,    RNE,       CVT_WU,    FP32,    3U,                                0,                                f32_to_u32(3.0),                  0b00000},
        //     {"FCVT.S.WU: uint(2147483647) -> float",         OP_FCVT_S_W,    RNE,       CVT_WU,    FP32,    2147483647U,                       0,                                f32_to_u32(2147483648.0),         0b00001},
        //     {"FCVT.S.WU: uint(4294967295) -> float",         OP_FCVT_S_W,    RNE,       CVT_WU,    FP32,    4294967295U,                       0,                                f32_to_u32(4294967296.0),         0b00001},
        // // --- Multiplication Tests ---    
        // // SP_Multiplier    
        //     {"FMUL.S: 0.0 * 2.5",                            OP_FMUL_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(0.0f),                  f32_to_u32(2.5f),                 f32_to_u32(0.0f),                 0b00000},
        //     {"FMUL.S: -0.0 * -0.0",                          OP_FMUL_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(-0.0f),                 f32_to_u32(-0.0f),                f32_to_u32(0.0f),                 0b00000},
        //     {"FMUL.S: -0.0 * 2.5",                           OP_FMUL_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(-0.0f),                 f32_to_u32(2.5f),                 f32_to_u32(-0.0f),                0b00000},
        //     {"FMUL.S: Inf * 2.5",                            OP_FMUL_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(INFINITY),              f32_to_u32(2.5f),                 f32_to_u32(INFINITY),             0b00000},
        //     {"FMUL.S: Inf * 0.0 -> invalid",                 OP_FMUL_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(INFINITY),              f32_to_u32(0.0f),                 f32_to_u32(NAN),                  0b10000},
        //     {"FMUL.S: Inf * -Inf",                           OP_FMUL_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(INFINITY),              f32_to_u32(-INFINITY),            f32_to_u32(-INFINITY),            0b00000},
        //     {"FMUL.S: NaN * 3.5 -> invalid",                 OP_FMUL_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(NAN),                   f32_to_u32(3.5f),                 f32_to_u32(NAN),                  0b10000},
        //     {"FMUL.S: 0.5 * 0.25",                           OP_FMUL_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(0.5f),                  f32_to_u32(0.25f),                f32_to_u32(0.125f),               0b00000},//
        //     {"FMUL.S: 3.0 * 2.5",                            OP_FMUL_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(3.0f),                  f32_to_u32(2.5f),                 f32_to_u32(7.5f),                 0b00000},
        //     {"FMUL.S: 1.875 * 1.875",                        OP_FMUL_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(1.875f),                f32_to_u32(1.875f),               f32_to_u32(3.515625f),            0b00000},
        //     {"FMUL.S: 1.875 * -1.875",                       OP_FMUL_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(1.875f),                f32_to_u32(-1.875f),              f32_to_u32(-3.515625f),           0b00000},
        //     {"FMUL.S: 0.0 * 123.456",                        OP_FMUL_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(0.0f),                  f32_to_u32(123.456f),             f32_to_u32(0.0f),                 0b00000},
        //     {"FMUL.S: -2.0 * 3.0",                           OP_FMUL_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(-2.0f),                 f32_to_u32(3.0f),                 f32_to_u32(-6.0f),                0b00000},
        //     {"FMUL.S: 1e38 * 1e10 (overflow)",               OP_FMUL_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(1e38f),                 f32_to_u32(1e10f),                f32_to_u32(INFINITY),             0b00101},
        //     {"FMUL.S: 1e-38 * 1e-10 (underflow)",            OP_FMUL_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(1e-38f),                f32_to_u32(1e-10f),               f32_to_u32(0.0f),                 0b00011},
        //     {"FMUL.S: 1e-45 * 1.0",                          OP_FMUL_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(1e-45f),                f32_to_u32(1.0f),                 0x00000001,                       0b00000},
        //     {"FMUL.S: 1e-45 * 8.0",                          OP_FMUL_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(1e-45f),                f32_to_u32(8.0f),                 0x00000008,                       0b00000},
        //     {"FMUL.S: 2.1474836E9 * 1e-45",                  OP_FMUL_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(2.1474836E9f),          f32_to_u32(1e-45f),               0x04800000,                       0b00000},
        //     {"FMUL.S: 0.3333333 * 0.3 (RNE)",                OP_FMUL_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(0.3333333f),            f32_to_u32(0.3f),                 0x3dcccccd,                       0b00001},
        //     {"FMUL.S: 0.3333333 * 0.3 (RTZ)",                OP_FMUL_S,      RTZ,       CVT_NN,    FP32,    f32_to_u32(0.3333333f),            f32_to_u32(0.3f),                 0x3dcccccc,                       0b00001},
        //     {"FMUL.S: 0.3333333 * 0.3 (RUP)",                OP_FMUL_S,      RUP,       CVT_NN,    FP32,    f32_to_u32(0.3333333f),            f32_to_u32(0.3f),                 0x3dcccccd,                       0b00001},
        //     {"FMUL.S: 0.3333333 * 0.3 (RDN)",                OP_FMUL_S,      RDN,       CVT_NN,    FP32,    f32_to_u32(0.3333333f),            f32_to_u32(0.3f),                 0x3dcccccc,                       0b00001},
        //     {"FMUL.S: 0.3333333 * 0.3 (RMM)",                OP_FMUL_S,      RMM,       CVT_NN,    FP32,    f32_to_u32(0.3333333f),            f32_to_u32(0.3f),                 0x3dcccccd,                       0b00001},
        // // DP_Multiplier    
        //     {"FMUL.D: 0.0 * 2.5",                            OP_FMUL_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(0.0),                   f64_to_u64(2.5),                  f64_to_u64(0.0),                  0b00000},
        //     {"FMUL.D: -0.0 * -0.0",                          OP_FMUL_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(-0.0),                  f64_to_u64(-0.0),                 f64_to_u64(0.0),                  0b00000},
        //     {"FMUL.D: -0.0 * 2.5",                           OP_FMUL_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(-0.0),                  f64_to_u64(2.5),                  f64_to_u64(-0.0),                 0b00000},
        //     {"FMUL.D: Inf * 2.5",                            OP_FMUL_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(INFINITY),              f64_to_u64(2.5),                  f64_to_u64(INFINITY),             0b00000},
        //     {"FMUL.D: Inf * 0.0 -> invalid",                 OP_FMUL_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(INFINITY),              f64_to_u64(0.0),                  f64_to_u64(NAN),                  0b10000},
        //     {"FMUL.D: Inf * -Inf",                           OP_FMUL_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(INFINITY),              f64_to_u64(-INFINITY),            f64_to_u64(-INFINITY),            0b00000},
        //     {"FMUL.D: NaN * 3.5 -> invalid",                 OP_FMUL_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(NAN),                   f64_to_u64(3.5),                  f64_to_u64(NAN),                  0b10000},
        //     {"FMUL.D: 0.5 * 0.25",                           OP_FMUL_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(0.5),                   f64_to_u64(0.25),                 f64_to_u64(0.125),                0b00000},//
        //     {"FMUL.D: 3.0 * 2.5",                            OP_FMUL_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(3.0),                   f64_to_u64(2.5),                  f64_to_u64(7.5),                  0b00000},
        //     {"FMUL.D: 1.875 * 1.875",                        OP_FMUL_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(1.875),                 f64_to_u64(1.875),                f64_to_u64(3.515625),             0b00000},
        //     {"FMUL.D: 1.875 * -1.875",                       OP_FMUL_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(1.875),                 f64_to_u64(-1.875),               f64_to_u64(-3.515625),            0b00000},
        //     {"FMUL.D: 0.0 * 123.456",                        OP_FMUL_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(0.0),                   f64_to_u64(123.456),              f64_to_u64(0.0),                  0b00000},
        //     {"FMUL.D: -2.0 * 3.0",                           OP_FMUL_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(-2.0),                  f64_to_u64(3.0),                  f64_to_u64(-6.0),                 0b00000},
        //     {"FMUL.D: 1e300 * 1e100 (overflow)",             OP_FMUL_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(1e300),                 f64_to_u64(1e100),                f64_to_u64(INFINITY),             0b00101},
        //     {"FMUL.D: 1e-300 * 1e-100 (underflow)",          OP_FMUL_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(1e-300),                f64_to_u64(1e-100),               f64_to_u64(0.0),                  0b00011},
        //     {"FMUL.D: Denormal 1 (small norm * small norm)", OP_FMUL_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(pow(2.0, -1020.0)),     f64_to_u64(pow(2.0, -50.0)),      f64_to_u64(pow(2.0, -1070.0)),    0b00000},
        //     {"FMUL.D: Denormal 2 (norm * denorm)",           OP_FMUL_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(pow(2.0, 10.0)),        f64_to_u64(pow(2.0, -1070.0)),    f64_to_u64(pow(2.0, -1060.0)),    0b00000},
        //     {"FMUL.D: Denormal 3 (denorm * denorm)",         OP_FMUL_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(pow(2.0, -1070.0)),     f64_to_u64(pow(2.0, -4.0)),       f64_to_u64(pow(2.0, -1074.0)),    0b00000},
        //     {"FMUL.D: 0.3333333333333333 * 0.3 (RNE)",       OP_FMUL_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(0.3333333333333333),    f64_to_u64(0.3),                  0x3fb9999999999999,               0b00001},
        //     {"FMUL.D: 0.3333333333333333 * 0.3 (RTZ)",       OP_FMUL_D,      RTZ,       CVT_NN,    FP64,    f64_to_u64(0.3333333333333333),    f64_to_u64(0.3),                  0x3fb9999999999998,               0b00001},
        //     {"FMUL.D: 0.3333333333333333 * 0.3 (RUP)",       OP_FMUL_D,      RUP,       CVT_NN,    FP64,    f64_to_u64(0.3333333333333333),    f64_to_u64(0.3),                  0x3fb9999999999999,               0b00001},
        //     {"FMUL.D: 0.3333333333333333 * 0.3 (RDN)",       OP_FMUL_D,      RDN,       CVT_NN,    FP64,    f64_to_u64(0.3333333333333333),    f64_to_u64(0.3),                  0x3fb9999999999998,               0b00001},
        //     {"FMUL.D: 0.3333333333333333 * 0.3 (RMM)",       OP_FMUL_D,      RMM,       CVT_NN,    FP64,    f64_to_u64(0.3333333333333333),    f64_to_u64(0.3),                  0x3fb9999999999999,               0b00001},
        // // --- Division Tests ---
        // // SP_Divider
        //     {"FDIV.S: NaN / 0.25",                           OP_FDIV_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(NAN),                   f32_to_u32(0.25f),                f32_to_u32(NAN),                  0b10000},
        //     {"FDIV.S: Inf / Inf",                            OP_FDIV_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(INFINITY),              f32_to_u32(INFINITY),             f32_to_u32(NAN),                  0b10000},
        //     {"FDIV.S: 0.0 / 0.0",                            OP_FDIV_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(0.0f),                  f32_to_u32(0.0f),                 f32_to_u32(NAN),                  0b10000},
        //     {"FDIV.S: 5.0 / 0.0",                            OP_FDIV_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(5.0f),                  f32_to_u32(0.0f),                 f32_to_u32(INFINITY),             0b01000},
        //     {"FDIV.S: -5.0 / 0.0",                           OP_FDIV_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(-5.0f),                 f32_to_u32(0.0f),                 f32_to_u32(-INFINITY),            0b01000},
        //     {"FDIV.S: Inf / 5.0",                            OP_FDIV_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(INFINITY),              f32_to_u32(5.0f),                 f32_to_u32(INFINITY),             0b00000},
        //     {"FDIV.S: -Inf / 5.0",                           OP_FDIV_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(-INFINITY),             f32_to_u32(5.0f),                 f32_to_u32(-INFINITY),            0b00000},
        //     {"FDIV.S: 0.0 / 5.0",                            OP_FDIV_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(0.0f),                  f32_to_u32(5.0f),                 f32_to_u32(0.0f),                 0b00000},
        //     {"FDIV.S: 5.0 / Inf",                            OP_FDIV_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(5.0f),                  f32_to_u32(INFINITY),             f32_to_u32(0.0f),                 0b00000},
        //     {"FDIV.S: 5.0 / -Inf",                           OP_FDIV_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(5.0f),                  f32_to_u32(-INFINITY),            f32_to_u32(-0.0f),                0b00000},
        //     {"FDIV.S: 0.5 / 0.25",                           OP_FDIV_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(0.5f),                  f32_to_u32(0.25f),                f32_to_u32(2.0f),                 0b00000},//
        //     {"FDIV.S: 3.0 / 6.0",                            OP_FDIV_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(3.0f),                  f32_to_u32(6.0f),                 f32_to_u32(0.5f),                 0b00000},
        //     {"FDIV.S: 80875.0 / 125.0",                      OP_FDIV_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(80875.0f),              f32_to_u32(125.0f),               f32_to_u32(647.0f),               0b00000},
        //     {"FDIV.S: 114514.0 / 1919810.0",                 OP_FDIV_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(114514.0f),             f32_to_u32(1919810.0f),           f32_to_u32(0.05964861f),          0b00001},
        //     {"FDIV.S: min denormal / 0.5",                   OP_FDIV_S,      RNE,       CVT_NN,    FP32,    0x00000001,                        f32_to_u32(0.5f),                 0x00000002,                       0b00000},//
        //     {"FDIV.S: min denormal / 2.0 (UF)",              OP_FDIV_S,      RNE,       CVT_NN,    FP32,    0x00000001,                        f32_to_u32(2.0f),                 f32_to_u32(0.0f),                 0b00011},
        //     {"FDIV.S: max normal / 2.0",                     OP_FDIV_S,      RNE,       CVT_NN,    FP32,    0x7F7FFFFF,                        f32_to_u32(2.0f),                 0x7EFFFFFF,                       0b00000},
        //     {"FDIV.S: max normal / 0.5 (OF)",                OP_FDIV_S,      RNE,       CVT_NN,    FP32,    0x7F7FFFFF,                        f32_to_u32(0.5f),                 f32_to_u32(INFINITY),             0b00101},
        //     {"FDIV.S: 1.0 / 3.0 (RNE)",                      OP_FDIV_S,      RNE,       CVT_NN,    FP32,    f32_to_u32(1.0f),                  f32_to_u32(3.0f),                 0x3eaaaaab,                       0b00001},//
        //     {"FDIV.S: 1.0 / 3.0 (RTZ)",                      OP_FDIV_S,      RTZ,       CVT_NN,    FP32,    f32_to_u32(1.0f),                  f32_to_u32(3.0f),                 0x3eaaaaaa,                       0b00001},
        //     {"FDIV.S: 1.0 / 3.0 (RUP)",                      OP_FDIV_S,      RUP,       CVT_NN,    FP32,    f32_to_u32(1.0f),                  f32_to_u32(3.0f),                 0x3eaaaaab,                       0b00001},
        //     {"FDIV.S: 1.0 / 3.0 (RDN)",                      OP_FDIV_S,      RDN,       CVT_NN,    FP32,    f32_to_u32(1.0f),                  f32_to_u32(3.0f),                 0x3eaaaaaa,                       0b00001},
        //     {"FDIV.S: 1.0 / 3.0 (RMM)",                      OP_FDIV_S,      RMM,       CVT_NN,    FP32,    f32_to_u32(1.0f),                  f32_to_u32(3.0f),                 0x3eaaaaab,                       0b00001},
        // // DP_Divider
        //     {"FDIV.D: NaN / 0.25",                           OP_FDIV_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(NAN),                   f64_to_u64(0.25),                 f64_to_u64(NAN),                  0b10000},
        //     {"FDIV.D: Inf / Inf",                            OP_FDIV_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(INFINITY),              f64_to_u64(INFINITY),             f64_to_u64(NAN),                  0b10000},
        //     {"FDIV.D: 0.0 / 0.0",                            OP_FDIV_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(0.0),                   f64_to_u64(0.0),                  f64_to_u64(NAN),                  0b10000},
        //     {"FDIV.D: 5.0 / 0.0",                            OP_FDIV_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(5.0),                   f64_to_u64(0.0),                  f64_to_u64(INFINITY),             0b01000},
        //     {"FDIV.D: -5.0 / 0.0",                           OP_FDIV_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(-5.0),                  f64_to_u64(0.0),                  f64_to_u64(-INFINITY),            0b01000},
        //     {"FDIV.D: Inf / 5.0",                            OP_FDIV_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(INFINITY),              f64_to_u64(5.0),                  f64_to_u64(INFINITY),             0b00000},
        //     {"FDIV.D: -Inf / 5.0",                           OP_FDIV_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(-INFINITY),             f64_to_u64(5.0),                  f64_to_u64(-INFINITY),            0b00000},
        //     {"FDIV.D: 0.0 / 5.0",                            OP_FDIV_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(0.0),                   f64_to_u64(5.0),                  f64_to_u64(0.0),                  0b00000},
        //     {"FDIV.D: 5.0 / Inf",                            OP_FDIV_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(5.0),                   f64_to_u64(INFINITY),             f64_to_u64(0.0),                  0b00000},
        //     {"FDIV.D: 5.0 / -Inf",                           OP_FDIV_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(5.0),                   f64_to_u64(-INFINITY),            f64_to_u64(-0.0),                 0b00000},
        //     {"FDIV.D: 0.5 / 0.25",                           OP_FDIV_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(0.5),                   f64_to_u64(0.25),                 f64_to_u64(2.0),                  0b00000},//
        //     {"FDIV.D: 3.0 / 6.0",                            OP_FDIV_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(3.0),                   f64_to_u64(6.0),                  f64_to_u64(0.5),                  0b00000},
        //     {"FDIV.D: 80875.0 / 125.0",                      OP_FDIV_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(80875.0),               f64_to_u64(125.0),                f64_to_u64(647.0),                0b00000},
        //     {"FDIV.D: 114514.0 / 1919810.0",                 OP_FDIV_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(114514.0),              f64_to_u64(1919810.0),            0x3FAE8A4343835946,               0b00001},
        //     {"FDIV.D: min denormal / 0.5",                   OP_FDIV_D,      RNE,       CVT_NN,    FP64,    0x0000000000000001,                f64_to_u64(0.5),                  0x0000000000000002,               0b00000},//
        //     {"FDIV.D: min denormal / 2.0 (UF)",              OP_FDIV_D,      RNE,       CVT_NN,    FP64,    0x0000000000000001,                f64_to_u64(2.0),                  f64_to_u64(0.0),                  0b00011},
        //     {"FDIV.D: max normal / 2.0",                     OP_FDIV_D,      RNE,       CVT_NN,    FP64,    0x7FEFFFFFFFFFFFFF,                f64_to_u64(2.0),                  0x7FDFFFFFFFFFFFFF,               0b00000},
        //     {"FDIV.D: max normal / 0.5 (OF)",                OP_FDIV_D,      RNE,       CVT_NN,    FP64,    0x7FEFFFFFFFFFFFFF,                f64_to_u64(0.5),                  f64_to_u64(INFINITY),             0b00101},
        //     {"FDIV.D: 1.0 / 3.0 (RNE)",                      OP_FDIV_D,      RNE,       CVT_NN,    FP64,    f64_to_u64(1.0),                   f64_to_u64(3.0),                  0x3fd5555555555555,               0b00001},//
        //     {"FDIV.D: 1.0 / 3.0 (RTZ)",                      OP_FDIV_D,      RTZ,       CVT_NN,    FP64,    f64_to_u64(1.0),                   f64_to_u64(3.0),                  0x3fd5555555555555,               0b00001},
        //     {"FDIV.D: 1.0 / 3.0 (RUP)",                      OP_FDIV_D,      RUP,       CVT_NN,    FP64,    f64_to_u64(1.0),                   f64_to_u64(3.0),                  0x3fd5555555555556,               0b00001},
        //     {"FDIV.D: 1.0 / 3.0 (RDN)",                      OP_FDIV_D,      RDN,       CVT_NN,    FP64,    f64_to_u64(1.0),                   f64_to_u64(3.0),                  0x3fd5555555555555,               0b00001},
            {"FDIV.D: 1.0 / 3.0 (RMM)",                      OP_FDIV_D,      RMM,       CVT_NN,    FP64,    f64_to_u64(1.0),                   f64_to_u64(3.0),                  0x3fd5555555555556,               0b00001},
        // --- Sqrt Tests ---
        // SP_Sqrt
            {"FSQRT.S: 4.0",                                 OP_FSQRT_S,     RTZ,       CVT_NN,    FP32,    f32_to_u32(4.0f),                  0,                                f32_to_u32(2.0f),                 0b00000},
            {"FSQRT.S: 0.25",                                OP_FSQRT_S,     RTZ,       CVT_NN,    FP32,    f32_to_u32(0.25f),                 0,                                f32_to_u32(0.5f),                 0b00000},
            {"FSQRT.S: 121.0",                               OP_FSQRT_S,     RTZ,       CVT_NN,    FP32,    f32_to_u32(121.0f),                0,                                f32_to_u32(11.0f),                0b00000},
            {"FSQRT.S: 22.7",                               OP_FSQRT_S,     RTZ,       CVT_NN,    FP32,    f32_to_u32(22.7f),                0,                                f32_to_u32(11.0f),                0b00000},
            {"FSQRT.S: 171.0",                               OP_FSQRT_S,     DYN,       CVT_NN,    FP32,    f32_to_u32(171.0f),                0,                                0x41513A26,                0b00000},
            {"FSQRT.S: 10000.0",                               OP_FSQRT_S,     DYN,       CVT_NN,    FP32,    f32_to_u32(10000.0f),                0,                                f32_to_u32(100.0f),                0b00000},
    };

    // reset
    top->rst_n = 0;
    top->clk = 0;
    top->eval();
    main_time++;
    if (tfp) tfp->dump(main_time);
    top->clk = 1;
    top->eval();
    main_time++;
    if (tfp) tfp->dump(main_time);
    top->rst_n = 1;

    // run tests
    int passed_count = 0;
    for (const auto& test : test_suite) {
        std::cout << "Running test: " << test.name << " ..." << std::endl;
        if (run_test(top, tfp, test)) {
            std::cout << "  \033[32m[PASS]\033[0m" << std::endl;
            passed_count++;
        }
    }
    
    // Summary
    std::cout << "\n----------------------------------------" << std::endl;
    std::cout << "Test Summary: " << passed_count << " / " << test_suite.size() << " passed." << std::endl;
    std::cout << "----------------------------------------" << std::endl;

    // clean up
    tfp->close();
    delete top;
    
    return (passed_count == test_suite.size()) ? 0 : 1;
}
