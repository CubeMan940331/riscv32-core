module SP_Convert (
    input           clk,
    input           rst_n,
    input               start,
    input [31:0]        operand_in,
    input [1:0]         input_type,
    input [1:0]         output_type,
    input [2:0]         rounding_mode,
    output reg [31:0]   result,
    output reg          flag_invalid,
    output reg          flag_overflow,
    output reg          flag_underflow,
    output reg          flag_inexact,
    output              done
);
    // --- Type & Constant Definitions ---
    localparam FP_TYPE_FP32 = 2'b00, FP_TYPE_FP64 = 2'b01;
    localparam FP_TYPE_INT32 = 2'b10, FP_TYPE_UINT32 = 2'b11;
    localparam INT32_MAX_VAL = 64'h000000007FFFFFFF;
    localparam INT32_MIN_VAL = 64'h0000000080000000;
    localparam UINT32_MAX_VAL = 64'h00000000FFFFFFFF;
    localparam UINT32_MIN_VAL = 64'h0000000000000000;
    
    localparam RNE = 3'b000;
    localparam RTZ = 3'b001;
    localparam RDN = 3'b010;
    localparam RUP = 3'b011;
    localparam RMM = 3'b100;

    // operand a
    wire sign_a_dec;
    wire [7:0] exp_a_dec;
    wire [23:0] mant_a_dec;
    wire is_a_zero, is_a_infinity, is_a_nan, is_a_denormal;

    // result
    reg final_sign;
    reg [7:0] final_exp;
    reg [23:0] final_mant;

    wire [31:0] result_sp;
    reg [63:0] shifted_val;
    reg [63:0] result_int;
    
    // Decode / Encode
    SP_Decoder decoder_a ( .fp_in(operand_in), .sign_out(sign_a_dec), .exponent_out(exp_a_dec), .mantissa_out(mant_a_dec), .is_zero(is_a_zero), .is_infinity(is_a_infinity), .is_nan(is_a_nan), .is_denormal(is_a_denormal) );
    SP_Encoder encoder ( .sign_in(final_sign), .exponent_in(final_exp), .mantissa_in(final_mant), .fp_out(result_sp) );

    integer i;
    reg normal_path_enable;
    reg lsb, g_bit, r_bit, s_bit, round_up;
    integer shift_amt;

    always @(*) begin

        // init
        flag_invalid = 0; flag_overflow = 0; flag_underflow = 0; flag_inexact = 0;
        normal_path_enable = 1;

        final_sign=0; final_exp=0; final_mant=0;
        shifted_val = 0;
        result_int = 0;
        lsb = 0; g_bit = 0; r_bit = 0; s_bit = 0; round_up = 0;
        shift_amt = 0;

        // --- 1. Special Value Handling ---
        if (input_type == FP_TYPE_FP32) begin
            if (is_a_nan) begin

                normal_path_enable = 0;
                flag_invalid = 1; // NV
                if (output_type == FP_TYPE_INT32) begin result_int = INT32_MIN_VAL-1; end // int32 // don't know why it is 0x7fffffff, bc the default conversion of c++ output 0x80000000
                else if (output_type == FP_TYPE_UINT32) begin result_int = UINT32_MAX_VAL; end // uint32

            end else if (is_a_infinity) begin

                normal_path_enable = 0;
                if (output_type == FP_TYPE_INT32) begin flag_invalid = 1; flag_overflow = 1; result_int = (sign_a_dec) ? INT32_MIN_VAL : INT32_MAX_VAL; end // int32 (NV, OF)
                else if (output_type == FP_TYPE_UINT32) begin flag_invalid = 1; flag_overflow = !sign_a_dec; result_int = (sign_a_dec) ? UINT32_MIN_VAL : UINT32_MAX_VAL; end // uint32 (NV, OF(+))

            end else if (is_a_zero) begin

                normal_path_enable = 0;
                if (output_type == FP_TYPE_INT32 || output_type == FP_TYPE_UINT32) begin result_int = 0; end // 0

            end

        end else if (operand_in[31:0] == 0) begin

            normal_path_enable = 0;
            final_sign = 0; final_exp = 0; final_mant = 0; // 0

        end

        // --- 2. Normal Path ---
        if (normal_path_enable) begin
            // --- SP -> UINT Conversion ---
            if ((input_type == FP_TYPE_FP32) && (output_type == FP_TYPE_UINT32)) begin
                if (sign_a_dec) begin // negative
                    result_int = 0;
                    if (((rounding_mode == 3'b001) || (rounding_mode == 3'b011)) && (exp_a_dec < 127)) begin flag_inexact = 1; end
                    else begin flag_invalid = 1; end
                end else if (exp_a_dec < 127) begin // 0.xx
                    result_int = 0;
                    flag_inexact = |mant_a_dec[23:0];
                    if (flag_inexact && (rounding_mode == RUP)) begin
                        result_int = 64'd1;
                    end
                end else if (exp_a_dec > 158) begin // over 2^32
                    flag_invalid = 1;
                    flag_overflow = 1;
                    flag_inexact = 1;
                    result_int = UINT32_MAX_VAL;
                end else begin
                    shift_amt = 150 - {24'b0, exp_a_dec}; // 150 = 127 + 23
                    
                    if (shift_amt >= 0) begin
                        result_int = {40'b0, mant_a_dec} >> shift_amt;
                        shifted_val = {40'b0, mant_a_dec} << (24 - shift_amt);
                    end else begin
                        result_int = {40'b0, mant_a_dec} << -shift_amt;
                        shifted_val = {40'b0, mant_a_dec} >> (shift_amt - 24);
                    end

                    // rounding
                    lsb = result_int[0];
                    g_bit = shifted_val[23];
                    r_bit = shifted_val[22];
                    s_bit = |shifted_val[21:0];
                    flag_inexact = g_bit | r_bit | s_bit;
                    case (rounding_mode)
                        3'b000: round_up = g_bit & (lsb | r_bit | s_bit); // RNE
                        3'b001: round_up = 1'b0; // RTZ
                        3'b010: round_up = flag_inexact & sign_a_dec; // RDN
                        3'b011: round_up = flag_inexact & ~sign_a_dec; // RUP
                        3'b100: round_up = flag_inexact; //RMM
                        default: round_up = 1'b0;
                    endcase
                    result_int = result_int + {63'b0, round_up};

                    if (result_int[63:32] != 0) begin
                        flag_invalid=1; flag_inexact=1; result_int=UINT32_MAX_VAL;
                    end
                end
            end

            // --- SP -> integer Conversion ---
            else if ((input_type == FP_TYPE_FP32) && (output_type == FP_TYPE_INT32)) begin
                if (exp_a_dec < 127) begin // 0.xx
                    result_int = 0;
                    flag_inexact = |mant_a_dec[23:0];
                    if (flag_inexact) begin
                        if (!sign_a_dec && (rounding_mode == RUP)) begin result_int = 64'd1; end // 1
                        else if (sign_a_dec && (rounding_mode == RDN)) begin result_int = {32'b0, -$signed(32'd1)}; end // -1
                    end
                end else if (exp_a_dec >= 158) begin
                    if (sign_a_dec && (exp_a_dec == 158) && (mant_a_dec == {1'b1, 23'b0})) begin result_int = INT32_MIN_VAL; end
                    else begin
                        flag_invalid = 1;
                        result_int = (sign_a_dec) ? INT32_MIN_VAL : INT32_MAX_VAL;
                    end
                end else begin
                    shift_amt = 150 - {24'b0, exp_a_dec}; // 150 = 127 + 23
                    
                    if (shift_amt >= 0) begin
                        result_int = {40'b0, mant_a_dec} >> shift_amt;
                        shifted_val = {40'b0, mant_a_dec} << (24 - shift_amt);
                    end else begin
                        result_int = {40'b0, mant_a_dec} << -shift_amt;
                        shifted_val = {40'b0, mant_a_dec} >> (shift_amt - 24);
                    end

                    // rounding
                    lsb = result_int[0];
                    g_bit = shifted_val[23];
                    r_bit = shifted_val[22];
                    s_bit = |shifted_val[21:0];
                    flag_inexact = g_bit | r_bit | s_bit;
                    case (rounding_mode)
                        3'b000: round_up = g_bit & (lsb | r_bit | s_bit); // RNE
                        3'b001: round_up = 1'b0; // RTZ
                        3'b010: round_up = flag_inexact & sign_a_dec; // RDN
                        3'b011: round_up = flag_inexact & ~sign_a_dec; // RUP
                        3'b100: round_up = flag_inexact; //RMM
                        default: round_up = 1'b0;
                    endcase
                    result_int = result_int + {63'b0, round_up};

                    if (result_int[31:0] == {1'b1, 31'b0}) begin
                        if (sign_a_dec) begin result_int = INT32_MIN_VAL; end
                        else begin flag_invalid=1; flag_inexact=1; result_int=(sign_a_dec) ? INT32_MIN_VAL : INT32_MAX_VAL; end
                    end

                    if(sign_a_dec) begin result_int = {32'b0, -$signed(result_int[31:0])}; end
                end
            end

            // --- integer -> SP Conversion ---
            else begin
                final_sign = (input_type == FP_TYPE_INT32) & operand_in[31];
                final_exp = 8'd158; // 2^31
                result_int = (final_sign) ? {1'b0, -operand_in[31:0], 31'b0} : {1'b0, operand_in[31:0], 31'b0};

                for(i = 0 ; i < 32 ; i = i + 1) begin
                    if (!result_int[62]) begin final_exp = final_exp - 1; result_int = result_int << 1; end
                end

                lsb = result_int[39];
                g_bit = result_int[38];
                r_bit = result_int[37];
                s_bit = result_int[36];
                flag_inexact = g_bit | r_bit | s_bit;
                case (rounding_mode)
                    3'b000: round_up = g_bit & (lsb | r_bit | s_bit); // RNE
                    3'b001: round_up = 1'b0; // RTZ
                    3'b010: round_up = flag_inexact & sign_a_dec; // RDN
                    3'b011: round_up = flag_inexact & ~sign_a_dec; // RUP
                    3'b100: round_up = flag_inexact; //RMM
                    default: round_up = 1'b0;
                endcase
                if (round_up) begin result_int = result_int + {24'b0, 1'b1, 39'b0}; end
                if (result_int[63]) begin final_exp = final_exp + 1; result_int = result_int >> 1; end

                final_mant = result_int[62:39];
            end
        end
    end

    always @(*) begin
        // --- 3. Final Result Muxing ---
        result = (output_type == FP_TYPE_FP32) ? result_sp : result_int[31:0];
    end

    assign done = start;
endmodule
