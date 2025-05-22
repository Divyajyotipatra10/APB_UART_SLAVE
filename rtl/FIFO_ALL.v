`timescale 1ns / 1ps

module FIFO_ALL #(
    parameter   DATA_WIDTH = 8,
    parameter   FIFO_DEPTH = 50
)
(
    input                       clk_i,
    input                       rstn_i,
    input                       wren_i,
    input                       rden_i,
    input   [DATA_WIDTH-1:0]    wr_data_i,
    output  [DATA_WIDTH-1:0]    rd_data_o,
    output                      full_o,
    output                      empty_o
    );
    localparam  ADDR_WIDTH = $clog2(FIFO_DEPTH + 1);

    /*Required Wire Declarations*/
    wire [ADDR_WIDTH-1:0]   wr_ptr_buf ;
    wire [ADDR_WIDTH-1:0]   rd_ptr_buf ;

    wire [ADDR_WIDTH:0]     wr_ptr_rd ;
    wire [ADDR_WIDTH:0]     rd_ptr_wr ; 
    
    wire    wren_buff;
    wire    rden_buff;
    
    assign wren_buff = wren_i & ~full_o;
    assign rden_buff = rden_i & ~empty_o;
    /*Required Wire Declarations END*/

    /*Module Instances*/
    FIFO_BUFF #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    )Buffer(
        .clkw_i(clk_i),
        .clkr_i(clk_i),
        .rstn_i(rstn_i),
        .wren_i(wren_buff),
        .rden_i(rden_buff),
        .wr_buf_i(wr_data_i),
        .wr_ptr_i(wr_ptr_buf),
        .rd_ptr_i(rd_ptr_buf),
        .rd_buf_o(rd_data_o)
    );

    FIFO_WR #(
        .FIFO_DEPTH(FIFO_DEPTH)
    )Write_module(
        .clkw_i(clk_i),
        .rstn_i(rstn_i),
        .rd_ptr_i(rd_ptr_wr),
        .wren_i(wren_i),
        .wr_ptr_o(wr_ptr_rd), //wr_ptr_before Synchronisation
        .wr_ptr_buff_o(wr_ptr_buf),
        .full_o(full_o)
    );

    FIFO_RD #(
        .FIFO_DEPTH(FIFO_DEPTH)
    )Read_module(
        .clkr_i(clk_i),
        .rstn_i(rstn_i),
        .wr_ptr_i(wr_ptr_rd),
        .rden_i(rden_i),
        .rd_ptr_o(rd_ptr_wr),
        .rd_ptr_buff_o(rd_ptr_buf),
        .empty_o(empty_o)
    );

    /*Module Instances END*/
endmodule
