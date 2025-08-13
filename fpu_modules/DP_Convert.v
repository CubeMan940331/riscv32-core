module DP_Convert (
    input [63:0]    operand_in,
    input [1:0]     input_type,
    input [1:0]     output_type,
    input [2:0]     rounding_mode,
    output reg [31:0]   result,
    output reg      flag_invalid,
    output reg      flag_overflow,
    output reg      flag_underflow,
    output reg      flag_inexact
);
    // --- Type & Constant Definitions ---
    localparam FP_TYPE_FP32 = 2'b00, FP_TYPE_FP64 = 2'b01;
    localparam FP_TYPE_INT32 = 2'b10, FP_TYPE_UINT32 = 2'b11;
    localparam FP64_QNAN_MANT = {1'b1, 52'h80000_00000000};
    localparam FP32_QNAN_MANT = {2'b1, 22'b0};
    localparam INT32_MAX_VAL = 32'h7FFFFFFF;
    localparam INT32_MIN_VAL = 32'h80000000;
    localparam UINT32_MAX_VAL = 32'hFFFFFFFF;
    localparam UINT32_MIN_VAL = 32'h00000000;
    
    localparam RNE = 3'b000;
    localparam RTZ = 3'b001;
    localparam RDN = 3'b010;
    localparam RUP = 3'b011;
    localparam RMM = 3'b100;

    // operand a
    reg sign_a_dec;
    reg [10:0] exp_a_dec;
    reg [52:0] mant_a_dec;
    reg is_a_zero, is_a_infinity, is_a_nan, is_a_denormal;

    // result
    reg final_sign;
    reg [7:0] final_exp;
    reg [23:0] final_mant;

    reg [31:0] result_sp;
    reg [63:0] result_int;
    reg [31:0] result_int_32;
    
    // Decode / Encode
    DP_Decoder decoder_a ( .fp_in(operand_in), .sign_out(sign_a_dec), .exponent_out(exp_a_dec), .mantissa_out(mant_a_dec), .is_zero(is_a_zero), .is_infinity(is_a_infinity), .is_nan(is_a_nan), .is_denormal(is_a_denormal) );
    SP_Encoder encoder ( .sign_in(final_sign), .exponent_in(final_exp), .mantissa_in(final_mant), .fp_out(result_sp) );

    reg normal_path_enable;
    reg [10:0] exp_a_sp;
    reg [52:0] mant_a_sp;
    reg [63:0] shifted_val;
    reg lsb, g_bit, r_bit, s_bit, round_up;
    int shift_amt;

    always @(*) begin

        // init
        flag_invalid = 0; flag_overflow = 0; flag_underflow = 0; flag_inexact = 0;
        normal_path_enable = 1;

        final_sign=0; final_exp='0; final_mant='0;
        exp_a_sp = '0; mant_a_sp = '0;
        shifted_val = '0;
        result_int = '0;
        result_int_32 = '0;
        lsb = 0; g_bit = 0; r_bit = 0; s_bit = 0; round_up = 0;
        shift_amt = 0;

        // --- 1. Special Value Handling ---
        if (input_type == FP_TYPE_FP64) begin
            if (is_a_nan) begin

                normal_path_enable = 0;
                flag_invalid = 1; // NV
                if (output_type == FP_TYPE_INT32) begin result_int_32 = INT32_MIN_VAL; end // int32
                else if (output_type == FP_TYPE_UINT32) begin result_int_32 = UINT32_MAX_VAL; end // uint32
                else begin final_sign = 0; final_exp = '1; final_mant = FP32_QNAN_MANT; end // float (NaN)

            end else if (is_a_infinity) begin

                normal_path_enable = 0;
                if (output_type == FP_TYPE_INT32) begin flag_invalid = 1; flag_overflow = 1; result_int_32 = (sign_a_dec) ? INT32_MIN_VAL : INT32_MAX_VAL; end // int32 (NV, OF)
                else if (output_type == FP_TYPE_UINT32) begin flag_invalid = 1; flag_overflow = !sign_a_dec; result_int_32 = (sign_a_dec) ? UINT32_MIN_VAL : UINT32_MAX_VAL; end // uint32 (NV, OF(+))
                else begin final_sign = sign_a_dec; final_exp = '1; final_mant = '0; end // float (inf)

            end else if (is_a_zero) begin

                normal_path_enable = 0;
                if (output_type == FP_TYPE_INT32 || output_type == FP_TYPE_UINT32) begin result_int_32 = '0; end // 0
                else begin final_sign = sign_a_dec; final_exp = '0; final_mant = '0; end // 0

            end

        end else if (operand_in[31:0] == 0) begin

            normal_path_enable = 0;
            final_sign = 0; final_exp = '0; final_mant = '0; // 0

        end

        // --- 2. Normal Path ---
        if (normal_path_enable) begin
            // --- DP -> SP Conversion ---
            if ((input_type == FP_TYPE_FP64) && (output_type == FP_TYPE_FP32)) begin
                // sign
                final_sign = sign_a_dec;
                
                // exponent / mantissa
                if (exp_a_dec <= 896 && exp_a_dec >= 874) begin
                    final_exp = '0;
                    mant_a_sp = mant_a_dec;
                    for (int i = 897; i > exp_a_dec ; i--) begin
                        mant_a_sp >>= 1;
                    end
                    final_mant = mant_a_sp[52:29];
                    flag_inexact = |mant_a_sp[28:0];
                    flag_underflow = (final_mant == 0);
                end
                else if (exp_a_dec == 1150) begin// (2^127)
                    if((mant_a_dec[52:29] == {24{1'b1}}) && (mant_a_dec[28:0] != 0)) begin flag_invalid = 1; flag_overflow = 1; final_exp = '1; final_mant = '0; end // Inf
                    else begin final_exp = 8'd254; final_mant = mant_a_dec[52:29]; end
                end
                else if (exp_a_dec > 1150) begin
                    flag_invalid = 1; flag_overflow = 1;
                    final_exp = '1; final_mant = '0; // Inf
                end
                else begin // in float range
                    exp_a_sp = exp_a_dec - 11'd896;
                    final_exp = exp_a_sp[7:0];
                    
                    mant_a_sp = mant_a_dec >> 1;
                    lsb = mant_a_sp[28];
                    g_bit = mant_a_sp[27];
                    r_bit = mant_a_sp[26];
                    s_bit = mant_a_sp[25];
                    flag_inexact = g_bit | r_bit | s_bit;
                    case (rounding_mode)
                        3'b000: round_up = g_bit & (lsb | r_bit | s_bit); // RNE
                        3'b001: round_up = 1'b0; // RTZ
                        3'b010: round_up = flag_inexact & sign_a_dec; // RDN
                        3'b011: round_up = flag_inexact & ~sign_a_dec; // RUP
                        3'b100: round_up = flag_inexact; //RMM
                        default: round_up = 1'b0;
                    endcase
                    if(round_up) begin mant_a_sp += {25'b0, 1'b1, 27'b0}; end
                    if(mant_a_sp[52]) begin final_exp += 1; mant_a_sp >>= 1; end

                    final_mant = mant_a_sp[51:28];
                end
            end

            // --- DP -> UINT Conversion ---
            else if ((input_type == FP_TYPE_FP64) && (output_type == FP_TYPE_UINT32)) begin
                if (sign_a_dec) begin // negative
                    result_int_32 = '0;
                    flag_invalid = 1;
                end else if (exp_a_dec < 1023) begin // 0.xx
                    result_int_32 = '0;
                    flag_inexact = |mant_a_dec[52:0];
                    if (flag_inexact && (rounding_mode == RUP)) begin
                        result_int_32 = 32'd1;
                    end
                end else if (exp_a_dec > 1054) begin // over 2^32
                    flag_invalid = 1;
                    flag_overflow = 1;
                    flag_inexact = 1;
                    result_int_32 = UINT32_MAX_VAL;
                end else begin
                    shift_amt = 1075 - {21'b0, exp_a_dec}; // 1075 = 1023 + 52
                    
                    if (shift_amt >= 0) begin
                        result_int = {11'b0, mant_a_dec} >> shift_amt;
                        shifted_val = {11'b0, mant_a_dec} << (53 - shift_amt);
                    end else begin
                        result_int = {11'b0, mant_a_dec} << -shift_amt;
                        shifted_val = {11'b0, mant_a_dec} >> (shift_amt - 53);
                    end

                    // rounding
                    lsb = result_int[0];
                    g_bit = shifted_val[52];
                    r_bit = shifted_val[51];
                    s_bit = |shifted_val[50:0];
                    flag_inexact = g_bit | r_bit | s_bit;
                    case (rounding_mode)
                        3'b000: round_up = g_bit & (lsb | r_bit | s_bit); // RNE
                        3'b001: round_up = 1'b0; // RTZ
                        3'b010: round_up = flag_inexact & sign_a_dec; // RDN
                        3'b011: round_up = flag_inexact & ~sign_a_dec; // RUP
                        3'b100: round_up = flag_inexact; //RMM
                        default: round_up = 1'b0;
                    endcase
                    result_int += {63'b0, round_up};
                    result_int_32 = result_int[31:0];

                    if (result_int[63:32] != 0) begin
                        flag_invalid=1; flag_inexact=1; result_int_32=UINT32_MAX_VAL;
                    end
                end
            end

            // --- DP -> INT Conversion ---
            else if ((input_type == FP_TYPE_FP64) && (output_type == FP_TYPE_INT32)) begin
                if (exp_a_dec < 1023) begin // 0.xx
                    result_int_32 = '0;
                    flag_inexact = |mant_a_dec[52:0];
                    if (flag_inexact) begin
                        if (!sign_a_dec && (rounding_mode == RUP)) begin result_int_32 = 32'd1; end // 1
                        else if (sign_a_dec && (rounding_mode == RDN)) begin result_int_32 = -$signed(32'd1); end // -1
                    end
                end else if (exp_a_dec >= 1054) begin
                    if (sign_a_dec && (exp_a_dec == 1054) && (mant_a_dec == {1'b1, 52'b0})) begin result_int_32 = INT32_MIN_VAL; end
                    else begin
                        flag_invalid = 1;
                        flag_overflow = 1;
                        flag_inexact = 1;
                        result_int_32 = (sign_a_dec) ? INT32_MIN_VAL : INT32_MAX_VAL;
                    end
                end else begin
                    shift_amt = 1075 - {21'b0, exp_a_dec}; // 1075 = 1023 + 52
                    
                    if (shift_amt >= 0) begin
                        result_int = {11'b0, mant_a_dec} >> shift_amt;
                        shifted_val = {11'b0, mant_a_dec} << (53 - shift_amt);
                    end else begin
                        result_int = {11'b0, mant_a_dec} << -shift_amt;
                        shifted_val = {11'b0, mant_a_dec} >> (shift_amt - 53);
                    end

                    // rounding
                    lsb = result_int[0];
                    g_bit = shifted_val[52];
                    r_bit = shifted_val[51];
                    s_bit = |shifted_val[50:0];
                    flag_inexact = g_bit | r_bit | s_bit;
                    case (rounding_mode)
                        3'b000: round_up = g_bit & (lsb | r_bit | s_bit); // RNE
                        3'b001: round_up = 1'b0; // RTZ
                        3'b010: round_up = flag_inexact & sign_a_dec; // RDN
                        3'b011: round_up = flag_inexact & ~sign_a_dec; // RUP
                        3'b100: round_up = flag_inexact; //RMM
                        default: round_up = 1'b0;
                    endcase
                    result_int += {63'b0, round_up};

                    if (result_int[31:0] == {1'b1, 31'b0}) begin
                        if (sign_a_dec) begin result_int_32 = INT32_MIN_VAL; end
                        else begin flag_invalid=1; flag_inexact=1; result_int_32=(sign_a_dec) ? INT32_MIN_VAL : INT32_MAX_VAL; end
                    end

                    result_int_32 = (sign_a_dec) ? -$signed(result_int[31:0]) : result_int[31:0];
                end
            end

            // --- INT -> DP Conversion ---
            else begin
                final_sign = (input_type == FP_TYPE_INT32) && operand_in[31];
                final_exp = 8'd158; // 2^31
                result_int = (final_sign) ? {1'b0, -operand_in[31:0], 31'b0} : {1'b0, operand_in[31:0], 31'b0};

                for(int i = 31 ; i >= 0 ; i--) begin
                    if (!result_int[62]) begin final_exp -= 1; result_int <<= 1; end
                    else begin i = 0; end
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
                if (round_up) begin result_int += {24'b0, 1'b1, 39'b0}; end
                if (result_int[63]) begin final_exp += 1; result_int >>= 1; end

                final_mant = result_int[62:39];
            end
        end
    end

    always @(*) begin
        // --- 3. Final Result Muxing ---
        result = (output_type == FP_TYPE_FP32) ? result_sp : result_int_32;
    end
endmodule
