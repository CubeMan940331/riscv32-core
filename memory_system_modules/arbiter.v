`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/15 20:48:09
// Design Name: 
// Module Name: arbiter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module arbiter(
    input clk,
    input rst_n,
    
    // sys init
    input [31:0]init_addr_i,
    input [127:0]init_data_i,
    input init_end_i,
    
    // d cache
    input [31:0] d_addr_i,
    input [255:0] d_wr_data_i,
    input d_req_wr_i,
    input d_req_rd_i,
    output reg d_rd_end_o,
    output reg [255:0] d_rd_data_o,
    output reg d_mem_rdy_o,

    // monitor
	output [2:0] arb_cs,
	output [2:0] arm_cs,
    
    // i cache
    input [31:0] i_addr_i,
    input i_req_rd_i,
    output reg i_rd_end_o,
    output reg [255:0] i_rd_data_o,
    output reg i_mem_rdy_o,
    
	///////////////
    // MIG ports //
	///////////////
    output reg [26:0] app_addr,
    output reg [2:0]  app_cmd,
    output reg        app_en,
    input        app_rdy,
	input 	init_mem_rdy,
	
	// write related
    output reg [127:0] app_wdf_data,
    output reg        app_wdf_end,
    output reg        app_wdf_wren,
    input        app_wdf_rdy,
    output reg [15:0] app_wdf_mask,
	
	// read related
    input [127:0] app_rd_data,
    input        app_rd_data_end,
    input        app_rd_data_valid
);
    //////////////////////////////////////////////////////////////////
	//   issue request to MIG (READ回傳的訊息另外處理，加速資料傳輸效率)  //
    //////////////////////////////////////////////////////////////////
	assign arb_cs = cs;
	assign arm_cs = RMCS;
	
	//還沒處理rd_end訊號
	parameter INIT = 0;
	parameter LOAD = 1;
    parameter IDLE = 2;
    parameter D_WM = 3; // write request to MIG
    parameter D_RM = 4; // read request to MIG
	parameter I_RM = 5;
	
	reg [2:0] cs, ns;
    wire mem_wr_rdy = app_rdy & app_wdf_rdy; // MIG ready to write data
	
    always@(posedge clk or negedge rst_n)begin //state update
        if(!rst_n)
            cs <= 0;
        else if(init_mem_rdy)
            cs <= ns;
        else
            cs <= 0;
    end
	// i cache和D cache實現邏輯不一樣
    // i cache 先判 rdy，才會動作              => rdy用於確認可以發送指令
    // d cache 先發request，然後等rdy回來再動作 => rdy用於確認動作完成

	// state transfer logic //
	always@(*)begin
		app_wdf_mask = 16'h0000;
		app_en = 0; 
		app_cmd = 3'b001; 
		app_addr = 0; 
		app_wdf_data = 0; 
		app_wdf_wren = 0; 
		app_wdf_end = 0;

		i_mem_rdy_o = 0;
		d_mem_rdy_o = 0;
		case(cs)
		    INIT :  if(init_mem_rdy)
		                ns = LOAD;
		            else
		                ns = INIT;
			LOAD :	begin
                    app_en = 0; 
                    app_cmd = 3'b000; 
                    app_wdf_wren = 0; 
                    app_addr = init_addr_i[26:0]; 
                    app_wdf_data = init_data_i; 
                    app_wdf_end = 0; 

                    i_mem_rdy_o = 0;
                    d_mem_rdy_o = 0;

                    if(mem_wr_rdy) begin
                        if(init_end_i)
                            ns = IDLE;
                        else
                            ns = LOAD;
                        app_en = 1; //發送請求給MIG
                        app_cmd = 3'b000; //寫命令
                        app_wdf_wren = 1;
                        app_wdf_end = init_end_i; 
                    end
                    else 
                        ns = LOAD;
            end
			IDLE : 	begin
                    app_en = 0; 
                    app_cmd = 3'b001; 
                    app_addr = 0; 
                    app_wdf_data = 0; 
                    app_wdf_wren = 0; 
                    app_wdf_end = 0; 

                    i_mem_rdy_o = app_rdy;
                    d_mem_rdy_o = 0;

                    if(!app_rdy)begin
                        ns = IDLE;
                        i_mem_rdy_o = 0;
                    end
                    else if(i_req_rd_i) begin//下一步發送rd請求給MIG，並分段等待回傳
                        ns = I_RM;
                        app_en = 1; //發送請求給MIG
                        app_cmd = 3'b001; //讀命令
                        app_addr = i_addr_i[26:0];
                    end 
                    else if(d_req_wr_i) begin //下一步發送wr請求給MIG，並切data_i為2 pieces
                        ns = (app_rdy & app_wdf_rdy) ? D_WM : IDLE; //成立的話馬上送一半的資料給MIG
                        app_en = app_wdf_rdy ? 1 : 0; //發送請求給MIG
                        app_cmd = 3'b000; //寫命令
                        app_wdf_wren = 1; //寫入資料的前半部
                        app_wdf_end = 0; //寫入資料的前半部 
                        app_addr = d_addr_i[26:0];
                        app_wdf_data = d_wr_data_i[127:0]; //寫入資料的前半部
                    end
                    else if(d_req_rd_i)begin //下一步發送rd請求給MIG，並分段等待回傳
                        ns = D_RM;
                        app_en = 1; //發送請求給MIG
                        app_cmd = 3'b001; //讀命令
                        app_addr = d_addr_i[26:0];
                    end
                    else 
                        ns = IDLE;
            end
			D_WM :	begin
                    app_en = 0; 
                    app_cmd = 3'b000; 
                    app_wdf_wren = 0; 
                    app_addr = {d_addr_i[26:5],5'd16}; 
                    app_wdf_data = d_wr_data_i[255:128]; 
                    app_wdf_end = 0; 

                    i_mem_rdy_o = 0;
                    d_mem_rdy_o = mem_wr_rdy; 

                    if(mem_wr_rdy) begin
                        ns = IDLE; //等待MIG可寫入並寫入剩下一半的資料，回傳dcache完成
                        app_en = 1; //發送請求給MIG
                        app_cmd = 3'b000; //寫命令
                        app_wdf_wren = 1; //寫入資料的後半部
                        app_addr= {d_addr_i[26:5],5'd16}; 
                        app_wdf_data = d_wr_data_i[255:128]; //寫入資料的後半部
                        app_wdf_end = 1; //寫入資料的後半部
                    end
                    else 
                        ns = D_WM;
            end
            D_RM :	begin
                    app_en = 0; 
                    app_cmd = 3'b001; 
                    app_addr = {d_addr_i[26:5],5'd16}; ; 
                    app_wdf_data = 0; 
                    app_wdf_wren = 0; 
                    app_wdf_end = 0; 

                    i_mem_rdy_o = 0;
                    d_mem_rdy_o = app_rdy; 

                    if(app_rdy) begin
                        ns = IDLE;
                        app_en = 1; //發送請求給MIG
                        app_wdf_wren = 1;
                        app_cmd = 3'b001; //讀命令
                        app_addr = {d_addr_i[26:5],5'd16}; 
                    end
                    else 
                        ns = D_RM;
            end
            I_RM :  begin
                    app_en = 0; 
                    app_cmd = 3'b001; 
                    app_addr = {i_addr_i[26:5],5'd16}; 
                    app_wdf_data = 0; 
                    app_wdf_wren = 0; 
                    app_wdf_end = 0; 

                    i_mem_rdy_o = app_rdy;
                    d_mem_rdy_o = 0; 

                    if(app_rdy) begin
                        ns = IDLE; 
                        app_en = 1; //發送請求給MIG
                        app_wdf_wren = 1; 
                        app_cmd = 3'b001; //讀命令
                        app_addr = {i_addr_i[26:5],5'd16}; 
                    end
                    else 
                        ns = I_RM;
            end
            default : ns = IDLE;
        endcase
    end
	
	
	// deal with RD issue //
	// worst case : I/d同時要讀取mem ?還是直接用的FSM寫??
    //還沒處理讀訊號
	parameter RM_IDLE = 0, RM_I0 = 1, RM_I1 = 2, RM_D0 = 3, RM_D1 = 4, RM_ID = 5, RM_DI = 6;
	reg [2:0]RMCS,RMNS;
	
	reg [127:0] data_temp;
	
	
	// always@(posedge clk or negedge rst_n)begin
		// if(!rst_n)
			// RMCS <= RM_IDLE;
		// else
			// RMCS <= RMNS;
	// end
	
	// reg iWait,dWait;
	// always@(*)begin
		// iWait = iWait;
		// dWait = dWait;
        
        // d_rd_end_o = d_rd_end_o;
        // i_rd_end_o = i_rd_end_o;
        
        // data_temp = data_temp;
        // d_rd_data_o = 0;
        // i_rd_data_o = 0;
		// case(RMCS)
			// RM_IDLE : begin
						// iWait = 0;
						// dWait = 0;

                        // data_temp = 0;
                        // d_rd_data_o = 0;
                        // i_rd_data_o = 0;

						// if(cs != I_RM && ns == I_RM)begin
							// RMNS = RM_I0;
						// end
						// else if(cs != D_RM && ns == D_RM)begin
							// RMNS = RM_D0;
						// end
						// else begin
							// RMNS =RM_IDLE;
						// end
			// end
			// RM_I0	:	begin
						// iWait = 0;
                        // data_temp = data_temp;
						// if(app_rd_data_end && app_rd_data_valid)begin
							// RMNS = RM_I1;
                            // data_temp = app_rd_data;
						// end
						// else 
							// RMNS = RM_I0;
						
						// if(cs != D_RM && ns == D_RM)
							// dWait = 1;
						// else
							// dWait = dWait;				
			// end
			// RM_I1	:	begin
						// iWait = 0;
						// data_temp = data_temp;
                        // i_rd_data_o = {app_rd_data, data_temp};
						// if(app_rd_data_end && app_rd_data_valid)begin
							// RMNS = dWait ? RM_D0 : IDLE;
                            // i_rd_end_o =  1;
						// end
						// else
							// RMNS = RM_I1;
							
						// if(cs != D_RM && ns == D_RM)
							// dWait = 1;
						// else
							// dWait = dWait;	
			// end
			// RM_D0	:	begin
						// dWait = 0;
                        // data_temp = data_temp;
						// if(app_rd_data_end && app_rd_data_valid)begin
							// RMNS = RM_D1;
                            // data_temp = app_rd_data;
						// end
						// else
							// RMNS = RM_D0;
							
						// if(cs != I_RM && ns == I_RM)
							// iWait = 1;
			// end
			// RM_D1	:	begin
						// dWait = 0;
						// data_temp = data_temp;
                        // d_rd_data_o = {app_rd_data, data_temp};
						// if(app_rd_data_end && app_rd_data_valid)begin
							// RMNS = iWait ? RM_D0 : RM_IDLE;
                            // d_rd_end_o = 1;
						// end
						// else
							// RMNS = RM_D1;
							
						// if(cs != I_RM && ns == I_RM)
							// iWait = 1;
						// else
							// iWait = iWait;	
			// end
			// default	: RMNS = RM_IDLE;
		// endcase
	// end
	
	reg iWait,dWait;
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			RMCS <= RM_IDLE;
		else begin		
			case(RMCS)
				RM_IDLE : begin
							iWait <= 0;
							dWait <= 0;

							data_temp <= 0;
							d_rd_data_o <= 0;
							i_rd_data_o <= 0;
							d_rd_end_o <= 0;
							i_rd_end_o <= 0;

							if(cs != I_RM && ns == I_RM)begin
								RMCS <= RM_I0;
							end
							else if(cs != D_RM && ns == D_RM)begin
								RMCS <= RM_D0;
							end
							else begin
								RMCS <= RM_IDLE;
							end
				end
				RM_I0	:	begin
							iWait <= 0;
							data_temp <= data_temp;
							d_rd_data_o <= 0;
							i_rd_data_o <= 0;
							d_rd_end_o <= 0;
							i_rd_end_o <= 0;
							if(app_rd_data_end && app_rd_data_valid)begin
								RMCS <= RM_I1;
								data_temp <= app_rd_data;
							end
							else 
								RMCS <= RM_I0;
							
							if(cs != D_RM && ns == D_RM)
								dWait <= 1;
							else
								dWait <= dWait;				
				end
				RM_I1	:	begin
							iWait <= 0;
							data_temp <= data_temp;
							d_rd_end_o <= 0;
							d_rd_data_o <= 0;
							i_rd_data_o <= {app_rd_data, data_temp};
							if(app_rd_data_end && app_rd_data_valid)begin
								RMCS <= dWait ? RM_D0 : RM_IDLE;
								
								i_rd_end_o <=  1;
							end
							else begin
								RMCS <= RM_I1;
								i_rd_end_o <= 0;
							end
							
							if(cs != D_RM && ns == D_RM)
								dWait <= 1;
							else
								dWait <= dWait;	
				end
				RM_D0	:	begin
							dWait <= 0;
							data_temp <= data_temp;
							d_rd_end_o <= 0;
							i_rd_end_o <= 0;
							d_rd_data_o <= 0;
							i_rd_data_o <= 0;
							if(app_rd_data_end && app_rd_data_valid)begin
								RMCS <= RM_D1;
								data_temp <= app_rd_data;
							end
							else
								RMCS <= RM_D0;
								
							if(cs != I_RM && ns == I_RM)
								iWait <= 1;
							else
								iWait <= iWait;
				end
				RM_D1	:	begin
							dWait <= 0;
							data_temp <= data_temp;
							i_rd_end_o <= 0;
							i_rd_data_o <= 0;
							d_rd_data_o <= {app_rd_data, data_temp};
							if(app_rd_data_end && app_rd_data_valid)begin
								RMCS <= iWait ? RM_D0 : RM_IDLE;
								d_rd_end_o <= 1;
							end
							else begin
								RMCS <= RM_D1;
								d_rd_end_o <= 0; 
							end
								
							if(cs != I_RM && ns == I_RM)
								iWait <= 1;
							else
								iWait <= iWait;	
				end
				default	: 	begin
							RMCS <= RM_IDLE;
							iWait <= iWait;
							dWait <= dWait;
							
							d_rd_end_o <= d_rd_end_o;
							i_rd_end_o <= i_rd_end_o;
							
							data_temp <= data_temp;
							d_rd_data_o <= d_rd_data_o;
							i_rd_data_o <= i_rd_data_o; end
			endcase
		end
	end
endmodule
