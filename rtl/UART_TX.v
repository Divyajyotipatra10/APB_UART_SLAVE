`timescale 1ns / 1ps

module UART_TX(
    input       clk_i,          //ORIGINAL AXI CLOCK
    input       rstn_i,         //ACTIVE LOW Reset
    input       uart_clk_i,     //UART BAUDCLK
    input [7:0] tx_data_i,      //Data Read From FIFO
    input       tx_en_i,        //TX ENABLE from CTRL REGISTER AXI
    input       fifo_E_i,       //Not Gated FIFO Empty Condition
    output      rd_en_o,        //RD EN for reading from FIFO
    output[1:0] tx_stat_o,    //Current status of UART TX Module
    output      tx_o            //UART TX Line for Final Output.
);
localparam UART_IDLE = 0, START = 1, DATA = 3, STOP = 2;
localparam FIFO_IDLE = 0, FIFO_RD = 1, TX_BUFF_WRITE = 3, UART_TX = 2;

//reg and wire declarations

reg [1:0]fifo_rd_state = FIFO_IDLE; //State Variable for FIFO RD
reg [1:0]uart_tx_state = UART_IDLE; //State Variable for UART TX
reg [7:0]fifo_rd_data  = 0;
reg [7:0]uart_tx_data  = 0;
reg      rd_en_reg     = 0;
reg      tx_reg        = 1;
reg      tx_done       = 0;    //Signal For handshaking
reg [2:0]datacount     = 0;
reg      tx_busy       = 0;
//assign statements
assign tx_o     = tx_reg;
assign rd_en_o  = rd_en_reg;
assign tx_stat_o = {tx_done,tx_busy};

//always blocks
always @(posedge clk_i or negedge rstn_i) begin
    if(rstn_i == 1'b0) begin
        fifo_rd_state <= FIFO_IDLE;
        fifo_rd_data  <= 0;
        rd_en_reg     <= 0;
    end
    else begin
        case (fifo_rd_state)
            FIFO_IDLE: begin
                if((!tx_done) && (tx_en_i) && (!fifo_E_i) ) fifo_rd_state <= FIFO_RD;
            end
            FIFO_RD: begin
                rd_en_reg     <= 1;                        // RD_EN made High for 1 AXI Clock Cycle
                fifo_rd_state <= TX_BUFF_WRITE;
            end
            TX_BUFF_WRITE: begin
                rd_en_reg     <= 0;
                fifo_rd_state <= UART_TX;
            end
            UART_TX: begin                              // Need to put a counter so It doesn't automatically Read again from FIFO until UART read is complete
                fifo_rd_data  <= tx_data_i;
                if(tx_done == 1) fifo_rd_state <= FIFO_IDLE;
            end
            default: fifo_rd_state <= FIFO_IDLE;
        endcase
    end
end

always @(posedge uart_clk_i or negedge rstn_i) begin
    if(rstn_i == 1'b0) begin
        uart_tx_state <= UART_IDLE;
        uart_tx_data  <= 0;
        tx_reg        <= 1;
        tx_done       <= 0;
        tx_busy       <= 0;
    end
    else begin
        case (uart_tx_state)
            UART_IDLE: begin
                if((tx_en_i) && (!fifo_E_i)) begin
                    uart_tx_state <= START;
                    tx_reg <= 0; //Start Bit
                    tx_busy <= 1;
                end
                else tx_busy <= 0;
            end 
            START: begin
                tx_done      <= 0;
                tx_reg       <= fifo_rd_data[0];
                uart_tx_data <= {1'b0,fifo_rd_data[7:1]};
                uart_tx_state<= DATA;
            end
            DATA : begin
                if(datacount == 7) begin
                    tx_done         <=     1;
                    tx_reg          <=     1;
                    datacount       <=     0;
                    uart_tx_state   <=  STOP;
                end
                else begin
                    datacount         <= datacount + 1;
                    uart_tx_data[6:0] <= uart_tx_data[7:1]; 
                    tx_reg            <= uart_tx_data[0];
                end
            end
            STOP : begin
                if((tx_en_i) && (!fifo_E_i)) begin
                    tx_done         <=  0;
                    uart_tx_state   <=  START;
                    tx_reg          <=  0;
                end 
                else begin
                    tx_busy <= 0;
                    uart_tx_state   <=  UART_IDLE;
                end
            end
            default: uart_tx_state <= UART_IDLE;
        endcase
    end
end
endmodule
