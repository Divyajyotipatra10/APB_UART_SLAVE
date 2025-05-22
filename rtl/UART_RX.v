`timescale 1ns / 1ps

module UART_RX(
    input        clk_i,      //AXI Clock
    input        rstn_i,     //Common Reset signal
    input        uart_clk_i, //UART CLock based on selected Baud rate
    input        fifo_F_i,   //RX FIFO Full signal
    input        rx_i,       //RX Input Line
    output [7:0] rx_data_o,  //Data to be written into FIFO
    output [1:0] rx_stat_o,  //RX status for status register
    output       wr_en_o     //Write enable Signal(For One AXI Clock Pulse)
);

localparam UART_IDLE = 0, START = 1, DATA = 3, STOP = 2;
localparam FIFO_IDLE = 0, FIFO_WR = 1, FIFO_BUFF_WR = 3, UART_WAIT = 2;

//reg and wire declarations

reg [1:0] fifo_wr_state = FIFO_IDLE;
reg [1:0] uart_rx_state = UART_IDLE;
reg [7:0] fifo_wr_data  = 0;
reg [7:0] uart_rx_data  = 0;
reg       rx_done       = 0;
reg       wr_en_reg     = 0;
reg [2:0] datacount     = 0;
reg       rx_overrun    = 0;
reg       rx_busy       = 0;

     
//assign statements 
assign rx_stat_o = {rx_overrun,rx_busy};
assign rx_data_o = fifo_wr_data;
assign wr_en_o   = wr_en_reg;
//always blocks
always @(posedge clk_i or negedge rstn_i) begin
    if(rstn_i == 1'b0) begin
        fifo_wr_state <= FIFO_IDLE;
        fifo_wr_data  <= 0;
        wr_en_reg     <= 0;
    end
    else begin
        case(fifo_wr_state)
        FIFO_IDLE: begin
            if(rx_done) fifo_wr_state <= FIFO_WR;
        end
        FIFO_WR: begin
            fifo_wr_data <= uart_rx_data;
            wr_en_reg    <= 1;
            fifo_wr_state<= FIFO_BUFF_WR;
        end
        FIFO_BUFF_WR: begin
            wr_en_reg    <= 0;
            fifo_wr_state<= UART_WAIT;
        end
        UART_WAIT: begin
            if(!rx_done) fifo_wr_state <= FIFO_IDLE;
        end
        default: fifo_wr_state <= FIFO_IDLE;
        endcase
    end
end

always @(posedge uart_clk_i or negedge rstn_i) begin
    if(rstn_i == 1'b0) begin
        uart_rx_state <= UART_IDLE;
        uart_rx_data  <= 0;
        rx_done       <= 0;
        rx_busy       <= 0;
        rx_overrun    <= 0;
    end
    else begin
        case (uart_rx_state)
            UART_IDLE: begin
                if((!rx_i)) begin 
                    rx_done <= 0;
                    if(fifo_F_i) begin
                        rx_overrun    <= 1;
                        uart_rx_state <= UART_IDLE;
                    end
                    else begin
                        rx_busy       <= 1;
                        rx_overrun    <= 0;
                        uart_rx_state <= START;
                    end
                end
            end
            START: begin
                uart_rx_data [6:0] <= uart_rx_data[7:1];
                uart_rx_data [7] <= rx_i;
                uart_rx_state <= DATA;
            end
            DATA: begin
                if(datacount == 7) begin
                    datacount <= 0;
                    uart_rx_state <= STOP;
                    rx_done       <= 1;
                end
                else begin 
                    uart_rx_data [6:0] <= uart_rx_data[7:1];
                    uart_rx_data [7] <= rx_i;
                    datacount <= datacount + 1'b1;
                end
            end
            STOP: begin
                if((!rx_i)) begin 
                    rx_done <= 0;
                    if(fifo_F_i) begin
                        rx_busy       <= 0;
                        rx_overrun    <= 1;
                        uart_rx_state <= UART_IDLE;
                    end
                    else begin
                        rx_overrun    <= 0;
                        uart_rx_state <= START;
                    end
                end
                else begin
                    rx_busy <= 0;
                    uart_rx_state <= UART_IDLE; 
                end
            end 
            default:    uart_rx_state <= UART_IDLE;
        endcase
    end
end
endmodule
