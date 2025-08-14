// -----------------------------------------------
// TLB
// -----------------------------------------------

module TLB
#(
    parameter PPN_SIZE = 20
)
(
     input                  clk_i
    ,input                  rst_i
    ,input  [PPN_SIZE-1:0]  addr_i
    ,input  [31:0]          entry_i
    ,input                  valid_i
    ,input                  update_i

    ,output                 hit_o
    ,output [31:0]          entry_o
);

reg [PPN_SIZE-1:0]  vpn_q;
reg [31:0]          entry_q;
reg                 tlb_valid_r;

assign hit_o   = valid_i  && (addr_i == vpn_q) && tlb_valid_r;
assign entry_o = entry_q;

always @(posedge clk_i or negedge  rst_i)begin
    if(~rst_i)begin
        begin
            vpn_q       <= 20'b0;
            entry_q     <= 32'b0; 
            tlb_valid_r <= 0;   
        end
    end else begin
        if(update_i && valid_i)
        begin
            vpn_q       <= addr_i;
            entry_q     <= entry_i;
            tlb_valid_r <= 1;
        end
    end

end

endmodule


// -----------------------------------------------
// Page Table Walker (PTW)
// -----------------------------------------------

module PTW(
     input          clk_i
    ,input          rst_i
    ,input  [31:0]  satp_i
    ,input  [31:0]  req_addr_i      // virtual address
    ,input          req_valid_i     
    ,input  [31:0]  resp_data_i     // page table return value
    ,input          resp_valid_i
    ,input          pte_errow_i     // page table fault

    ,output [31:0]  pte_addr_o      // physical address of page table entry
    ,output [31:0]  pte_value_o     // page table entry value
    // ,output         pte_rd_o        // page table entry read
    ,output         update_o        // state is update
    ,output         ptw_work_o
    ,output         pte_fault_o
);

// State 
localparam STATE_W              = 2;
localparam STATE_IDLE           = 0;
localparam STATE_LEVEL_FIRST    = 1;
localparam STATE_LEVEL_SECOND   = 2;
localparam STATE_UPDATE         = 3;

// Satp
localparam SAPT_PPN             = 20;

// Page Struct
localparam PAGE_VALID           = 0;
localparam PAGE_READ            = 1;
localparam PAGE_WRITE           = 2;
localparam PAGE_EXE             = 3;
localparam PAGE_USER            = 4;
localparam PAGE_GLOBAL          = 5;
localparam PAGE_ACCESS          = 6;
localparam PAGE_DIRTY           = 7;


// Register & Wire
reg [STATE_W-1:0] fsm_state;
reg [31:0] pte_addr_r;
reg [31:0] pte_value_r;
reg [31:0] req_addr_r;
reg        pte_fault_r;

wire [31:0] start_ppn   = {satp_i[SAPT_PPN-1:0],12'b0};
wire [31:0] ppn_data    = {resp_data_i[29:10],12'b0};
wire [ 9:0] pte_flags   = resp_data_i[9:0];

wire        pte_active  = (resp_data_i[PAGE_READ] || resp_data_i[PAGE_WRITE] || resp_data_i[PAGE_EXE]);
wire        pte_invalid = (!resp_data_i[PAGE_VALID]) && resp_valid_i;

// Assign
assign update_o     = (fsm_state == STATE_UPDATE);
assign pte_addr_o   = pte_addr_r;
assign pte_value_o  = pte_value_r;
assign pte_fault_o  = pte_fault_r;

reg ptw_work_r;
// assign ptw_work_o = ptw_work_r;
assign ptw_work_o = (fsm_state == STATE_LEVEL_FIRST) || (fsm_state == STATE_LEVEL_SECOND);

always @(posedge clk_i or negedge rst_i)begin
    if(~rst_i)
    begin
        fsm_state   <= STATE_IDLE;
        pte_addr_r  <= 32'b0;
        pte_value_r <= 32'b0;
        req_addr_r  <= 32'b0;
        pte_fault_r <= 0;
        ptw_work_r  <= 0;
    end
    else 
    begin
        if(fsm_state == STATE_IDLE)
        begin
            if(req_valid_i)
            begin
                fsm_state   <= STATE_LEVEL_FIRST;
                req_addr_r  <= req_addr_i;
                pte_addr_r  <= start_ppn + {20'b0, req_addr_i[31:22],2'b0};
                ptw_work_r  <= 1;
            end
            else
            begin
                fsm_state <= STATE_IDLE;
                pte_addr_r  <= 32'b0;
                pte_value_r <= 32'b0;
                req_addr_r  <= 32'b0;  
                pte_fault_r <= 0;
                ptw_work_r  <= 0;
            end
        end
        else if(fsm_state == STATE_LEVEL_FIRST && resp_valid_i)
        begin
            if(pte_errow_i || pte_invalid)
            begin
                pte_addr_r  <= 32'b0;
                pte_value_r <= 32'b0;
                fsm_state   <= STATE_UPDATE;
                pte_fault_r <= 1;
                ptw_work_r  <= 0;
            end
            else if(!pte_active)
            begin
                pte_addr_r <= ppn_data + {20'b0, req_addr_r[21:12],2'b0};
                fsm_state  <= STATE_LEVEL_SECOND;
                ptw_work_r <= 1;
            end
            else
            begin
                pte_addr_r  <= {12'b0,req_addr_r[31:12]};
                pte_value_r <= resp_data_i;
                fsm_state   <= STATE_UPDATE;
                ptw_work_r  <= 0;
            end
        end
        else if(fsm_state == STATE_LEVEL_SECOND && resp_valid_i)
        begin
            if(pte_errow_i || pte_invalid)
            begin
                pte_addr_r  <= 32'b0;
                pte_value_r <= 32'b0;
                fsm_state   <= STATE_UPDATE;
                pte_fault_r <= 1;
                ptw_work_r  <= 0;
            end
            else
            begin
                pte_addr_r  <= {12'b0,req_addr_r[31:12]}; 
                pte_value_r <= resp_data_i;
                fsm_state   <= STATE_UPDATE;
                ptw_work_r  <= 0;
            end
        end
        else if(fsm_state == STATE_UPDATE)
            fsm_state <= STATE_IDLE;
        else
        begin
            fsm_state  <= fsm_state;
            ptw_work_r <= 0;
        end
    end 
end

endmodule

// Dcache Signal Control
module Dcache_Ctrl(
     input clk_i
    ,input rst_i
    ,input mmu_dcache_rd_i
    ,input mmu_dcache_wr_i
    ,input dcache_mmu_available_i
    ,output mmu_dcache_rd_o
    ,output mmu_dcache_wr_o
    ,output dcache_valid_o
);

reg dcache_mmu_available_pre;
reg dcache_valid_r;

assign dcache_valid_o  = dcache_valid_r && dcache_mmu_available_i;
assign mmu_dcache_rd_o = mmu_dcache_rd_i && dcache_mmu_available_pre;
assign mmu_dcache_wr_o = mmu_dcache_wr_i && dcache_mmu_available_pre;

always @(posedge clk_i or negedge rst_i)begin
    if(!rst_i)begin
        dcache_mmu_available_pre <= 1;
        dcache_valid_r <= 0;
    end else begin
        dcache_mmu_available_pre <= dcache_mmu_available_i;
        dcache_valid_r <= (mmu_dcache_rd_i || mmu_dcache_wr_i) && dcache_mmu_available_i;
    end
end

endmodule 
