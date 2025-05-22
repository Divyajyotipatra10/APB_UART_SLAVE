`timescale 1ns / 1ps

module APB_UART#(
    parameter MOD_CLK_FRQ   = 100, //In MHz
    parameter DATA_WIDTH    = 32,
    parameter ADDR_WIDTH    = 32,
    parameter MEM_DEPTH     = 4,
    parameter TX_FIFO_DEPTH = 5,
    parameter RX_FIFO_DEPTH = 5
)(
    input                        PCLK,       //Global Clock signal for both Master and Slave
    input                        PResetn,    //Global Active low Reset for both Master and Slave
    input  [ADDR_WIDTH-1:0]      PADDR,      //Master to Slave -> For Selecting Particular Address
    input                        PSELx,      //Master to Slave -> Signal to Select this particular Peripheral
    input                        PWRITE,     //Master to Slave -> For Setting up for read or write operation 1->Write 0->Read
    input                        PENABLE,    //Master to Slave -> For Enabling Read and moving into ACCESS state
    input  [DATA_WIDTH/8-1:0]    PWSTRB,     //Master to Slave -> For Writing into particular byte of the given register
    input  [DATA_WIDTH-1:0]      PWDATA,     //Master to Slave -> Data to be written in the indicated regsiter(indicated by PADDR)
    output [DATA_WIDTH-1:0]      PRDATA,     //Slave to Master -> Data sent by the slave to the Master
    output                       PREADY,     //Slave to Master -> Indicates completion of Tranfer when High
    output                       PSLVERR,    //Slave to Master -> Indicates if any error occured while Transfer

    input                        RX,         //UART RX Line
    output                       TX          //UART TX Line
);

//Wire Declarations
wire [5:0]              uart_ctrl_reg;
wire [7:0]              tx_fifo_data;
wire [7:0]              rx_fifo_data; 
wire [7:0]              uart_stat_reg;
wire                    wren_wire;      
wire                    rden_wire;       
//Wire Declarations END

//Module Instantiations
APB_Slave #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .MEM_DEPTH(MEM_DEPTH)
)APB_MOD(
    .PCLK(PCLK),         
    .PResetn(PResetn),      
    .PADDR(PADDR),        
    .PSELx(PSELx),        
    .PWRITE(PWRITE),       
    .PENABLE(PENABLE),      
    .PWSTRB(PWSTRB),       
    .PWDATA(PWDATA),       
    .PRDATA(PRDATA),       
    .PREADY(PREADY),       
    .PSLVERR(PSLVERR),               
    .uart_ctrl_reg(uart_ctrl_reg),
    .tx_fifo_data(tx_fifo_data), 
    .rx_fifo_data(rx_fifo_data), 
    .uart_stat_reg(uart_stat_reg),
    .wren_tx(wren_wire),      
    .rden_rx(rden_wire)       
);

UART_Module #(
    .APB_CLK_FRQ(MOD_CLK_FRQ),
    .TX_FIFO_DEPTH(TX_FIFO_DEPTH),
    .RX_FIFO_DEPTH(RX_FIFO_DEPTH)
)UART_FIFO(
    .clk(PCLK),          
    .rstn(PResetn),         
    .wren(wren_wire),         
    .rden(rden_wire),         
    .uart_ctrl_reg(uart_ctrl_reg),
    .tx_data(tx_fifo_data),      
    .rx_data(rx_fifo_data),      
    .uart_status(uart_stat_reg),             
    .rx(RX),           
    .tx(TX)            
);
//Module Instantiations END
endmodule
