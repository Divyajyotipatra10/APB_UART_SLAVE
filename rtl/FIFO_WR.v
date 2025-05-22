`timescale 1ns / 1ps

module FIFO_WR#(
    parameter   FIFO_DEPTH = 50, //Can Be Any Number
    localparam  ADDR_WIDTH = $clog2(FIFO_DEPTH + 1) // To be changed as per requirement
)
(
    input                    clkw_i,            
    input                    rstn_i,
    input   [ADDR_WIDTH:0]   rd_ptr_i, // Synchronised Signal Coming from two flop synchronisers and through gray to binary counters
    input                    wren_i,
    output  [ADDR_WIDTH:0]   wr_ptr_o,
    output  [ADDR_WIDTH-1:0] wr_ptr_buff_o,  // Buffer gets the Actual address where data will be stored(No need to send MSB)               
    output                   full_o
    );

    // Wire and Register Definitions
    /*WR_PTR Signals*/
    wire   [ADDR_WIDTH-1:0] wr_ptr_nxt;
    wire   [ADDR_WIDTH-1:0] wr_ptr_up ;
    wire                    wr_mod    ; //For Any depth, Used Mod Counter based pointers
    wire                    wr_msb    ; 
    wire                    wr_toggle_msb;//Toggling The MSB
    reg    [ADDR_WIDTH-1:0] wr_ptr_reg = 0;
    reg                     wr_ptr_msb_reg = 0;     
    /*WR_PTR Signals*/

    //Assign Statements
    assign wr_mod        = wr_ptr_reg < (FIFO_DEPTH - 1); //Checking Condition and storing in this
    assign wr_toggle_msb = (wren_i & (~full_o))&(wr_ptr_reg == (FIFO_DEPTH - 1)); //

    assign wr_ptr_up     = ({ADDR_WIDTH{wr_mod}} & (wr_ptr_reg + 1'b1))|
                           ({ADDR_WIDTH{wr_toggle_msb}} & {ADDR_WIDTH{1'b0}}) ;

    assign wr_msb        = ((wr_toggle_msb) & (~wr_ptr_msb_reg))|
                            ((~wr_toggle_msb) & (wr_ptr_msb_reg));

    
    assign wr_ptr_nxt    = (({ADDR_WIDTH{(wren_i & (~full_o))}}) & wr_ptr_up )|
                            (({ADDR_WIDTH{(wren_i & (full_o))}}) & wr_ptr_reg )|
                            (({ADDR_WIDTH{(~wren_i)}}) & wr_ptr_reg );
    

    assign wr_ptr_buff_o = wr_ptr_reg ; //Buffer gets the Binary value

    assign wr_ptr_o   = {wr_ptr_msb_reg,wr_ptr_reg}; //Will be Passed Through  

    assign full_o     = (wr_ptr_msb_reg!= rd_ptr_i[ADDR_WIDTH]) && (wr_ptr_reg == rd_ptr_i[ADDR_WIDTH-1:0]);

    /*always block*/
    always @(posedge clkw_i) begin
        if(rstn_i == 1'b0) begin
            wr_ptr_reg     <= {ADDR_WIDTH{1'b0}};
            wr_ptr_msb_reg <= 1'b0;
        end
        else begin
            wr_ptr_reg     <= wr_ptr_nxt;
            wr_ptr_msb_reg <= wr_msb;
        end
    end
    /*always block end*/
    
endmodule
