`timescale 1ns / 1ps

module UART_CLK #(
    parameter APB_CLK_FRQ = 100    ////Clock Frequency to be assumed in MHz
)(
    input           clk_i, // Frequency to be same as APB_CLK_FRQ
    input   [2:0]   baud_sel,
    input           rstn_i,
    output          uart_clk_o
);

reg  [31:0] baudcount    = 0;
reg         uart_clk_reg = 0;
reg  [31:0] baudrate_count = 0;

//Calculating permanent Baud rate count various baudrates.
localparam baud4800   = ((APB_CLK_FRQ * 1000000)/ (4800))>> 1'b1;
localparam baud9600   = ((APB_CLK_FRQ * 1000000)/ (9600))>> 1'b1;
localparam baud19200  = ((APB_CLK_FRQ * 1000000)/ (19200))>> 1'b1;
localparam baud38400  = ((APB_CLK_FRQ * 1000000)/ (38400))>> 1'b1;
localparam baud57600  = ((APB_CLK_FRQ * 1000000)/ (57600))>> 1'b1;
localparam baud115200 = ((APB_CLK_FRQ * 1000000)/ (115200))>> 1'b1; 
localparam baud230400 = ((APB_CLK_FRQ * 1000000)/ (230400))>> 1'b1;
localparam baud460800 = ((APB_CLK_FRQ * 1000000)/ (460800))>> 1'b1;


assign uart_clk_o     = uart_clk_reg;

always @(*) begin
    case(baud_sel)
        0: baudrate_count = baud4800;
        1: baudrate_count = baud9600;
        2: baudrate_count = baud19200;
        3: baudrate_count = baud38400;
        4: baudrate_count = baud57600;
        5: baudrate_count = baud115200;
        6: baudrate_count = baud230400;
        7: baudrate_count = baud460800;
        default : baudrate_count = baud115200;
    endcase
end

always @(posedge clk_i)
begin
    if(rstn_i == 1'b0) begin
        baudcount    <= 0;
        uart_clk_reg <= 0;
    end
    else begin
        if (baudcount == baudrate_count - 1) begin
            baudcount <= 0;
            uart_clk_reg <= ~uart_clk_reg;
        end
        else baudcount <= baudcount + 1'b1;
    end 
end
endmodule
