`timescale 1ns / 1ps

module UART_Module#(
    parameter APB_CLK_FRQ = 100, //Value Considered to be in MHz
    parameter TX_FIFO_DEPTH  = 50,
    parameter RX_FIFO_DEPTH  = 50,
    localparam DATA_WIDTH = 8
)(
    input                   clk,
    input                   rstn,
    input                   wren,             //Write enable for tx fifo
    input                   rden,             //read enable for rx fifo
    input       [5:0]       uart_ctrl_reg,    //Control register
    input [DATA_WIDTH-1:0]  tx_data,          //Data To be transmitted over Tx line of UART(Goes into FIFO)
    output[DATA_WIDTH-1:0]  rx_data,          //Data received over the rx line and read from rx FIFO
    output      [7:0]       uart_status,      //Status register
    
    input                   rx,               //UART RX Line
    output                  tx                //UART TX Line
);
//Wire Definitions
wire        uart_clk_wire;
wire        rx_wire;
wire   [3:0]rx_stat, tx_stat;

assign rx_wire = (uart_ctrl_reg[5] == 1)? tx : rx ;
assign uart_status = {rx_stat,tx_stat};
//Module Instantiations

UART_CLK #(
    .APB_CLK_FRQ(APB_CLK_FRQ) 
)
BAUDCLK(
    .clk_i(clk),
    .rstn_i(rstn),
    .baud_sel(uart_ctrl_reg[4:2]),
    .uart_clk_o(uart_clk_wire)
);

FIFO_UART_TX #(.FIFO_DEPTH(TX_FIFO_DEPTH))
TX_BUFFER(
    .clk_i(clk),
    .rstn_i(rstn),
    .wren_i(wren),
    .uart_clk_i(uart_clk_wire),
    .tx_en_i(uart_ctrl_reg[0]),
    .wr_data_i(tx_data),
    .fifo_uart_tx_stat(tx_stat),
    .tx_o(tx)
);

FIFO_UART_RX #(.FIFO_DEPTH(RX_FIFO_DEPTH))
RX_BUFFER(
    .clk_i(clk),
    .rstn_i(rstn),
    .rden_i(rden),
    .uart_clk_i(uart_clk_wire),
    .rx_i(rx_wire),
    .rd_data_o(rx_data),
    .fifo_uart_rx_stat(rx_stat)
);
endmodule
