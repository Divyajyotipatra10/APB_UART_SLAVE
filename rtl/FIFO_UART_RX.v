`timescale 1ns / 1ps

module FIFO_UART_RX#(
    parameter FIFO_DEPTH  = 10,     // FIFO Depth considered to be 10
    localparam DATA_WIDTH = 8  // Data Width of 8 bits
)
(
    input                   clk_i,              // AXI Clock
    input                   rstn_i,             // Active Low Reset
    input                   rden_i,             // Write Enable Signal
    input                   uart_clk_i,
    input                   rx_i,
    output [DATA_WIDTH-1:0] rd_data_o,          // Data to be written to RX FIFO
    output [3:0]            fifo_uart_rx_stat
);

//Wire declarations
wire [DATA_WIDTH-1:0] rx_data_uart; // Data read from FIFO to tx_data in UART
wire                  wr_en_uart;   // Read Enable Signal for FIFO  
wire    [1:0]         rx_stat_wire;
wire                  rx_buff_full_o,rx_buff_empty_o;

//assign statements
assign fifo_uart_rx_stat = {rx_buff_full_o,rx_buff_empty_o,rx_stat_wire};
//Module Instantiations
FIFO_ALL #(
    .DATA_WIDTH(DATA_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
) RX_FIFO_INST(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wren_i(wr_en_uart),
    .rden_i(rden_i),
    .wr_data_i(rx_data_uart),
    .rd_data_o(rd_data_o), // Data read from FIFO
    .full_o(rx_buff_full_o),
    .empty_o(rx_buff_empty_o)
);

UART_RX RX_Module(
    .clk_i(clk_i),
    .uart_clk_i(uart_clk_i),
    .rstn_i(rstn_i),
    .rx_i(rx_i),
    .rx_data_o(rx_data_uart),
    .wr_en_o(wr_en_uart),
    .rx_stat_o(rx_stat_wire),
    .fifo_F_i(rx_buff_full_o)
);
endmodule
