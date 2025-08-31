module FPU_top (
    input clk,
    input rst_n,
    input FPU_start,

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
    output reg [4:0] fflags,         // invalid, divbyzero, overflow, underflow, inexact

    // --- Done ---
    output FPU_done
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
    wire sp_adder_enable = enable & enable_mask[0];
    wire [31:0] sp_adder_result;
    wire sp_adder_invalid, sp_adder_overflow, sp_adder_underflow, sp_adder_inexact;
    wire sp_adder_done;

    wire sp_cmp_enable = enable & enable_mask[1];
    wire sp_cmp, sp_cmp_invalid;
    wire sp_cmp_done;

    wire sp_convert_enable = enable & enable_mask[2];
    wire [31:0] sp_convert_result;
    wire sp_convert_invalid, sp_convert_overflow, sp_convert_underflow, sp_convert_inexact;
    wire sp_convert_done;

    wire sp_multiplier_enable = enable & enable_mask[3];
    wire [31:0] sp_multiplier_result;
    wire sp_multiplier_invalid, sp_multiplier_overflow, sp_multiplier_underflow, sp_multiplier_inexact;
    wire sp_multiplier_done;

    wire sp_divider_enable = enable & enable_mask[4];
    wire [31:0] sp_divider_result;
    wire sp_divider_invalid, sp_divider_divbyzero, sp_divider_overflow, sp_divider_underflow, sp_divider_inexact;
    wire sp_divider_done;

    wire sp_sqrt_enable = enable & enable_mask[5];
    wire [31:0] sp_sqrt_result;
    wire sp_sqrt_invalid, sp_sqrt_inexact;
    wire sp_sqrt_done;

    wire sp_min_max_enable = enable & enable_mask[6];
    wire [31:0] sp_min_max_result;
    wire sp_min_max_invalid;
    wire sp_min_max_done;

    wire sp_fused_enable = enable & enable_mask[7];
    wire [31:0] sp_fused_result;
    wire sp_fused_invalid, sp_fused_overflow, sp_fused_underflow, sp_fused_inexact;
    wire sp_fused_done;

    wire sp_class_enable = enable & enable_mask[8];
    wire [9:0]  sp_class_result;
    wire sp_class_done;

    wire sp_fsgnj_enable = enable & enable_mask[9];
    wire [31:0] sp_fsgnj_result;
    wire sp_fsgnj_done;

    // --- Sub-module control signals ---
    reg enable;
    reg [9:0]  enable_mask;
    reg [2:0]  rounding_mode;
    reg [1:0]  convert_input_type;
    reg [1:0]  convert_output_type;

    // --- Conversion Type Constants ---
    localparam FP32 = 2'b00, FP64 = 2'b01, INT32 = 2'b10, UINT32 = 2'b11;

    // --- Instantiate all functional units ---
    SP_Adder sp_adder_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(sp_adder_enable),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .is_subtraction(func7[2]),
        .rounding_mode(rounding_mode),
        .result(sp_adder_result),
        .flag_invalid(sp_adder_invalid), .flag_overflow(sp_adder_overflow), .flag_underflow(sp_adder_underflow), .flag_inexact(sp_adder_inexact),
        .done(sp_adder_done)
    );

    SP_Compare sp_compare_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(sp_cmp_enable),
        .operand_a(operand_a), .operand_b(operand_b),
        .func3(func3),
        .flag_cmp(sp_cmp), .flag_invalid(sp_cmp_invalid),
        .done(sp_cmp_done)
    );

    SP_Convert sp_convert_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(sp_convert_enable),
        .operand_in(operand_a), 
        .input_type(convert_input_type),
        .output_type(convert_output_type),
        .rounding_mode(rounding_mode),
        .result(sp_convert_result),
        .flag_invalid(sp_convert_invalid), .flag_overflow(sp_convert_overflow), .flag_underflow(sp_convert_underflow), .flag_inexact(sp_convert_inexact),
        .done(sp_convert_done)
    );

    SP_Multiplier sp_multiplier_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(sp_multiplier_enable),
        .operand_a(operand_a), .operand_b(operand_b),
        .rounding_mode(rounding_mode),
        .result(sp_multiplier_result),
        .flag_invalid(sp_multiplier_invalid), .flag_overflow(sp_multiplier_overflow), .flag_underflow(sp_multiplier_underflow), .flag_inexact(sp_multiplier_inexact),
        .done(sp_multiplier_done)
    );

    SP_Divider sp_divider_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(sp_divider_enable),
        .operand_a(operand_a), .operand_b(operand_b),
        .rounding_mode(rounding_mode),
        .result(sp_divider_result),
        .flag_invalid(sp_divider_invalid), .flag_divbyzero(sp_divider_divbyzero), .flag_overflow(sp_divider_overflow), .flag_underflow(sp_divider_underflow), .flag_inexact(sp_divider_inexact),
        .done(sp_divider_done)
    );

    SP_Sqrt sp_sqrt_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(sp_sqrt_enable),
        .operand_a(operand_a),
        .rounding_mode(rounding_mode),
        .result(sp_sqrt_result),
        .flag_invalid(sp_sqrt_invalid), .flag_inexact(sp_sqrt_inexact),
        .done(sp_sqrt_done)
    );

    SP_Min_Max sp_min_max_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(sp_min_max_enable),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .func3(func3),
        .result(sp_min_max_result),
        .flag_invalid(sp_min_max_invalid),
        .done(sp_min_max_done)
    );

    SP_Fused sp_fused_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(sp_fused_enable),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .operand_c(operand_c),
        .is_subtraction(opcode[2]),
        .is_negative(opcode[3]),
        .rounding_mode(rounding_mode),
        .result(sp_fused_result),
        .flag_invalid(sp_fused_invalid), .flag_overflow(sp_fused_overflow), .flag_underflow(sp_fused_underflow), .flag_inexact(sp_fused_inexact),
        .done(sp_fused_done)
    );

    SP_Classifier sp_class_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(sp_class_enable),
        .fp_in(operand_a),
        .result(sp_class_result),
        .done(sp_class_done)
    );

    SP_Fsgnj sp_fsgnj_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(sp_fsgnj_enable),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .func3(func3),
        .result(sp_fsgnj_result),
        .done(sp_fsgnj_done)
    );

    // Done
    assign FPU_done = sp_adder_done | sp_cmp_done | sp_convert_done | sp_multiplier_done | sp_divider_done | sp_sqrt_done | sp_min_max_done | sp_fused_done | sp_class_done | sp_fsgnj_done;

    // --- Main Combinational Logic: Opcode Decoding and Output Muxing ---
    always @(*) begin
        // Default assignments to avoid latches
        result_out     = 0;
        fflags = 0;

        rounding_mode = (func3 == 3'b111) ? (func7 == OP_FSQRT_S) ? 3'b001 : frm : func3;
        convert_input_type = 0;
        convert_output_type = 0;

        enable = FPU_start;
        enable_mask = 0;

        // Decode opcode to select operation and drive outputs
        case (opcode)
            OP_FMADD_S, OP_FMSUB_S, OP_FNMSUB_S, OP_FNMADD_S: begin
                enable_mask = 10'b0010000000;
                result_out = sp_fused_result;
                {fflags[4], fflags[2], fflags[1], fflags[0]} = {sp_fused_invalid, sp_fused_overflow, sp_fused_underflow, sp_fused_inexact};
            end
            default: begin
                case (func7)
                    OP_FADD_S, OP_FSUB_S: begin
                        enable_mask = 10'b0000000001;
                        result_out = sp_adder_result;
                        {fflags[4], fflags[2], fflags[1], fflags[0]} = {sp_adder_invalid, sp_adder_overflow, sp_adder_underflow, sp_adder_inexact};
                    end
                    OP_FCMP_S: begin
                        enable_mask = 10'b0000000010;
                        result_out = {31'b0, sp_cmp};
                        fflags[4] = sp_cmp_invalid;
                    end
                    OP_FCVT_W_S: begin
                        enable_mask = 10'b0000000100;
                        result_out = sp_convert_result;
                        {fflags[4], fflags[2], fflags[1], fflags[0]} = {sp_convert_invalid, sp_convert_overflow, sp_convert_underflow, sp_convert_inexact};
                        convert_input_type = FP32; convert_output_type = (rs2[0]) ? UINT32 : INT32;
                    end
                    OP_FCVT_S_W: begin
                        enable_mask = 10'b0000000100;
                        result_out = sp_convert_result;
                        {fflags[4], fflags[2], fflags[1], fflags[0]} = {sp_convert_invalid, sp_convert_overflow, sp_convert_underflow, sp_convert_inexact};
                        convert_input_type = (rs2[0]) ? UINT32 : INT32; convert_output_type = FP32;
                    end
                    OP_FMUL_S: begin
                        enable_mask = 10'b0000001000;
                        result_out = sp_multiplier_result;
                        {fflags[4], fflags[2], fflags[1], fflags[0]} = {sp_multiplier_invalid, sp_multiplier_overflow, sp_multiplier_underflow, sp_multiplier_inexact};
                    end
                    OP_FDIV_S: begin
                        enable_mask = 10'b0000010000;
                        result_out = sp_divider_result;
                        {fflags[4], fflags[3], fflags[2], fflags[1], fflags[0]} = {sp_divider_invalid, sp_divider_divbyzero, sp_divider_overflow, sp_divider_underflow, sp_divider_inexact};
                    end
                    OP_FSQRT_S: begin
                        enable_mask = 10'b0000100000;
                        result_out = sp_sqrt_result;
                        {fflags[4], fflags[0]} = {sp_sqrt_invalid, sp_sqrt_inexact};
                    end
                    OP_FMIN_FMAX_S: begin
                        enable_mask = 10'b0001000000;
                        result_out = sp_min_max_result;
                        fflags[4] = sp_min_max_invalid;
                    end
                    OP_FCLASS_S: begin
                        enable_mask = 10'b0100000000;
                        result_out = {22'b0, sp_class_result};
                    end
                    OP_FSGNJ_S: begin
                        enable_mask = 10'b1000000000;
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
