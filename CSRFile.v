//-----------------------------------------------------------------
//                         RISC-V Core
//                            V1.0.1
//                     Ultra-Embedded.com
//                     Copyright 2014-2019
//
//                   admin@ultra-embedded.com
//
//                       License: BSD
//-----------------------------------------------------------------
//
// Copyright (c) 2014-2019, Ultra-Embedded.com
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions 
// are met:
//   - Redistributions of source code must retain the above copyright
//     notice, this list of conditions and the following disclaimer.
//   - Redistributions in binary form must reproduce the above copyright
//     notice, this list of conditions and the following disclaimer 
//     in the documentation and/or other materials provided with the 
//     distribution.
//   - Neither the name of the author nor the names of its contributors 
//     may be used to endorse or promote products derived from this 
//     software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR 
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE 
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
// THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
// SUCH DAMAGE.
//-----------------------------------------------------------------
/* verilator lint_off UNUSEDSIGNAL */
`include "riscv_defs.v"

module CSRFile (
     input clk
    ,input rst_n
    
    ,input  [31:0]  cpu_id_i
    ,input  [31:0]  misa_i

    ,input  [5:0]   exception_i
    ,input  [31:0]  exception_pc_i
    ,input  [31:0]  exception_addr_i

    ,input  [11:0]  csr_rd_addr_i
    ,output [31:0]  csr_rd_data_o
    
    ,input          csr_wr_en_i
    ,input  [11:0]  csr_wr_addr_i
    ,input  [31:0]  csr_wr_data_i

    ,output         csr_branch_o
    ,output [31:0]  csr_target_o

    // CSR registers
    ,output [1:0]   priv_o
    ,output [31:0]  mstatus_o
    // ,output [31:0]  satp_o

    ,output [31:0]  interrupt_o
);

// utilities
reg [1:0]   csr_priv_r;
reg [1:0]   csr_priv_q;
// reg [31:0]  csr_satp_r;
// reg [31:0]  csr_satp_q;

// CSR - Machine

// Information RO
reg [31:0] csr_mvendorid_q;
reg [31:0] csr_marchid_q;
reg [31:0] csr_mimpid_q;
reg [31:0] csr_mhartid_q;
reg [31:0] csr_mconfigptr_q;

// Trap Setup
reg [31:0] csr_mstatus_q;
reg [31:0] csr_medeleg_q;
reg [31:0] csr_mideleg_q;
reg [31:0] csr_mie_q;
reg [31:0] csr_mtvec_q;
reg [31:0] csr_mcounteren_q;
reg [31:0] csr_mstatush_q;
reg [31:0] csr_medelegh_q;

// Trap Handling
reg [31:0] csr_mscratch_q;
reg [31:0] csr_mepc_q;
reg [31:0] csr_mcause_q;
reg [31:0] csr_mtval_q;
reg [31:0] csr_mip_q;
reg [31:0] csr_mtinst_q;
reg [31:0] csr_mtval2_q;

// Configuration
reg [31:0] csr_menvcfg_q;
reg [31:0] csr_menvcfgh_q;
reg [31:0] csr_mseccfg_q;
reg [31:0] csr_mseccfgh_q;

// Memory Protection
reg [31:0] csr_pmpcfg_q     [0:15];
reg [31:0] csr_pmpaddr_q    [0:63];

// State Enable Registers
reg [31:0] csr_mstateen_q     [0:3];
reg [31:0] csr_mstateenh_q    [0:3];

// Non-Maskable Interrupt Handling
reg [31:0] csr_mnscratch_q;
reg [31:0] csr_mnepc_q;
reg [31:0] csr_mncause_q;
reg [31:0] csr_mnstatus_q;

// Counter/Timers
reg [31:0] csr_mcycle_q;
reg [31:0] csr_minstret_q;
reg [31:0] csr_mhpmcounter_q  [3:31];
reg [31:0] csr_mcycleh_q;
reg [31:0] csr_minstreth_q;
reg [31:0] csr_mhpmcounterh_q [3:31];

// Counter Setup
reg [31:0] csr_mcountinhibit_q;
reg [31:0] csr_mhpmevent_q    [3:31];
reg [31:0] csr_mhpmeventh_q   [3:31];

//-----------------------------------------------------------------
// Masked Interrupts
//-----------------------------------------------------------------
reg [31:0] irq_pending_r;
reg [31:0] irq_masked_r;
reg [1:0]  irq_priv_r;

// TODO: need to implement s mode check
reg        m_enabled_r;
reg [31:0] m_interrupts_r;
always @(*) begin
    irq_pending_r = (csr_mip_q & csr_mie_q);
    irq_masked_r  = csr_mstatus_q[`SR_MIE_R] ? irq_pending_r : 32'b0;
    irq_priv_r    = `PRIV_MACHINE;
end
reg [1:0] irq_priv_q;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        irq_priv_q <= `PRIV_MACHINE;
    end else if(| irq_masked_r)begin
        irq_priv_q <= irq_priv_r;
    end
