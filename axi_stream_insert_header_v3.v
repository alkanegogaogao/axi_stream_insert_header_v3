`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         xxx
// Engineer:        alkane
// 
// Create Date:     2024/04/27
// Design Name:     xxx
// Module Name:     xxx
// Project Name:    xxx
// Target Devices:  xxx
// Tool Versions:   VIVADO2020.2
// Description:     xxx
// 
// Dependencies:    xxx
// 
// Revision:     v0.3
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module axi_stream_insert_header 
#(
	parameter 						DATA_WD 		= 32					,
	parameter 						DATA_BYTE_WD 	= DATA_WD / 8			,//4  3'100
	parameter 						BYTE_CNT_WD 	= $clog2(DATA_BYTE_WD)	 //3  4的二进制位数
)(
	input 							clk				,
	input 							rst_n			,
	// AXI Stream input original data
	input 							valid_in		,
	input 	[DATA_WD-1 : 0] 		data_in			,
	input 	[DATA_BYTE_WD-1 : 0] 	keep_in			,
	input 							last_in			,
	output 							ready_in		,
	// AXI Stream output with header inserted
	output 							valid_out		,
	output 	[DATA_WD-1 : 0] 		data_out		,
	output 	[DATA_BYTE_WD-1 : 0] 	keep_out		,
	output 							last_out		,
	input 							ready_out		,
	// The header to be inserted to AXI Stream input
	input 							valid_insert	,
	input 	[DATA_WD-1 : 0] 		data_insert		,
	input 	[DATA_BYTE_WD-1 : 0] 	keep_insert		,
	input	[BYTE_CNT_WD-1 : 0]		byte_insert_cnt	,
	output 							ready_insert
);

/***************function**************/
// calculate the 1's number
function [DATA_WD:0]swar;
    input [DATA_WD:0] data_in;
    reg [DATA_WD:0] i;
    begin
        i = data_in;
        i = (i & 32'h55555555) + ({0, i[DATA_WD:1]} & 32'h55555555);
        i = (i & 32'h33333333) + ({0, i[DATA_WD:2]} & 32'h33333333);
        i = (i & 32'h0F0F0F0F) + ({0, i[DATA_WD:4]} & 32'h0F0F0F0F);
        i = i * (32'h01010101);
        swar = i[31:24];    
    end        
endfunction

////计算二进制位宽,低位为1的数目
//function integer clog2d(input reg number);
//	for(clog2d = 0 ; number > 0 ; clog2d = clog2d + 1)
//		number = number >> 1;
//endfunction


/************parameter****************/


/***************wire******************/
wire	w_insert_active			;
wire	w_in_active				;
wire	w_out_active			;
wire	w_in_active_flag		;
wire	w_out_cnt_active		;
/***************reg*******************/
reg						r_ready_insert	;
reg	[DATA_BYTE_WD-1:0]	r_keep_insert	;
reg						r_ready_in  	;
reg	[DATA_WD-1:0]		r_data			;
reg	[DATA_WD-1:0]		r_data1			;
reg	[DATA_BYTE_WD-1:0]	r_keep			;
reg	[DATA_BYTE_WD-1:0]	r_keep1			;
reg						r_in_active1	;
reg						r_in_active2	;
reg	[4:0]				r_out_cnt		;
//reg	[DATA_WD-1:0]		r_data_out	;
reg	[DATA_WD*2-1:0]		r_data01_out	;
reg 					r_valid_out		;
reg	[DATA_BYTE_WD-1:0]	r_keep_out		;
reg 					r_last_out		;


/***************assign*******************/
assign	w_insert_active = 	valid_insert && ready_insert	;
assign  w_in_active 	= 	valid_in && ready_in			;
assign	w_out_active 	= 	valid_out && ready_out			;
assign	ready_insert 	= 	r_ready_insert					;
//assign	ready_in 		= 	~ready_insert				;
assign  ready_in        =   r_ready_in                      ;
assign	data_out 		= 	r_data01_out[DATA_WD-1:0]		;
assign	last_out		= 	r_last_out						;
assign	keep_out		= 	r_keep_out						;
assign	valid_out		= 	r_valid_out						;
//assign	w_out_cnt_active = w_in_active_flag || valid_out;

/*************************************/
//输出信号ready_insert
reg [3:0] r_rinsert_interval;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		r_ready_insert <= 1'b1;
	else if(w_insert_active)
		r_ready_insert <= 1'b0;
	else if(last_in) begin
		r_rinsert_interval = {$random}%6 + 1;
		repeat (r_rinsert_interval)@(posedge clk);        
		r_ready_insert <= 1'b1;
    end
	else
		r_ready_insert <= r_ready_insert;
end

//insert有效时，寄存此刻对应的insert_keep值
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		r_keep_insert <= {DATA_BYTE_WD{1'b0}};//4'b0
	else if(w_insert_active)
		r_keep_insert <= keep_insert;
	else
		r_keep_insert <= r_keep_insert;
end

reg [3:0] r_rin_interval;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        r_ready_in <= 1'b0;
    else if(last_in)
        r_ready_in <= 1'b0;
    else begin
        r_rin_interval <= {$random}%12 + 1;
        repeat(r_rin_interval)@(posedge clk);
        r_ready_in <= 1'b1;
    end
end


//得到w_in_active上升沿
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		r_in_active1 <= 0;
		r_in_active2 <= 0;
	end
	else begin
		r_in_active1 <= w_in_active;
		r_in_active2 <= r_in_active1;
	end
end
assign w_in_active_flag = r_in_active1 && (~r_in_active2);


//将data以及对应的keep缓存，并打一拍
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		r_data <= 0;
		r_keep <= 0;
	end
	else if(w_insert_active)begin
		r_data <= data_insert;
		r_keep <= keep_insert;
	end
	else if(w_in_active)begin
		r_data <= data_in;
		r_keep <= keep_in;
	end
	else begin
		r_data <= r_data;
		r_keep <= r_keep;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		r_data1 <= 0;
		r_keep1 <= 0;
	end
	else begin
		r_data1 <= r_data;
		r_keep1 <= r_keep;
	end
end


//输出有效信号
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		r_valid_out <= 1'b0;
	else if(w_in_active_flag)
		r_valid_out <= 1'b1;
	else if(last_out)
		r_valid_out <= 1'b0;
	else
		r_valid_out <= r_valid_out;
end

//输出有效信号时，开始计数
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		r_out_cnt <= 0;
	else if(valid_out && last_out)
		r_out_cnt <= 0;
	else if(w_in_active_flag)
		r_out_cnt <= 0;
	else
		r_out_cnt <= r_out_cnt +1;
end

//always@(posedge clk or negedge rst_n)begin
//	if(!rst_n)
//		r_out_cnt <= 0;
//	else if(valid_out && (~last_out))
//		r_out_cnt <= r_out_cnt +1;
//	else if(r_out_cnt == 5)
//		r_out_cnt <= r_out_cnt +1;
//	else 
//		r_out_cnt <= r_out_cnt;
//end

//输出信号的最后一个信号标志
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		r_last_out <= 1'b0;
	else if(valid_out && (r_out_cnt == 4))
		r_last_out <= 1'b1;
	else
		r_last_out <= 1'b0;
end


//获得拼接好的输出信号，信号位宽是所需信号位宽的两倍，输出信号截取此信号的低位即可
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		r_data01_out <= 0;
	else if(w_in_active_flag || valid_out)
		r_data01_out <= {r_data1,r_data} >> swar(r_keep_insert)*8;
	else
		r_data01_out <= r_data01_out;
end



//输出keep寄存器
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		r_keep_out <= 0;
	else if(w_in_active_flag)
		r_keep_out <= {DATA_BYTE_WD{1'b1}};
	else if( (r_out_cnt == 4) && w_out_active )
//	else if(r_out_cnt == 4)
		r_keep_out <= r_keep1 << ( DATA_BYTE_WD - swar(r_keep_insert) );
	else 
		r_keep_out <= r_keep_out;
end


endmodule


























