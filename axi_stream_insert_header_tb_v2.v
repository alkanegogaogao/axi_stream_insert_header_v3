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
// Revision:     v0.2
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module axi_stream_insert_header_tb();


parameter DATA_WD 		= 32					;
parameter DATA_BYTE_WD 	= DATA_WD / 8			;
parameter BYTE_CNT_WD 	= $clog2(DATA_BYTE_WD)	;

reg 						clk					;
reg 						rst_n				;
// AXI Stream input original data
reg 						valid_in			;
reg [DATA_WD-1 : 0] 		data_in				;
reg [DATA_BYTE_WD-1 : 0] 	keep_in				;
reg 						last_in				;
wire 						ready_in			;
// AXI Stream output with header inserted
wire 						valid_out			;
wire [DATA_WD-1 : 0] 		data_out			;
wire [DATA_BYTE_WD-1 : 0] 	keep_out			;
wire 						last_out			;
reg 						ready_out			;
// The header to be inserted to AXI Stream input
reg 						valid_insert		;
reg [DATA_WD-1 : 0] 		data_insert			;
reg [DATA_BYTE_WD-1 : 0] 	keep_insert			;
reg	[BYTE_CNT_WD-1 : 0]		byte_insert_cnt		;
wire 						ready_insert		;
reg	[4:0]					r_valid_in_cnt		;

initial begin
	clk = 1'b0						;
	rst_n = 1'b0					;
	valid_insert = 1'b0				;
	keep_in={DATA_BYTE_WD{1'b1}}	;
	#20
	rst_n = 1'b1					;
	#20
	valid_insert = 1'b1				;
	//#10
	//valid_insert = 1'b0;
end

always #10 clk = ~clk;

/****************************************************/
//insert
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        data_insert <= {$random}%2**(DATA_WD-1);
    else if(valid_insert && ready_insert)
        data_insert <= {$random}%2**(DATA_WD-1);    
	else 
		data_insert <= data_insert;
end

reg [BYTE_CNT_WD:0]num;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
//		num ={$random}%DATA_BYTE_WD;
        keep_insert <= ( {DATA_BYTE_WD{1'b1}} >> {$random}%DATA_BYTE_WD );
	end
    else if(valid_insert && ready_insert)begin
//		num =({$random}%DATA_BYTE_WD) + 1;
        keep_insert <= ( {DATA_BYTE_WD{1'b1}} >> {$random}%DATA_BYTE_WD );  
	end
	else 
		keep_insert <= keep_insert;
end

//always@(posedge clk or negedge rst_n)begin
//    if(!rst_n)
//        keep_insert <= {$random}%2**(DATA_BYTE_WD-1);
//    else if(valid_insert && ready_insert)
//        keep_insert <= {$random}%2**(DATA_BYTE_WD-1);    
//	else 
//		keep_insert <= keep_insert;
//end

reg [3:0] r_vinsert_interval;
always@(posedge clk)begin
    if(valid_insert && ready_insert)
		valid_insert <= 1'b0;
    else if(last_in)begin
		r_vinsert_interval = {$random}%10;
		repeat (r_vinsert_interval+1)@(posedge clk);
		valid_insert <= 1'b1;
//		repeat (1) @(posedge clk);
//		valid_insert <= 1'b0;
	end
	else 
		valid_insert <= valid_insert;
end

//in
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        r_valid_in_cnt <= 0;
    else if(valid_in && ready_in && ~last_in)
        r_valid_in_cnt <= r_valid_in_cnt + 1;
	else if(last_in)
		r_valid_in_cnt <= 0;
	else 
		r_valid_in_cnt <= r_valid_in_cnt;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        data_in <= 0;
    else 
        data_in <= {$random}%2**(DATA_WD-1);    
end


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        last_in <= 1'b0;
    else if(r_valid_in_cnt == 'd3)
        last_in <= 1'b1;
	else 
		last_in <= 1'b0;
end

reg [3:0] r_vin_interval;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        valid_in <= 1'b0;
    else if(valid_insert && ready_insert)begin
		r_vin_interval <= {$random}%10;
		repeat (r_vin_interval+1) @(posedge clk);
		valid_in <= 1'b1;
	end
	else if(last_in)
		valid_in <= 1'b0;
end


//out
reg [3:0] r_rout_interval;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n || last_out)
        ready_out <= 1'b0;
	else begin
        r_rout_interval <= {$random}%10 + 1;
        repeat (r_rout_interval)@(posedge clk);
		ready_out <= 1'b1;
    end
end
//always@(posedge clk or negedge rst_n)begin
//    if(!rst_n)
//        ready_out <= 1'b0;
//    else if(valid_insert && ready_insert)
//		ready_out <= 1'b1;
//	else if(last_out)
//		ready_out <= 1'b0;
//	else
//		ready_out <= ready_out;
//end

/****************************************************/
//计算二进制位宽
function integer clog2(input integer number);
begin
	for(clog2 = 0 ; number > 0 ; clog2 = clog2 + 1)
		number = number << 1;
end
endfunction

axi_stream_insert_header
#(
	.DATA_WD 				(DATA_WD		)	,
	.DATA_BYTE_WD 			(DATA_BYTE_WD	)	,
	.BYTE_CNT_WD 			(BYTE_CNT_WD	)	
)	
axi_stream_insert_header_inst(	
	.clk					(clk			)	,
	.rst_n					(rst_n			)	,
	.valid_in				(valid_in		)	,
	.data_in				(data_in		)	,
	.keep_in				(keep_in		)	,
	.last_in				(last_in		)	,
	.ready_in				(ready_in		)	,
	.valid_out				(valid_out		)	,
	.data_out				(data_out		)	,
	.keep_out				(keep_out		)	,
	.last_out				(last_out		)	,
	.ready_out				(ready_out		)	,
	.valid_insert			(valid_insert	)	,
	.data_insert			(data_insert	)	,
	.keep_insert			(keep_insert	)	,
	.byte_insert_cnt		(byte_insert_cnt)	,
	.ready_insert			(ready_insert	)
);

endmodule