end
assign interrupt_o = irq_masked_r;

//-----------------------------------------------------------------
// CSR Read Port
//-----------------------------------------------------------------
reg [31:0] csr_rd_data_r;
always @(*) begin
    case (csr_rd_addr_i)
    // CSR - Machine
        `CSR_MHARTID:   csr_rd_data_r = cpu_id_i;
        // Trap Setup
        `CSR_MSTATUS:   csr_rd_data_r = csr_mstatus_q & `CSR_MSTATUS_MASK;
        `CSR_MISA:      csr_rd_data_r = misa_i;
        `CSR_MEDELEG:   csr_rd_data_r = csr_medeleg_q & `CSR_MEDELEG_MASK;
        `CSR_MIDELEG:   csr_rd_data_r = csr_mideleg_q & `CSR_MIDELEG_MASK;
        `CSR_MIE:       csr_rd_data_r = csr_mie_q & `CSR_MIE_MASK;
        `CSR_MTVEC:     csr_rd_data_r = csr_mtvec_q & `CSR_MTVEC_MASK;
        // Trap Handling
        `CSR_MSCRATCH:  csr_rd_data_r = csr_mscratch_q & `CSR_MSCRATCH_MASK;
        `CSR_MEPC:      csr_rd_data_r = csr_mepc_q & `CSR_MEPC_MASK;
        `CSR_MCAUSE:    csr_rd_data_r = csr_mcause_q & `CSR_MCAUSE_MASK;
        `CSR_MTVAL:     csr_rd_data_r = csr_mtval_q & `CSR_MTVAL_MASK;
        `CSR_MIP:       csr_rd_data_r = csr_mip_q & `CSR_MIP_MASK;
        // Counter/Timers
        `CSR_MCYCLE,    
        `CSR_MTIME:     csr_rd_data_r = csr_mcycle_q;
        `CSR_MTIMEH:    csr_rd_data_r = csr_mcycleh_q;
    // CSR - Supervisor
        default:
                        csr_rd_data_r = 32'b0;
    endcase
end

assign csr_rd_data_o = csr_rd_data_r;
assign priv_o        = csr_priv_q;
assign mstatus_o     = csr_mstatus_q;
// assign satp_o        = csr_satp_q;

//-----------------------------------------------------------------
// CSR register next state
//-----------------------------------------------------------------
    // Information RO
reg [31:0] csr_mvendorid_r;
reg [31:0] csr_marchid_r;
reg [31:0] csr_mimpid_r;
reg [31:0] csr_mhartid_r;
reg [31:0] csr_mconfigptr_r;
    // Trap Setup
reg [31:0] csr_mstatus_r;
reg [31:0] csr_medeleg_r;
reg [31:0] csr_mideleg_r;
reg [31:0] csr_mie_r;
reg [31:0] csr_mtvec_r;
reg [31:0] csr_mcounteren_r;
reg [31:0] csr_mstatush_r;
reg [31:0] csr_medelegh_r;
    // Trap Handling
reg [31:0] csr_mscratch_r;
reg [31:0] csr_mepc_r;
reg [31:0] csr_mcause_r;
reg [31:0] csr_mtval_r;
reg [31:0] csr_mip_r;
reg [31:0] csr_mtinst_r;
reg [31:0] csr_mtval2_r;
    // configuration
reg [31:0] csr_menvcfg_r;
reg [31:0] csr_menvcfgh_r;
reg [31:0] csr_mseccfg_r;
reg [31:0] csr_mseccfgh_r;
    // memory protection
reg [31:0] csr_pmpcfg_r     [0:15];
reg [31:0] csr_pmpaddr_r    [0:63];
    // State Enable Registers
reg [31:0] csr_mstateen_r     [0:3];
reg [31:0] csr_mstateenh_r    [0:3];
    // Non-Maskable Interrupt Handling
reg [31:0] csr_mnscratch_r;
reg [31:0] csr_mnepc_r;
reg [31:0] csr_mncause_r;
reg [31:0] csr_mnstatus_r;
    // Counter/Timers
reg [31:0] csr_mcycle_r;
reg [31:0] csr_minstret_r;
reg [31:0] csr_mhpmcounter_r  [3:31];
reg [31:0] csr_mcycleh_r;
reg [31:0] csr_minstreth_r;
reg [31:0] csr_mhpmcounterh_r [3:31];
    // Counter Setup
reg [31:0] csr_mcountinhibit_r;
reg [31:0] csr_mhpmevent_r    [3:31];
reg [31:0] csr_mhpmeventh_r   [3:31];

wire is_exception = | exception_i;

always @(*) begin
    // privilege level
    csr_priv_r = csr_priv_q;

    // Trap Setup
    csr_mstatus_r   = csr_mstatus_q;
    csr_medeleg_r   = csr_medeleg_q;
    csr_mideleg_r   = csr_mideleg_q;
    csr_mie_r       = csr_mie_q;
    csr_mtvec_r     = csr_mtvec_q;
    csr_medelegh_r  = csr_medelegh_q;

    // Trap Handling
    csr_mscratch_r  = csr_mscratch_q;
    csr_mepc_r      = csr_mepc_q;
    csr_mcause_r    = csr_mcause_q;
    csr_mtval_r     = csr_mtval_q;
    csr_mip_r       = csr_mip_q;

    // Counter/Timers
    csr_mcycle_r    = csr_mcycle_q + 32'd1;

    // Interrupt
    if((exception_i & `EXCEPTION_TYPE_MASK) == `EXCEPTION_INTERRUPT) begin
        if(irq_priv_q == `PRIV_MACHINE) begin
            // Save interrupt / supervisor state
            csr_mstatus_r[`SR_MPIE_R] = csr_mstatus_r[`SR_MIE_R];
            csr_mstatus_r[`SR_MPP_R]  = csr_priv_q;
            csr_mstatus_r[`SR_MIE_R]  = 1'b0;

            // Set privilege level
            csr_priv_r          = `PRIV_MACHINE;

            // Record interrupt source PC
            csr_mepc_r           = exception_pc_i;
            csr_mtval_r          = 32'b0;

            // Piority encoded interrupt cause
            if (interrupt_o[`IRQ_M_SOFT])
                csr_mcause_r = `MCAUSE_INTERRUPT + 32'd`IRQ_M_SOFT;
            else if (interrupt_o[`IRQ_M_TIMER])
                csr_mcause_r = `MCAUSE_INTERRUPT + 32'd`IRQ_M_TIMER;
            else if (interrupt_o[`IRQ_M_EXT])
                csr_mcause_r = `MCAUSE_INTERRUPT + 32'd`IRQ_M_EXT;
        end else begin
            // placeholder for S mode interrupt handling
        end

    // Exception return
    end else if (exception_i >= `EXCEPTION_ERET_U && exception_i <= `EXCEPTION_ERET_M) begin
        // mret
        if(exception_i[1:0] == `PRIV_MACHINE) begin
            // Restore previous level
            csr_priv_r          = csr_mstatus_q[`SR_MPP_R];
            csr_mstatus_r[`SR_MIE_R] = csr_mstatus_q[`SR_MPIE_R];
            csr_mstatus_r[`SR_MPIE_R] = 1'b1; // previous is enabled
            csr_mstatus_r[`SR_MPP_R] = `SR_MPP_M;
        end else begin
        // placeholder for sret handling
        end
    // TODO: need to implement s mode exception handling
    // Exception - Machine
    end else if((exception_i & `EXCEPTION_TYPE_MASK) == `EXCEPTION_EXCEPTION) begin
        csr_mstatus_r[`SR_MPIE_R] = csr_mstatus_r[`SR_MIE_R];
        csr_mstatus_r[`SR_MPP_R]  = csr_priv_q;
        csr_mstatus_r[`SR_MIE_R]  = 1'b0;
        csr_priv_r                = `PRIV_MACHINE;
        csr_mepc_r                = exception_pc_i;
        csr_mcause_r              = {28'b0, exception_i[3:0]}; // need to check if this is correct
        // Bad address / PC
        case (exception_i)
            `EXCEPTION_MISALIGNED_FETCH,
            `EXCEPTION_FAULT_FETCH,
            `EXCEPTION_PAGE_FAULT_INST:     csr_mtval_r = exception_pc_i;
            `EXCEPTION_ILLEGAL_INSTRUCTION,
            `EXCEPTION_MISALIGNED_LOAD,
            `EXCEPTION_FAULT_LOAD,
            `EXCEPTION_MISALIGNED_STORE,
            `EXCEPTION_FAULT_STORE,
            `EXCEPTION_PAGE_FAULT_LOAD,
            `EXCEPTION_PAGE_FAULT_STORE:    csr_mtval_r = exception_addr_i;
            default:                        csr_mtval_r = 32'b0;
        endcase

    // normal write operation WL
    end else if(csr_wr_en_i) begin
        case(csr_wr_addr_i)
        // CSR - Machine
            // Trap Setup
            `CSR_MSTATUS: csr_mstatus_r   = csr_wr_data_i & `CSR_MSTATUS_MASK;
            `CSR_MEDELEG: csr_medeleg_r   = csr_wr_data_i & `CSR_MEDELEG_MASK;
            `CSR_MIDELEG: csr_mideleg_r   = csr_wr_data_i & `CSR_MIDELEG_MASK;
            `CSR_MIE:     csr_mie_r       = csr_wr_data_i & `CSR_MIE_MASK;
            `CSR_MTVEC:   csr_mtvec_r     = csr_wr_data_i & `CSR_MTVEC_MASK;
            // Trap Handling
            `CSR_MSCRATCH:csr_mscratch_r  = csr_wr_data_i & `CSR_MSCRATCH_MASK;
            `CSR_MEPC:    csr_mepc_r      = csr_wr_data_i & `CSR_MEPC_MASK;
            `CSR_MCAUSE:  csr_mcause_r    = csr_wr_data_i & `CSR_MCAUSE_MASK;
            `CSR_MTVAL:   csr_mtval_r     = csr_wr_data_i & `CSR_MTVAL_MASK;
            `CSR_MIP:     csr_mip_r       = csr_wr_data_i & `CSR_MIP_MASK;
            default:;
        endcase
    end
end

//-----------------------------------------------------------------
// Sequential
//-----------------------------------------------------------------

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        // CSR - Machine
            // privilege level
        csr_priv_q     <= `PRIV_MACHINE;
            // Trap Setup
        csr_mstatus_q  <= 32'h0000_1800;
        csr_medeleg_q  <= 32'b0;
        csr_mideleg_q  <= 32'b0;
        csr_mie_q      <= 32'b0;
        csr_mtvec_q    <= 32'b0;
        csr_medelegh_q <= 32'b0;
            // Trap Handling
        csr_mscratch_q <= 32'b0;
        csr_mepc_q     <= 32'b0;
        csr_mcause_q   <= 32'b0;
        csr_mtval_q    <= 32'b0;
        csr_mip_q      <= 32'b0;
            // Counter/Timers
        csr_mcycle_q   <= 32'b0;
        csr_mcycleh_q  <= 32'b0;

    end else begin
        // CSR - Machine
            // privilege level
        csr_priv_q     <= csr_priv_r;
            // Trap Setup
        csr_mstatus_q  <= csr_mstatus_r;
        csr_medeleg_q  <= (csr_medeleg_r  & `CSR_MEDELEG_MASK);
        csr_mideleg_q  <= (csr_mideleg_r  & `CSR_MIDELEG_MASK);
        csr_mie_q      <= csr_mie_r;
        csr_mtvec_q    <= csr_mtvec_r;
        csr_medelegh_q <= csr_medelegh_r;
            // Trap Handling
        csr_mscratch_q <= csr_mscratch_r;
        csr_mepc_q     <= csr_mepc_r;
        csr_mcause_q   <= csr_mcause_r;
        csr_mtval_q    <= csr_mtval_r;
        csr_mip_q      <= csr_mip_r;
            // Counter/Timers
        csr_mcycle_q   <= csr_mcycle_r;
        if (csr_mcycle_q == 32'hFFFFFFFF)
            csr_mcycleh_q <= csr_mcycleh_q + 32'd1;
    end
end

//-----------------------------------------------------------------
// CSR branch
//-----------------------------------------------------------------
reg        csr_branch_r;
reg [31:0] csr_target_r;

always @(*) begin
    csr_branch_r = 1'b0;
    csr_target_r = 32'b0;

    // Interrupt
    if(exception_i == `EXCEPTION_INTERRUPT)begin
        csr_branch_r = 1'b1;
        // TODO: need to implement s mode check
        csr_target_r = csr_mtvec_q;
    end
    // Exception return
    else if(exception_i >= `EXCEPTION_ERET_U && exception_i <= `EXCEPTION_ERET_M) begin
        // mret
        if(exception_i[1:0] == `PRIV_MACHINE) begin
            csr_branch_r = 1'b1;
            csr_target_r = csr_mepc_q;
        end
        // TODO: sret
    end
    // TODO: need to implement s mode exception handling
    // Exception - Machine
    else if((exception_i & `EXCEPTION_TYPE_MASK) == `EXCEPTION_EXCEPTION) begin
        csr_branch_r = 1'b1;
        csr_target_r = csr_mtvec_q;
    end
end

assign csr_branch_o = csr_branch_r;
assign csr_target_o = csr_target_r;

endmodule
