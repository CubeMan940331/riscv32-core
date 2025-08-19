// -----------------------------------------------
// Page Table Walker (PTW)
// -----------------------------------------------

`include "../riscv_defs.v"

module mmu_ptw(
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

// Register & Wire
reg [STATE_W-1:0] fsm_state;
reg [31:0] pte_addr_r;
reg [31:0] pte_value_r;
reg [31:0] req_addr_r;
reg        pte_fault_r;

wire        vm_enable   = satp_i[`SATP_MODE_R];
wire [ 8:0] vm_asid     = satp_i[`SATP_ASID_R];
wire [31:0] vm_ppn      = {satp_i[`SATP_PPN_R],12'b0};

wire [31:0] ppn_data    = {resp_data_i[29:10],12'b0};
wire [ 9:0] pte_flags   = resp_data_i[9:0];

wire        pte_active  = (resp_data_i[`PAGE_READ] || resp_data_i[`PAGE_WRITE] || resp_data_i[`PAGE_EXEC]);
wire        pte_invalid = (!resp_data_i[`PAGE_PRESENT]) && resp_valid_i;

assign update_o     = (fsm_state == STATE_UPDATE);
assign pte_addr_o   = pte_addr_r;
assign pte_value_o  = pte_value_r;
assign pte_fault_o  = pte_fault_r;

assign ptw_work_o = (fsm_state == STATE_LEVEL_FIRST) || (fsm_state == STATE_LEVEL_SECOND);

always @(posedge clk_i or negedge rst_i)begin
    if(~rst_i)
    begin
        fsm_state   <= STATE_IDLE;
        pte_addr_r  <= 32'b0;
        pte_value_r <= 32'b0;   
        req_addr_r  <= 32'b0;
        pte_fault_r <= 0;
    end
    else 
    begin
        if(!vm_enable)
            fsm_state <= STATE_IDLE;
        else if(fsm_state == STATE_IDLE)
        begin
            if(req_valid_i)
            begin
                fsm_state   <= STATE_LEVEL_FIRST;
                req_addr_r  <= req_addr_i;
                pte_addr_r  <= vm_ppn + {20'b0, req_addr_i[31:22],2'b0};
            end
            else
            begin
                fsm_state <= STATE_IDLE;
                pte_addr_r  <= 32'b0;
                pte_value_r <= 32'b0;
                req_addr_r  <= 32'b0;  
                pte_fault_r <= 0;
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
            end
            else if(!pte_active)
            begin
                pte_addr_r <= ppn_data + {20'b0, req_addr_r[21:12],2'b0};
                fsm_state  <= STATE_LEVEL_SECOND;
            end
            else
            begin
                pte_addr_r  <= {12'b0,req_addr_r[31:12]};
                pte_value_r <= resp_data_i;
                fsm_state   <= STATE_UPDATE;
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
            end
            else
            begin
                pte_addr_r  <= {12'b0,req_addr_r[31:12]}; 
                pte_value_r <= resp_data_i;
                fsm_state   <= STATE_UPDATE;
            end
        end
        else if(fsm_state == STATE_UPDATE)
            fsm_state <= STATE_IDLE;
        else
        begin
            fsm_state  <= fsm_state;
        end
    end 
end

endmodule


