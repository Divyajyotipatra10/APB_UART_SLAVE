`timescale 1ns / 1ps

module FIFO_UART_TX#(
    parameter FIFO_DEPTH  = 10,     // FIFO Depth considered to be 10
    localparam DATA_WIDTH = 8  // Data Width of 8 bits
)
(
    input                   clk_i,           // AXI Clock
    input                   rstn_i,          // Active Low Reset
    input                   wren_i,          // Write Enable Signal
    input                   uart_clk_i,      // UART Baudclock
    input                   tx_en_i,         // TX Enable from Control register
    input [DATA_WIDTH-1:0]  wr_data_i,       // Data to be written to TX FIFO
    output                  tx_o,            // UART TX Line for Final Output
    output  [3:0]           fifo_uart_tx_stat// UART FIFO for STAT  
);

//Wire declarations
wire [DATA_WIDTH-1:0] tx_data_uart; // Data read from FIFO to tx_data in UART
wire                  rd_en_uart;   // Read Enable Signal for FIFO 
wire  [1:0]           tx_stat_wire; //uart tx stat 
wire tx_buff_full_o,tx_buff_empty_o;
//assign statement

assign fifo_uart_tx_stat = {tx_buff_full_o,tx_buff_empty_o,tx_stat_wire};

//Module Instantiations
FIFO_ALL #(
    .DATA_WIDTH(DATA_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
) TX_FIFO_INST(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wren_i(wren_i),
    .rden_i(rd_en_uart),
    .wr_data_i(wr_data_i),
    .rd_data_o(tx_data_uart), // Data read from FIFO
    .full_o(tx_buff_full_o),
    .empty_o(tx_buff_empty_o)
);

UART_TX TX_Module(
    .clk_i(clk_i),
    .uart_clk_i(uart_clk_i),
    .rstn_i(rstn_i),
    .tx_data_i(tx_data_uart),
    .tx_en_i(tx_en_i),
    .rd_en_o(rd_en_uart),
    .tx_o(tx_o),
    .fifo_E_i(tx_buff_empty_o),
    .tx_stat_o(tx_stat_wire)
);
endmodule
