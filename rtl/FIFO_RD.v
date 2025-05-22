`timescale 1ns / 1ps

module FIFO_RD #(
    parameter   FIFO_DEPTH = 50, //Can Be Any Number
    localparam  ADDR_WIDTH = $clog2(FIFO_DEPTH + 1) // To be changed as per requirement
)
(
    input                    clkr_i,            
    input                    rstn_i,
    input   [ADDR_WIDTH:0]   wr_ptr_i, // Synchronised Signal Coming from two flop synchronisers and through gray to binary counters
    input                    rden_i,
    output  [ADDR_WIDTH:0]   rd_ptr_o,
    output  [ADDR_WIDTH-1:0] rd_ptr_buff_o,  // Buffer gets the Actual address where data will be stored(No need to send MSB)               
    output                   empty_o
    );
    // Wire and Register Definitions
    /*RD_PTR Signals*/
    wire   [ADDR_WIDTH-1:0] rd_ptr_nxt;
    wire   [ADDR_WIDTH-1:0] rd_ptr_up ;
    wire                    rd_mod    ; //For Any depth, Used Mod Counter based pointers
    wire                    rd_msb    ; 
    wire                    rd_toggle_msb;//Toggling The MSB
    reg    [ADDR_WIDTH-1:0] rd_ptr_reg = 0;
    reg                     rd_ptr_msb_reg = 0;     
    /*RD_PTR Signals*/
    //Assign Statements
    assign rd_mod        = rd_ptr_reg < (FIFO_DEPTH - 1); //Checking Condition and storing in this
    assign rd_toggle_msb = ((rden_i & (~empty_o))) & (rd_ptr_reg == (FIFO_DEPTH - 1)); //

    assign rd_ptr_up     = ({ADDR_WIDTH{rd_mod}} & (rd_ptr_reg + 1'b1))|
                           ({ADDR_WIDTH{~rd_mod}} & {ADDR_WIDTH{1'b0}}) ;

    assign rd_msb        = (rd_toggle_msb & (~rd_ptr_msb_reg))|
                            ((~rd_toggle_msb) & rd_ptr_msb_reg);

    
    assign rd_ptr_nxt    = (({ADDR_WIDTH{(rden_i & (~empty_o))}}) & rd_ptr_up )|
                            (({ADDR_WIDTH{(rden_i & (empty_o))}}) & rd_ptr_reg )|
                            (({ADDR_WIDTH{(~rden_i)}}) & rd_ptr_reg );
    

    assign rd_ptr_buff_o = rd_ptr_reg ; //Buffer gets the Binary value

    assign rd_ptr_o   = {rd_ptr_msb_reg,rd_ptr_reg}; //Will be Passed Through  

    assign empty_o     = (rd_ptr_o == wr_ptr_i ); 

 /*always block*/
    always @(posedge clkr_i) begin
        if(rstn_i == 1'b0) begin
            rd_ptr_reg     <= {ADDR_WIDTH{1'b0}};
            rd_ptr_msb_reg <= 1'b0;
        end
        else begin
            rd_ptr_reg     <= rd_ptr_nxt;
            rd_ptr_msb_reg <= rd_msb;
        end
    end
    /*always block end*/
endmodule