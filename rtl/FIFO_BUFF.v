`timescale 1ns / 1ps
module FIFO_BUFF#(
    parameter   DATA_WIDTH = 8,
    parameter   FIFO_DEPTH = 50,
    localparam  ADDR_WIDTH = $clog2(FIFO_DEPTH + 1)
)
(
    input                   clkw_i,
    input                   clkr_i,
    input                   rstn_i,
    input                   wren_i,
    input                   rden_i,
    input  [DATA_WIDTH-1:0] wr_buf_i,
    input  [ADDR_WIDTH-1:0] wr_ptr_i,
    input  [ADDR_WIDTH-1:0] rd_ptr_i,
    output [DATA_WIDTH-1:0] rd_buf_o
);
//Registers and Buffer
reg [DATA_WIDTH-1:0] Fifo_buff [0:FIFO_DEPTH-1];
reg [DATA_WIDTH-1:0] rd_buf_reg = 0;
integer i = 0;
initial begin
    for(i = 0;i<FIFO_DEPTH;i=i+1)    Fifo_buff[i] = {DATA_WIDTH{1'b0}}; //Initialisation
end

//Assign statement
assign rd_buf_o = rd_buf_reg;

//Always Blocks
always @(posedge clkw_i) begin
    if(wren_i)      Fifo_buff[wr_ptr_i] <= wr_buf_i;
end

always @(posedge clkr_i) begin
    if(rstn_i == 1'b0)  rd_buf_reg <= {DATA_WIDTH{1'b0}};
    else begin   
        if(rden_i)   rd_buf_reg <= Fifo_buff[rd_ptr_i];
        else         rd_buf_reg <= rd_buf_reg; 
    end
end
endmodule
