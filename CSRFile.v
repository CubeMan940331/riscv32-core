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
    ,output [31:0]  satp_o

    ,output [31:0]  interrupt_o

    // memory interface
    ,input  [31:0] d_mem_addr_i
    ,input         d_mem_wr_en_i
    ,input         d_mem_rd_en_i
);

// utilities
reg [1:0]   csr_priv_r;
reg [1:0]   csr_priv_q;

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
reg [31:0] csr_mip_next_q;
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

// Floating Point
reg [31:0] csr_fflags_q;
reg [31:0] csr_frm_q;

// Timer interrupts
reg [31:0] csr_mtimecmp_q;
reg        csr_mtime_ie_q;

// CSR - Supervisor
reg [31:0]  csr_satp_q;

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

reg csr_mip_upd_q;
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) csr_mip_upd_q <= 1'b0;
    else if (csr_rd_addr_i == `CSR_MIP) csr_mip_upd_q <= 1'b1;
    else if (csr_wr_addr_i == `CSR_MIP || (|exception_i)) csr_mip_upd_q <= 1'b0;
end
wire buffer_mip_w = (csr_rd_addr_i == `CSR_MIP) | csr_mip_upd_q;

//-----------------------------------------------------------------
// CSR Read Port
//-----------------------------------------------------------------
reg [31:0] csr_rd_data_r;
always @(*) begin
    casez (csr_rd_addr_i)
    // CSR - Machine
        `CSR_MHARTID:   csr_rd_data_r = cpu_id_i;
        // Trap Setup
        // no need in S-mode
        `CSR_MSTATUS:   csr_rd_data_r = {csr_mstatus_q[31:13], (csr_mstatus_q[12:11] == 2'b11) ? 2'b11 : 2'b00, csr_mstatus_q[10:0]} & `CSR_MSTATUS_MASK;
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
        // Memory Protection
        `CSR_PMPCFG:    csr_rd_data_r = csr_pmpcfg_q[csr_rd_addr_i[3:0]] & `CSR_PMPCFG_MASK;
        `CSR_PMPADDR:   csr_rd_data_r = csr_pmpaddr_q[csr_rd_addr_i[5:0]];
        // Counter/Timers
        `CSR_MCYCLE,    
        `CSR_MTIME:     csr_rd_data_r = csr_mcycle_q;
        `CSR_MCYCLEH,  
        `CSR_MTIMEH:    csr_rd_data_r = csr_mcycleh_q;
        // Floating Point
        `CSR_FFLAGS:    csr_rd_data_r = csr_fflags_q & `CSR_FFLAGS_MASK;
        `CSR_FRM:       csr_rd_data_r = csr_frm_q & `CSR_FRM_MASK;
        `CSR_FCSR:      csr_rd_data_r = {24'b0, csr_frm_q[2:0], csr_fflags_q[4:0]} & `CSR_FCSR_MASK;
        // Non-Standard Timer Interrupt
        `CSR_MTIMECMP:  csr_rd_data_r = csr_mtimecmp_q;
    // CSR - Supervisor
        `CSR_SATP:      csr_rd_data_r = csr_satp_q & `CSR_SATP_MASK;
        default:        csr_rd_data_r = 32'b0;
    endcase
end

assign csr_rd_data_o = csr_rd_data_r;
assign priv_o        = csr_priv_q;
assign mstatus_o     = csr_mstatus_q;
assign satp_o        = csr_satp_q;

//-----------------------------------------------------------------
// CSR register next state
//-----------------------------------------------------------------
// CSR - Machine
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
reg [31:0] csr_mip_next_r;
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
    // Floating Point
reg [31:0] csr_fflags_r;
reg [31:0] csr_frm_r;
    // Timer interrupts
reg [31:0] csr_mtimecmp_r;
reg        csr_mtime_ie_r;
// CSR - Supervisor
    // SATP
reg [31:0] csr_satp_r;

integer i;
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
    csr_mip_next_r  = csr_mip_next_q;

    // Memory Protection
    for (i=0; i<16; i=i+1) begin
        csr_pmpcfg_r[i]  = csr_pmpcfg_q[i];
    end
    for (i=0; i<64; i=i+1) begin
        csr_pmpaddr_r[i] = csr_pmpaddr_q[i];
    end

    // Counter/Timers
    csr_mcycle_r    = csr_mcycle_q + 32'd1;

    // Floating Point
    csr_fflags_r    = csr_fflags_q;
    csr_frm_r       = csr_frm_q;

    // Non-Standard Timer Interrupt
    csr_mtimecmp_r  = csr_mtimecmp_q;
    csr_mtime_ie_r  = csr_mtime_ie_q;

    // SATP
    csr_satp_r      = csr_satp_q;

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
        csr_mstatus_r[`SR_SD_R]   = (csr_mstatus_r[`SR_FS_R] == `SR_FS_DIRTY) || (csr_mstatus_r[`SR_XS_R] == `SR_XS_DIRTY);
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

    // FPU flag write-in
    end else if(exception_i == `EXCEPTION_FPU) begin
        csr_fflags_r = csr_wr_data_i & `CSR_FFLAGS_MASK;
    // normal write operation WL
    end else if(csr_wr_en_i) begin
        casez(csr_wr_addr_i)
        // CSR - Machine
            // Trap Setup
            `CSR_MSTATUS: csr_mstatus_r   = {csr_wr_data_i[31:13], (csr_wr_data_i[12:11] == 2'b11) ? 2'b11 : 2'b00, csr_wr_data_i[10:0]} & `CSR_MSTATUS_MASK;
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
            // Memory Protection
                // PMP Configuration
            `CSR_PMPCFG:
                csr_pmpcfg_r[csr_wr_addr_i[3:0]] = csr_wr_data_i & `CSR_PMPCFG_MASK;
                // PMP Address
            `CSR_PMPADDR:
                csr_pmpaddr_r[csr_wr_addr_i[5:0]] = csr_wr_data_i;
            // Floating Point
            `CSR_FFLAGS:  csr_fflags_r    = csr_wr_data_i & `CSR_FFLAGS_MASK;
            `CSR_FRM:     csr_frm_r       = csr_wr_data_i & `CSR_FRM_MASK;
            `CSR_FCSR:
            begin
                csr_fflags_r = csr_wr_data_i & `CSR_FFLAGS_MASK;
                csr_frm_r    = (csr_wr_data_i >> 5) & `CSR_FRM_MASK;
            end
            // Non-Standard Timer Interrupt
            `CSR_MTIMECMP:
            begin
                csr_mtimecmp_r = csr_wr_data_i & `CSR_MTIMECMP_MASK;
                csr_mtime_ie_r = 1'b1;
            end
        // CSR - Supervisor
            // SATP
            `CSR_SATP:     csr_satp_r     = csr_wr_data_i & `CSR_SATP_MASK;
            default:;
        endcase
    end

    // Internal timer compare interrupt
    if(csr_mcycle_q == csr_mtimecmp_q) begin
        if(!csr_mtime_ie_q)
            csr_mip_next_r[`SR_IP_MTIP_R] = 1'b0;
        else
            csr_mip_next_r[`SR_IP_MTIP_R] = 1'b1;
        // TODO: need to implement s mode check
        csr_mtime_ie_r  = 1'b0;
    end

    csr_mip_r = csr_mip_r | csr_mip_next_r;
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
        csr_mip_next_q <= 32'b0;
            // Memory Protection
        for (i=0; i<16; i=i+1) begin
            csr_pmpcfg_q[i]  <= 32'b0;
        end
        for (i=0; i<64; i=i+1) begin
            csr_pmpaddr_q[i] <= 32'b0;
        end
            // Counter/Timers
        csr_mcycle_q   <= 32'b0;
        csr_mcycleh_q  <= 32'b0;
            // Floating Point
        csr_fflags_q   <= 32'b0;
        csr_frm_q      <= 32'b0;
            // Non-Standard Timer Interrupt
        csr_mtimecmp_q <= 32'b0;
        csr_mtime_ie_q <= 1'b0;

        // CSR - Supervisor
            // SATP
        csr_satp_q     <= 32'b0;
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
            // Memory Protection
        for (i=0; i<16; i=i+1) begin
            csr_pmpcfg_q[i]  <= csr_pmpcfg_r[i];
        end
        for (i=0; i<64; i=i+1) begin
            csr_pmpaddr_q[i] <= csr_pmpaddr_r[i];
        end
            // Counter/Timers
        csr_mcycle_q   <= csr_mcycle_r;
        if (csr_mcycle_q == 32'hFFFFFFFF)
            csr_mcycleh_q <= csr_mcycleh_q + 32'd1;
            // Floating Point
        csr_fflags_q   <= csr_fflags_r;
        csr_frm_q      <= csr_frm_r;
            // Non-Standard Timer Interrupt
        csr_mtimecmp_q <= csr_mtimecmp_r;
        csr_mtime_ie_q <= csr_mtime_ie_r;
        csr_mip_next_q <= buffer_mip_w ? csr_mip_next_r : 32'b0;
        // CSR - Supervisor
            // SATP
        csr_satp_q     <= csr_satp_r & `CSR_SATP_MASK;

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
    // Fence / SATP register writes cause pipeline flushes
    else if (exception_i == `EXCEPTION_FENCE) begin
        csr_branch_r = 1'b1;
        csr_target_r = exception_pc_i + 32'd4;
    end
end

assign csr_branch_o = csr_branch_r;
assign csr_target_o = csr_target_r;

//-----------------------------------------------------------------
// PMP check
//-----------------------------------------------------------------
wire [63:0] pmp_matched;
wire [126:0] pmp_matched_internal /*verilator split_var*/;

wire [63:0] pmp_pc_matched;
wire [126:0] pmp_pc_matched_internal /*verilator split_var*/;

wire [63:0] pmp_x_nok; // 1 not ok, 0 ok
wire [63:0] pmp_x_deney; // with priv check
wire [126:0] pmp_x_deney_internal /*verilator split_var*/;

wire [63:0] pmp_w_nok;
wire [63:0] pmp_w_deney;
wire [126:0] pmp_w_deney_internal /*verilator split_var*/;

wire [63:0] pmp_r_nok;
wire [63:0] pmp_r_deney;
wire [126:0] pmp_r_deney_internal /*verilator split_var*/;

// helper functions
function automatic pmp_L;
    input [7:0] cfg; begin pmp_L = cfg[7]; end
endfunction
function automatic [1:0] pmp_A;
    input [7:0] cfg; begin pmp_A = cfg[4:3]; end
endfunction
function automatic pmp_X;
    input [7:0] cfg; begin pmp_X = cfg[2]; end
endfunction
function automatic pmp_W;
    input [7:0] cfg; begin pmp_W = cfg[1]; end
endfunction
function automatic pmp_R;
    input [7:0] cfg; begin pmp_R = cfg[0]; end
endfunction
function automatic [7:0] get_pmpcfg;
    input integer idx;
    reg [31:0] word;
    reg [1:0]  which;
    begin
        word  = csr_pmpcfg_q[idx >> 2];
        which = idx[1:0];
        get_pmpcfg = word[(which*8) +: 8];
    end
endfunction
function automatic integer count_trailing_ones;
    input [31:0] v;
    integer k;
    begin
        k = 0;
        while ((k < 32) && (v[k] == 1'b1)) begin
            k = k + 1;
        end
        count_trailing_ones = k;
    end
endfunction

function automatic pmp_match(
    input integer idx,
    input [31:0] addr
);
    reg [31:0] napot_mask;
    integer trailing_ones;
    begin
        case (pmp_A(get_pmpcfg(idx)))
            // OFF
            2'b00: pmp_match = 1'b0;
            // TOR
            2'b01: begin
                if(idx==0) pmp_match = (addr < csr_pmpaddr_q[idx]);
                else pmp_match = (
                    addr >= csr_pmpaddr_q[idx-1] &&
                    addr < csr_pmpaddr_q[idx]
                );
            end
            // NA4
            2'b10: pmp_match = (addr == csr_pmpaddr_q[idx]);
            // NAPOT
            2'b11: begin
                trailing_ones = count_trailing_ones(csr_pmpaddr_q[idx]);
                if (trailing_ones >= 31) pmp_match = 1'b1; // covers all memory
                else begin
                    napot_mask = ~((32'h1 << (trailing_ones + 1)) - 1);
                    pmp_match = (
                        (csr_pmpaddr_q[idx] & napot_mask) ==
                        (addr & napot_mask)
                    );
                end
            end
        endcase
    end
endfunction

genvar gen_i;
// matching
generate
    for (gen_i = 0; gen_i < 64; gen_i = gen_i + 1) begin
        assign pmp_matched[gen_i] = pmp_match(gen_i, {2'h0, d_mem_addr_i[31:2]});
        assign pmp_matched_internal[gen_i+63] = pmp_matched[gen_i];
    end
endgenerate
// pc matching
generate
    for (gen_i = 0; gen_i < 64; gen_i = gen_i + 1) begin
        assign pmp_pc_matched[gen_i] = pmp_match(gen_i, {2'h0, exception_pc_i[31:2]});
        assign pmp_pc_matched_internal[gen_i+63]=pmp_pc_matched[gen_i];
    end
endgenerate
// x check
generate
    for(gen_i=0; gen_i<64; gen_i=gen_i+1) begin
        assign pmp_x_nok[gen_i] = !pmp_X(get_pmpcfg(gen_i));
        assign pmp_x_deney[gen_i] = pmp_L(get_pmpcfg(gen_i)) ? pmp_x_nok[gen_i]: (priv_o!=2'b11 && pmp_x_nok[gen_i]);
        assign pmp_x_deney_internal[gen_i+63] = pmp_x_deney[gen_i];
    end
endgenerate
// w check
generate
    for(gen_i=0; gen_i<64; gen_i=gen_i+1) begin
        assign pmp_w_nok[gen_i] = d_mem_wr_en_i && !pmp_W(get_pmpcfg(gen_i));
        assign pmp_w_deney[gen_i] = pmp_L(get_pmpcfg(gen_i)) ? pmp_w_nok[gen_i]: (priv_o!=2'b11 && pmp_w_nok[gen_i]);
        assign pmp_w_deney_internal[gen_i+63] = pmp_w_deney[gen_i];
    end
endgenerate
// r check
generate
    for(gen_i=0; gen_i<64; gen_i=gen_i+1) begin
        assign pmp_r_nok[gen_i] = d_mem_rd_en_i && !pmp_R(get_pmpcfg(gen_i));
        assign pmp_r_deney[gen_i] = pmp_L(get_pmpcfg(gen_i)) ? pmp_r_nok[gen_i]: (priv_o!=2'b11 && pmp_r_nok[gen_i]);
        assign pmp_r_deney_internal[gen_i+63] = pmp_r_deney[gen_i];
    end
endgenerate

// merge result
// using complete binary tree
generate
    for(gen_i=1;gen_i<64;gen_i=gen_i+1) begin
        // i*2;
        // i*2+1;
        assign pmp_matched_internal[gen_i-1] = (
            pmp_matched_internal[gen_i*2-1] ? 
            pmp_matched_internal[gen_i*2-1]: pmp_matched_internal[gen_i*2]
        );
        assign pmp_w_deney_internal[gen_i-1] = (
            pmp_matched_internal[gen_i*2-1] ? 
            pmp_w_deney_internal[gen_i*2-1]: pmp_w_deney_internal[gen_i*2]
        );
        assign pmp_r_deney_internal[gen_i-1] = (
            pmp_matched_internal[gen_i*2-1] ? 
            pmp_r_deney_internal[gen_i*2-1]: pmp_r_deney_internal[gen_i*2]
        );
        
        assign pmp_pc_matched_internal[gen_i-1] = (
            pmp_pc_matched_internal[gen_i*2-1] ?
            pmp_pc_matched_internal[gen_i*2-1] : pmp_pc_matched_internal[gen_i*2]
        );
        assign pmp_x_deney_internal[gen_i-1] = (
            pmp_pc_matched_internal[gen_i*2-1] ?
            pmp_x_deney_internal[gen_i*2-1]: pmp_x_deney_internal[gen_i*2]
        );
    end
endgenerate

// generate exception
reg [1:0] pmp_exception_q;
always @(*) begin
    pmp_exception_q = 0;
    if( // fetch fault
        (pmp_pc_matched_internal[0] && pmp_x_deney_internal[0]) ||
        (!pmp_pc_matched_internal[0] && priv_o!=2'b11)
    ) pmp_exception_q=2'b01;
    else if( // store fault
        (pmp_matched_internal[0] && pmp_w_deney_internal[0]) ||
        (!pmp_matched_internal[0] && priv_o!=2'b11 && d_mem_wr_en_i)
    ) pmp_exception_q=2'b10;
    else if( // load fault
        (pmp_matched_internal[0] && pmp_r_deney_internal[0]) ||
        (!pmp_matched_internal[0] && priv_o!=2'b11 && d_mem_rd_en_i)
    ) pmp_exception_q=2'b11;
end

// end of pmp check

`ifdef verilator
function [31:0] get_mcycle; /*verilator public*/
begin
    get_mcycle = csr_mcycle_q;
end
endfunction
`endif

endmodule
