`timescale 1ns/1ps

module APB_Slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH  = 4
)(
    input                     PCLK,           //Global Clock signal for both Master and Slave
    input                     PResetn,        //Global Active low Reset for both Master and Slave
    input  [ADDR_WIDTH-1:0]   PADDR,          //Master to Slave -> For Selecting Particular Address
    input                     PSELx,          //Master to Slave -> Signal to Select this particular Peripheral
    input                     PWRITE,         //Master to Slave -> For Setting up for read or write operation 1->Write 0->Read
    input                     PENABLE,        //Master to Slave -> For Enabling Read and moving into ACCESS state
    input  [DATA_WIDTH/8-1:0] PWSTRB,         //Master to Slave -> For Writing into particular byte of the given register
    input  [DATA_WIDTH-1:0]   PWDATA,         //Master to Slave -> Data to be written in the indicated regsiter(indicated by PADDR)
    output [DATA_WIDTH-1:0]   PRDATA,         //Slave to Master -> Data sent by the slave to the Master
    output                    PREADY,         //Slave to Master -> Indicates completion of Tranfer when High
    output                    PSLVERR,        //Slave to Master -> Indicates if any error occured while Transfer
    
    output [5:0]              uart_ctrl_reg,  //Control reg for Configuring UART 
    output [7:0]              tx_fifo_data,   //DATA to Transmit over UART
    input  [7:0]              rx_fifo_data,   //DATA received over rx line
    input  [7:0]              uart_stat_reg,  //Status of RX/TX FIFO and 
    output                    wren_tx,        //Write Enable for tx 
    output                    rden_rx         //Read Enable for rx
);
//Localparam Declaration
localparam IDLE = 2'b00, SETUP = 2'b01, ACCESS = 2'b10;
localparam FIFO_WRIDLE = 2'b00, FIFO_WR = 2'b01;
localparam FIFO_RDIDLE = 2'b00, FIFO_RD = 2'b01, FIFO_WAIT = 2'b10;
//Localparam Declaration END

//register declaration
reg [ADDR_WIDTH-1:0] p_addr   = 32'd0;            //Register to Latch address
reg [DATA_WIDTH-1:0] p_wdata  = 32'd0;            //Register to Latch wdata
reg [DATA_WIDTH-1:0] p_rdata  = 32'd0;            //Register to write rdata into PRDATA 
reg                  p_ready  = 1'b0;             //Indication for Completion of transfer
reg                  p_slverr = 1'b0;             //Error For Invalid Cases 
reg [1:0]            p_state  = IDLE;             //Operation States variable
reg [1:0]            p_nstate = IDLE;             //NEXT STATE
reg [1:0]            fifo_wr_state = FIFO_WRIDLE; //
reg [1:0]            fifo_rd_state = FIFO_RDIDLE; //
reg                  fifo_rd_done  = 1'b0;        //
reg                  wren_reg      = 1'b0;        //  
reg                  rden_reg      = 1'b0;        //
reg [DATA_WIDTH-1:0] p_mem [0:MEM_DEPTH-1];       //Memory 
integer i = 0;

initial begin
    for(i = 0; i < MEM_DEPTH; i = i + 1) p_mem[i] <= 32'h00000000; 
end
//register declaration END


//Assign Statements
assign PSLVERR = p_slverr;
assign PRDATA  = p_rdata;
assign PREADY  = p_ready;
assign wren_tx = wren_reg;
assign rden_rx = rden_reg;
assign uart_ctrl_reg = p_mem[1][5:0];
assign tx_fifo_data = p_mem[0][7:0];
//Assign Statements END

//Wire
wire   apb_handshake   = PSELx & PENABLE & PREADY;  //Handshake Flag
wire   tx_fifo_wr_flag = (p_addr == 0) & apb_handshake & (!uart_stat_reg[3]); //flag for writing into the tx fifo
wire   rx_fifo_rd_flag = ((PADDR>>2) == 3) & PSELx & PENABLE & (!uart_stat_reg[6]); //flag for reading from rx fifo 
wire   slv_errr = (p_state == SETUP) & (((PADDR>>2)>=MEM_DEPTH)|(PWRITE & ((PADDR>>2)>=2))); //Error Generated Invalid Address or Invalid Write into the Read Only Registers
wire   tx_fifo_full_wait = (((PADDR>>2)==0) & uart_stat_reg[3]);  //Indicates if TX fifo is full
wire   rx_fifo_wait = (!fifo_rd_done & (PADDR >> 2 == 3)); //Indicates if RX fifo is empty
//Always Blocks
always @(posedge PCLK) begin      //Sequential BLock
    if(!PResetn) p_state <= IDLE;
    else         p_state <= p_nstate;
end

always @(posedge PCLK) begin
    if(!PResetn) begin
        fifo_wr_state <= FIFO_WRIDLE;
        wren_reg <= 0;
    end  
    else begin
        case(fifo_wr_state)
        FIFO_WRIDLE: begin
            if(tx_fifo_wr_flag) begin 
                wren_reg <= 1;
                fifo_wr_state <= FIFO_WR;
            end
        end
        FIFO_WR:     begin
            wren_reg <= 0;
            fifo_wr_state <= FIFO_WRIDLE;
        end
        default: fifo_wr_state <= FIFO_WRIDLE;
        endcase
    end
end

always @(posedge PCLK) begin
    if(!PResetn) begin
        fifo_rd_state <= FIFO_RDIDLE;
        rden_reg <= 0;
        fifo_rd_done <= 0;
    end
    else begin
        case(fifo_rd_state)
        FIFO_RDIDLE: begin
            fifo_rd_done <= 0;
            if(rx_fifo_rd_flag) begin
                rden_reg <= 1;
                fifo_rd_state <= FIFO_RD;
            end 
        end
        FIFO_RD: begin
            rden_reg <= 0;
            fifo_rd_state <= FIFO_WAIT;
        end
        FIFO_WAIT: begin
            if(apb_handshake) begin
                fifo_rd_done <= 0;
                fifo_rd_state <= FIFO_RDIDLE;
            end
            else    fifo_rd_done <= 1; 
        end
        default: fifo_rd_state <= FIFO_RDIDLE;
        endcase
    end
end

always @(posedge PCLK) begin
    if(!PResetn) begin
        p_slverr <= 0;
        p_addr   <= 0;
        p_wdata  <= 0;
        p_rdata  <= 0;
        p_ready  <= 0;
    end
    else begin
        p_mem[2][7:0] <= uart_stat_reg;
        p_mem[3][7:0] <= rx_fifo_data;
        case(p_state)
            SETUP: begin
                if(PSELx & PENABLE) begin
                    p_addr   = PADDR >> 2 ; //Latching Word ADDRESS
                
                    if(slv_errr) p_slverr = 1; //Only generates error when the address is invalid
                    else         p_slverr = 0;
                
                    if(PWRITE) begin    //Write Txn
                        p_wdata  = PWDATA;      //Latching WDATA
                        if(tx_fifo_full_wait) p_ready <= 0;
                        else p_ready  = 1;           //For completion of transfer   //No wait states
                    end
                    else begin          //read txn
                        p_rdata  = p_mem[PADDR >> 2];
                        if(rx_fifo_wait) p_ready <= 0;
                        else p_ready  = 1;           //For completion of transfer   //No wait states
                    end
                end
            end 
            ACCESS: begin
                if(PSELx & PENABLE & PREADY) begin 
                    if(PWRITE & (p_addr < 2)) begin
                        for(i = 0; i<(DATA_WIDTH/8);  i = i+1) begin
                            if(PWSTRB[i]) p_mem[p_addr][(8*i)+:8] <= p_wdata[(8*i)+:8];
                        end
                    end
                    p_ready <= 0;
                end
                else begin
                    if(PWRITE) begin
                        if(tx_fifo_full_wait) p_ready <= 0;
                        else p_ready <= 1;
                    end
                    else begin
                        if(fifo_rd_done) begin
                            p_rdata <= p_mem[p_addr];
                            p_ready <= 1;
                        end
                        else p_ready <= 0;
                    end
                end
            end
            default: begin
                p_slverr <= p_slverr;
                p_addr   <= p_addr;
                p_wdata  <= p_wdata;
                p_rdata  <= p_rdata;
                p_ready  <= p_ready;
            end
        endcase
    end
end

always @(*) begin                 //Combinational Block
        case(p_state)
        IDLE:   begin
            if(PSELx) p_nstate = SETUP;  //Transfer Detected
            else      p_nstate = IDLE; 
        end
        SETUP:  begin
            if(!PSELx)                p_nstate = IDLE;   //Transfer Aborted
            else if(PSELx & !PENABLE) p_nstate = SETUP;  //Delayed PENABLE
            else if(PSELx & PENABLE)  p_nstate = ACCESS; //ACCEPT the Data
            else                      p_nstate = SETUP;
        end
        ACCESS: begin
            if(PSELx & !PENABLE) p_nstate = SETUP;  //back to back transmission
            else                 p_nstate = IDLE;   //No Transfer Detected, back to IDLE        
        end
        default: p_nstate = IDLE;
    endcase
end
//Always Blocks END
endmodule