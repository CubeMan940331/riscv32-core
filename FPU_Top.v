module FPU_Top (
    input clk,
    input rst_n,

    // --- Control Signals ---
    input [6:0]  opcode,
    input [6:0]  func7,         // func7 code to select the function
    input [2:0]  func3,         // Rounding mode for arithmetic operations (if 111 swap to frm)
    input [2:0]  frm,           // Rounding mode (dynamic from frm)
    input [4:0]  rs2,           // For selecting convert type

    // --- Data Inputs ---
    input [31:0] operand_a,      // Operand A
    input [31:0] operand_b,      // Operand B
    input [31:0] operand_c,      // Operand C

    // --- Data Outputs ---
    output reg [31:0] result_out,     // Result of the operation

    // --- Status Flags ---
    output reg [4:0] fflags         // invalid, divbyzero, overflow, underflow, inexact
);

    // --- Opcode Definitions ---
    // opcode
    localparam OP_FMADD_S  = 7'b1000011;
    localparam OP_FMSUB_S  = 7'b1000111;
    localparam OP_FNMSUB_S = 7'b1001011;
    localparam OP_FNMADD_S = 7'b1001111;

    // func7
    localparam OP_FADD_S  = 7'b0000000; // FP32 Add
    localparam OP_FSUB_S  = 7'b0000100; // FP32 Subtract
    localparam OP_FMUL_S  = 7'b0001000; // FP32 Multiply
    localparam OP_FDIV_S  = 7'b0001100; // FP32 Divide
    localparam OP_FSQRT_S = 7'b0101100; // FP32 Square Root
    localparam OP_FCMP_S  = 7'b1010000; // FP32 Compare
    localparam OP_FMIN_FMAX_S  = 7'b0010100; // FP32 Min Max
    localparam OP_FCLASS_S  = 7'b1110000; // FP32 f.class
    localparam OP_FSGNJ_S  = 7'b0010000; // FP32 fsgnj.s fsgnjn.s fsgnjx.s

    localparam OP_FCVT_W_S  = 7'b1100000; // FP32 -> INT32 // UINT32 same
    localparam OP_FCVT_S_W  = 7'b1101000; // INT32 -> FP32 // UINT32 same


    // --- Internal Wires for connecting to sub-modules ---
    reg [31:0] sp_adder_result;
    reg sp_adder_invalid, sp_adder_overflow, sp_adder_underflow, sp_adder_inexact;

    reg sp_cmp, sp_cmp_invalid;

    reg [31:0] sp_convert_result;
    reg sp_convert_invalid, sp_convert_overflow, sp_convert_underflow, sp_convert_inexact;

    reg [31:0] sp_multiplier_result;
    reg sp_multiplier_invalid, sp_multiplier_overflow, sp_multiplier_underflow, sp_multiplier_inexact;

    reg [31:0] sp_divider_result;
    reg sp_divider_invalid, sp_divider_divbyzero, sp_divider_overflow, sp_divider_underflow, sp_divider_inexact;

    reg [31:0] sp_sqrt_result;
    reg sp_sqrt_invalid, sp_sqrt_inexact;

    reg [31:0] sp_min_max_result;
    reg sp_min_max_invalid;

    reg [31:0] sp_fused_result;
    reg sp_fused_invalid, sp_fused_overflow, sp_fused_underflow, sp_fused_inexact;

    reg [9:0]  sp_class_result;

    reg [31:0] sp_fsgnj_result;

    // --- Sub-module control signals ---
    reg [2:0]  rounding_mode;
    reg [1:0]  convert_input_type;
    reg [1:0]  convert_output_type;

    // --- Conversion Type Constants ---
    localparam FP32 = 2'b00, FP64 = 2'b01, INT32 = 2'b10, UINT32 = 2'b11;

    // --- Instantiate all functional units ---
    SP_Adder sp_adder_inst (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .is_subtraction(func7[2]),
        .rounding_mode(rounding_mode),
        .result(sp_adder_result),
        .flag_invalid(sp_adder_invalid), .flag_overflow(sp_adder_overflow),
        .flag_underflow(sp_adder_underflow), .flag_inexact(sp_adder_inexact)
    );

    SP_Compare sp_compare_inst (
        .operand_a(operand_a), .operand_b(operand_b),
        .func3(func3),
        .flag_cmp(sp_cmp), .flag_invalid(sp_cmp_invalid)
    );

    SP_Convert sp_convert_inst (
        .operand_in(operand_a), 
        .input_type(convert_input_type),
        .output_type(convert_output_type),
        .rounding_mode(rounding_mode),
        .result(sp_convert_result),
        .flag_invalid(sp_convert_invalid), .flag_overflow(sp_convert_overflow),
        .flag_underflow(sp_convert_underflow), .flag_inexact(sp_convert_inexact)
    );

    SP_Multiplier sp_multiplier_inst (
        .operand_a(operand_a), .operand_b(operand_b),
        .rounding_mode(rounding_mode),
        .result(sp_multiplier_result),
        .flag_invalid(sp_multiplier_invalid), .flag_overflow(sp_multiplier_overflow),
        .flag_underflow(sp_multiplier_underflow), .flag_inexact(sp_multiplier_inexact)
    );

    SP_Divider sp_divider_inst (
        .operand_a(operand_a), .operand_b(operand_b),
        .rounding_mode(rounding_mode),
        .result(sp_divider_result),
        .flag_invalid(sp_divider_invalid), .flag_divbyzero(sp_divider_divbyzero),
        .flag_overflow(sp_divider_overflow), .flag_underflow(sp_divider_underflow), .flag_inexact(sp_divider_inexact)
    );

    SP_Sqrt sp_sqrt_inst (
        .operand_a(operand_a),
        .rounding_mode(rounding_mode),
        .result(sp_sqrt_result),
        .flag_invalid(sp_sqrt_invalid), .flag_inexact(sp_sqrt_inexact)
    );

    SP_Min_Max sp_min_max_inst (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .func3(func3),
        .result(sp_min_max_result),
        .flag_invalid(sp_min_max_invalid)
    );

    SP_Fused sp_fused_inst (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .operand_c(operand_c),
        .is_subtraction(opcode[2]),
        .is_negative(opcode[3]),
        .rounding_mode(rounding_mode),
        .result(sp_fused_result),
        .flag_invalid(sp_fused_invalid), .flag_overflow(sp_fused_overflow),
        .flag_underflow(sp_fused_underflow), .flag_inexact(sp_fused_inexact)
    );

    SP_Classifier sp_class_inst (
        .fp_in(operand_a),
        .result(sp_class_result)
    );

    SP_Fsgnj sp_fsgnj_inst (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .func3(func3),
        .result(sp_fsgnj_result)
    );

    // --- Main Combinational Logic: Opcode Decoding and Output Muxing ---
    always @(*) begin
        // Default assignments to avoid latches
        result_out     = 0;
        fflags = 0;

        rounding_mode = (func3 == 3'b111) ? (func7 == OP_FSQRT_S) ? 3'b001 : frm : func3;
        convert_input_type = 0;
        convert_output_type = 0;

        // Decode opcode to select operation and drive outputs
        case (opcode)
            OP_FMADD_S, OP_FMSUB_S, OP_FNMSUB_S, OP_FNMADD_S: begin
                result_out = sp_fused_result;
                {fflags[4], fflags[2], fflags[1], fflags[0]} = {sp_fused_invalid, sp_fused_overflow, sp_fused_underflow, sp_fused_inexact};
            end
            default: begin
                case (func7)
                    OP_FADD_S, OP_FSUB_S: begin
                        result_out = sp_adder_result;
                        {fflags[4], fflags[2], fflags[1], fflags[0]} = {sp_adder_invalid, sp_adder_overflow, sp_adder_underflow, sp_adder_inexact};
                    end
                    OP_FCMP_S: begin
                        result_out = {31'b0, sp_cmp};
                        fflags[4] = sp_cmp_invalid;
                    end
                    OP_FCVT_W_S: begin
                        result_out = sp_convert_result;
                        {fflags[4], fflags[2], fflags[1], fflags[0]} = {sp_convert_invalid, sp_convert_overflow, sp_convert_underflow, sp_convert_inexact};
                        convert_input_type = FP32; convert_output_type = (rs2[0]) ? UINT32 : INT32;
                    end
                    OP_FCVT_S_W: begin
                        result_out = sp_convert_result;
                        {fflags[4], fflags[2], fflags[1], fflags[0]} = {sp_convert_invalid, sp_convert_overflow, sp_convert_underflow, sp_convert_inexact};
                        convert_input_type = (rs2[0]) ? UINT32 : INT32; convert_output_type = FP32;
                    end
                    OP_FMUL_S: begin
                        result_out = sp_multiplier_result;
                        {fflags[4], fflags[2], fflags[1], fflags[0]} = {sp_multiplier_invalid, sp_multiplier_overflow, sp_multiplier_underflow, sp_multiplier_inexact};
                    end
                    OP_FDIV_S: begin
                        result_out = sp_divider_result;
                        {fflags[4], fflags[3], fflags[2], fflags[1], fflags[0]} = {sp_divider_invalid, sp_divider_divbyzero, sp_divider_overflow, sp_divider_underflow, sp_divider_inexact};
                    end
                    OP_FSQRT_S: begin
                        result_out = sp_sqrt_result;
                        {fflags[4], fflags[0]} = {sp_sqrt_invalid, sp_sqrt_inexact};
                    end
                    OP_FMIN_FMAX_S: begin
                        result_out = sp_min_max_result;
                        fflags[4] = sp_min_max_invalid;
                    end
                    OP_FCLASS_S: begin
                        result_out = {22'b0, sp_class_result};
                    end
                    OP_FSGNJ_S: begin
                        result_out = sp_fsgnj_result;
                    end

                    default: begin
                        // Default to an invalid operation, return QNaN
                        result_out     = 32'h7FC0_0000; // Default QNaN
                        fflags[4]      = 1'b1;
                    end
                endcase
            end
        endcase
    end

endmodule
