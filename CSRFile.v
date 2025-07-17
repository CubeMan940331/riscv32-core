module CSRFile (
    input         clk,
    input         rst_n,

    // Zicsr access
    input  [11:0] csr_addr_i,
    input  [31:0] csr_wdata_i,
    input         csr_we_i,
    output reg [31:0] csr_rdata_o,

    // Trap / return
    input         trap_taken_i,     // assert 1‑cycle when trap is taken
    input  [31:0] trap_pc_i,        // PC that caused trap
    input  [31:0] mcause_i,         // trap cause
    input         mret_i,           // 1‑cycle pulse on MRET

    output [31:0] csr_pc_redirect_o,// next PC (mtvec or mepc)
    output [1:0]  cur_priv_o        // 00 = U, 11 = M  (debug / external use)
);
localparam PRIV_U = 2'b00;
localparam PRIV_M = 2'b11;

///////////////////////////////////////////////////////////////////////////////
// Registers
///////////////////////////////////////////////////////////////////////////////
reg [31:0] mstatus, mie, mtvec, mscratch, mepc, mcause, mtval;
reg [31:0] utvec,  uscratch, uepc,  ucause,  utval;
reg        uie;            // bit‑0 only
reg [1:0]  priv_reg;       // current privilege

assign cur_priv_o = priv_reg;

///////////////////////////////////////////////////////////////////////////////
// Helpers to pick out mstatus fields we actually touch
///////////////////////////////////////////////////////////////////////////////
wire MIE  = mstatus[3];
wire MPIE = mstatus[7];
wire [1:0] MPP = mstatus[12:11];

///////////////////////////////////////////////////////////////////////////////
// Main sequential block
///////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mstatus <= 0; mie <= 0; mtvec <= 0; mscratch <= 0;
        mepc <= 0; mcause <= 0; mtval <= 0;
        utvec <= 0; uscratch <= 0; uepc <= 0; ucause <= 0; utval <= 0;
        uie <= 1'b0;
        priv_reg <= PRIV_M;        // start in Machine mode
    end else begin
        //----------------------------------------------------------------------
        // Trap into Machine mode
        //----------------------------------------------------------------------
        if (trap_taken_i) begin
            mepc   <= trap_pc_i;
            mcause <= mcause_i;
            mstatus[7]     <= MIE;      // MPIE ← MIE
            mstatus[3]     <= 1'b0;     // MIE  ← 0
            mstatus[12:11] <= priv_reg; // MPP  ← previous mode
            priv_reg       <= PRIV_M;   // now in Machine mode
        end
        //----------------------------------------------------------------------
        // Return from Machine trap
        //----------------------------------------------------------------------
        else if (mret_i) begin
            priv_reg       <= MPP;      // back to previous mode (U or M)
            mstatus[3]     <= MPIE;     // MIE  ← MPIE
            mstatus[7]     <= 1'b1;     // MPIE ← 1
            mstatus[12:11] <= 2'b00;    // MPP  ← 0
        end
        //----------------------------------------------------------------------
        // Explicit CSR write (from CSRRW/RS/RC…)
        //----------------------------------------------------------------------
        else if (csr_we_i) begin
            case (csr_addr_i)
                // ---------- Machine CSRs ----------
                12'h300: mstatus  <= csr_wdata_i;
                12'h304: mie      <= csr_wdata_i;
                12'h305: mtvec    <= csr_wdata_i;
                12'h340: mscratch <= csr_wdata_i;
                12'h341: mepc     <= csr_wdata_i;
                12'h342: mcause   <= csr_wdata_i;
                12'h343: mtval    <= csr_wdata_i;

                // ---------- User CSRs -------------
                12'h005: utvec    <= csr_wdata_i;
                12'h040: uscratch <= csr_wdata_i;
                12'h041: uepc     <= csr_wdata_i;
                12'h042: ucause   <= csr_wdata_i;
                12'h043: utval    <= csr_wdata_i;

                // ustatus – we only model UIE/UPIE bits (0,4)
                12'h000: begin
                    mstatus[0] <= csr_wdata_i[0];  // UIE
                    mstatus[4] <= csr_wdata_i[4];  // UPIE
                end
                12'h004: uie     <= csr_wdata_i[0]; // lowest bit only
                default: ;
            endcase
        end
    end
end

///////////////////////////////////////////////////////////////////////////////
// Combinational CSR read
///////////////////////////////////////////////////////////////////////////////
always @(*) begin
    case (csr_addr_i)
        // Machine CSRs
        12'h300: csr_rdata_o = mstatus;
        12'h304: csr_rdata_o = mie;
        12'h305: csr_rdata_o = mtvec;
        12'h340: csr_rdata_o = mscratch;
        12'h341: csr_rdata_o = mepc;
        12'h342: csr_rdata_o = mcause;
        12'h343: csr_rdata_o = mtval;

        // User CSRs
        12'h000: csr_rdata_o = {27'b0, mstatus[4], 3'b0, mstatus[0]}; // ustatus
        12'h004: csr_rdata_o = {31'b0, uie};                          // uie
        12'h005: csr_rdata_o = utvec;
        12'h040: csr_rdata_o = uscratch;
        12'h041: csr_rdata_o = uepc;
        12'h042: csr_rdata_o = ucause;
        12'h043: csr_rdata_o = utval;
        default: csr_rdata_o = 32'h0;
    endcase
end

///////////////////////////////////////////////////////////////////////////////
// PC redirect (combinational)
//   • Trap  → mtvec
//   • MRET  → mepc
///////////////////////////////////////////////////////////////////////////////
assign csr_pc_redirect_o = trap_taken_i ? mtvec :
                           (mret_i ? mepc : 32'h0);

endmodule