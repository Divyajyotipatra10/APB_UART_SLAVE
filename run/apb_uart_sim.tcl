#DO FILE FOR APB UART MODULE
#WORK LIBRARY
vlib work 
#vmap work dev
#COMPILING ALL RTL DESIGN FILES
vlog ../rtl/APB_Slave.v
vlog ../rtl/APB_UART.v
vlog ../rtl/FIFO_ALL.v
vlog ../rtl/FIFO_BUFF.v
vlog ../rtl/FIFO_RD.v
vlog ../rtl/FIFO_WR.v
vlog ../rtl/FIFO_UART_TX.v
vlog ../rtl/FIFO_UART_RX.v
vlog ../rtl/UART_CLK.v
vlog ../rtl/UART_Module.v
vlog ../rtl/UART_RX.v
vlog ../rtl/UART_TX.v

#COMPILING THE TESTBENCH

vlog ../tb/apb_uart_tb.v

#ELABORATION

vsim work.apb_uart_tb

add wave -divider "Global Signals"
add wave sim:/apb_uart_tb/CLK
add wave sim:/apb_uart_tb/RESETn

add wave -divider "APB Interface"
add wave sim:/apb_uart_tb/SELx
add wave sim:/apb_uart_tb/WRITE
add wave sim:/apb_uart_tb/ENABLE
add wave sim:/apb_uart_tb/ADDR
add wave sim:/apb_uart_tb/WDATA
add wave sim:/apb_uart_tb/RDATA
add wave sim:/apb_uart_tb/READY

add wave -divider "UART Lines"
add wave sim:/apb_uart_tb/RX
add wave sim:/apb_uart_tb/TX

add wave -divider "TX and RX Data Buffers"
add wave sim:/apb_uart_tb/TX_DATA_LIST
add wave sim:/apb_uart_tb/RX_DATA_LIST

# Run simulation
run -all
