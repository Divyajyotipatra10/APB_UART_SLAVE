`timescale 1ns / 1ps
module apb_uart_tb; //A Loopback Test // Configured through UART CTRL Register
//DUT Variables
localparam DATA_WIDTH = 32, ADDR_WIDTH = 32, MOD_CLK_FRQ = 100, MEM_DEPTH = 4;
localparam TX_FIFO_DEPTH = 5, RX_FIFO_DEPTH = 5;
reg CLK, RESETn; //Global Variables
reg SELx,ENABLE,WRITE; //Single Bit Master to Slave Signals
reg [ADDR_WIDTH-1:0] ADDR; //Address Bus -> Master to Slave
reg [DATA_WIDTH/8-1:0] WSTRB; //Write Strobe -> Master to Slave
reg [DATA_WIDTH-1:0] WDATA; //Write Data -> Master to Slave

wire [DATA_WIDTH-1:0] RDATA; //Read Data -> Slave to Master
wire READY, SLVERR; //Single Bit Slave to Master signals

reg  RX = 1; //UART RX LINE //will remain unused for the internal
wire TX; //UART TX LINE
//DUT Variables END

//testbench manager varaibles
localparam WRITE_CTRL_REG_1 = 0,WRITE_CTRL_REG_2 = 1;
localparam TX_DATA_WRITE = 2, TX_DATA_WRITE_DONE = 3;
localparam RD_UART_STATUS = 4, RD_UART_STATUS_2 = 5;
localparam RD_WAIT = 6, RX_DATA_READ_1 = 7, RX_DATA_READ_2=8;
localparam TXN_COMPLETE = 9; 

reg [3:0] COMPLETE_TXN = 0;  //State variable for Writing Control register and Data into TX fifo for transmission
//reg [2:0] STATUSCHK  = 0;  //State variable for checking the status of RX FIFO. ONCE FULL we can initiate read Transaction
//reg [1:0] DATA_READ  = 0;  //State variable for Reading Values from the RX FIFO
reg [7:0] TX_DATA_LIST [0:4]; //Storing the data sent
reg [7:0] RX_DATA_LIST [0:4]; //Storing the data received and compare it with sent data
reg [2:0] tx_count   = 0; //Counter for managing Write count
reg [2:0] rx_count   = 0; //Counter for managing Read  count
reg [2:0] compare_count = 0; //Final Comparision Count
reg       read_done    = 0; //Flag for indicating Read Operation's Completion
reg       write_done   = 0; //Flag for indicating Write Operation 's Completion
reg [7:0] wait_count   = 0; //A Wait counter for waiting between consecutive status register read operation
reg [7:0] end_count    = 0; //Final Counter before ending the simulation
integer i = 0; 
//testbench manager variables end

//Module Instantiation
APB_UART #(
    .MOD_CLK_FRQ(MOD_CLK_FRQ),
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .MEM_DEPTH(MEM_DEPTH),
    .TX_FIFO_DEPTH(TX_FIFO_DEPTH),
    .RX_FIFO_DEPTH(RX_FIFO_DEPTH)
)LOOPBACK_APBUART(
    .PCLK(CLK),
    .PResetn(RESETn),
    .PADDR(ADDR),
    .PSELx(SELx),
    .PWRITE(WRITE),
    .PENABLE(ENABLE),
    .PWSTRB(WSTRB),
    .PWDATA(WDATA),
    .PRDATA(RDATA),
    .PREADY(READY),
    .PSLVERR(SLVERR),
    .RX(RX),  //This RX won't be utilised as this is a loopback test
    .TX(TX)
);
//Module Instantiation ENDS
//The internally adjusts for Loopback test by assigning tx line to rx internally instead of relying on external rx input.

//INITIAL BLOCKS
initial begin  //Initialising all the possible registers
    {CLK,RESETn,SELx,ENABLE,WRITE,WSTRB} = 0; //Reseting the System by making RESETn 0(ACTIVE LOW Reset)
    ADDR = 0; WDATA = 0;
    for(i = 0; i<TX_FIFO_DEPTH; i = i + 1) begin
        TX_DATA_LIST[i] = 0;
        RX_DATA_LIST[i] = 0;
    end

    #105;
    
    RESETn = 1; //Deasserting Reset.
end
//INITIAL BLOCKS END

always #5 CLK <= ~CLK;

//Always Blocks For DUT
always @(posedge CLK) begin  //DATA WRITE
    if(!RESETn) begin
        COMPLETE_TXN <= WRITE_CTRL_REG_1;
        write_done <= 0; read_done <= 0;
    end 
    else begin
        case(COMPLETE_TXN)
        WRITE_CTRL_REG_1: begin
            ADDR  <= 4;  //Control Reg address
            WDATA <= 32'b0000_0000_0000_0000_0000_0000_0011_0101; //Setting Up Loopback Test, baudrate set to 115200, Enabled UART TX            
            SELx  <= 1;
            WSTRB <= 4'b0001;
            ENABLE<= 0;
            WRITE <= 1;
            COMPLETE_TXN <= WRITE_CTRL_REG_2;
        end
        WRITE_CTRL_REG_2: begin
            if(SELx & ENABLE & READY) begin //APB Handshake
                ADDR <= 0; //TX_FIFO Register
                WDATA[7:0] <= $urandom();
                WSTRB <= 4'b0001; //Write the Lowest Byte
                ENABLE <= 0;
                COMPLETE_TXN <= TX_DATA_WRITE;
            end
            else ENABLE <= 1;
        end
        TX_DATA_WRITE: begin
            if(SELx & ENABLE & READY) begin //APB Handshake
                ADDR <= 0; //TX_FIFO Register
                WDATA[7:0] <= $urandom();
                WSTRB <= 4'b0001; //Write the Lowest Byte
                ENABLE <= 0;
                tx_count <= tx_count + 1;
                TX_DATA_LIST[tx_count] <= WDATA[7:0];
                if((tx_count + 1)==5) begin
                    SELx <= 0;
                    COMPLETE_TXN <= TX_DATA_WRITE_DONE;
                    WRITE <= 0;    
                end
                else begin
                    SELx <= 1;
                end
            end
            else ENABLE <= 1;
        end
        TX_DATA_WRITE_DONE: begin
            write_done <= 1;
            COMPLETE_TXN <= RD_UART_STATUS;
        end
        RD_UART_STATUS: begin
            ADDR <= 8; //Checking the UART STATUS Register
            WRITE <= 0; //Read data from register
            SELx <= 1; //Select the peripheral
            ENABLE <= 0;
            COMPLETE_TXN <= RD_UART_STATUS_2;
        end
        RD_UART_STATUS_2: begin
            if(SELx & ENABLE & READY) begin
                ENABLE <= 0;
                SELx <= 0;
                if(RDATA[7]) COMPLETE_TXN <= RX_DATA_READ_1; //Indicates RX_FIFO FULL
                else COMPLETE_TXN <= RD_WAIT;
            end
            else ENABLE <= 1;
        end
        RD_WAIT: begin
            if(wait_count == 19) begin
                wait_count <= 0;
                COMPLETE_TXN <= RD_UART_STATUS;
            end
            else wait_count <= wait_count + 1;
        end
        RX_DATA_READ_1: begin
            ADDR <= 12; //Address for Reading Data from 
            WRITE <= 0; //Read data from register
            SELx <= 1; //Select the peripheral
            ENABLE <= 0;
            COMPLETE_TXN <= RX_DATA_READ_2;
        end
        RX_DATA_READ_2: begin
            if(SELx & ENABLE & READY) begin
                RX_DATA_LIST[rx_count] <= RDATA[7:0];
                ENABLE <= 0;
                rx_count <= rx_count + 1;
                if(rx_count + 1 == 5) begin
                    SELx <= 0;
                    COMPLETE_TXN <= TXN_COMPLETE;
                end
                else SELx <= 1;
            end
            else ENABLE <= 1;
        end
        TXN_COMPLETE: begin
            COMPLETE_TXN <= TXN_COMPLETE;
            read_done <= 1;
        end
        default: COMPLETE_TXN <= WRITE_CTRL_REG_1;
        endcase
    end
end


always @(posedge CLK) begin  //Always Block for comparing the TX DATA & RX DATA
    if(!RESETn) begin
        compare_count <= 0;
    end
    else begin
        if(read_done) begin
            if(compare_count <= 4) begin
                if(TX_DATA_LIST[compare_count] == RX_DATA_LIST[compare_count]) begin
                    $display("TX = %b || RX = %b",TX_DATA_LIST[compare_count],RX_DATA_LIST[compare_count]);
                    compare_count <= compare_count + 1;
                end
                else begin
                    $display("TX != RX at index  %0d", compare_count);
                    $finish;
                end    
            end
            else begin
                if(end_count<100) end_count <= end_count + 1;
                else begin
                    $display("TX Data Matches RX Data, Loopback Test Successful\n");
                    $finish;
                end
            end
        end
        else begin
            compare_count <= 0;
        end
    end
end
//Always Blocks For DUT end

endmodule
