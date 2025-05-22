# APB UART System– RTL Design
This project implements a UART (Universal Asynchronous Receiver/Transmitter) system with an APB (Advanced Peripheral Bus) interface using synthesizable Verilog RTL. It includes internal FIFOs, status/control registers, and supports both transmission and reception over a standard UART serial interface. The system is verified using a loopback testbench through APB-based control and status registers.

# Modules in the Design
## APB_UART.v
   Top-level wrapper that integrates the APB Slave interface with the UART module. Handles register-level communication and transfers configuration/control to UART logic.
   ![image](https://github.com/user-attachments/assets/d81c4ba2-6002-4cc6-bdcd-cdf68083b743)
## APB_Slave.v
   Implements APB3 protocol-compliant slave interface. Decodes addresses and manages read/write transactions. Supports: 
    - 0x00 – TX FIFO Write   - R/W
    - 0x04 – UART Control    - R/W
    - 0x08 – Status Register - R
    - 0x0C – RX FIFO Read    - R
   ![image](https://github.com/user-attachments/assets/b8b817fa-3241-4cc4-b9d0-5d3318d7eb16)
## UART_Module.v
   Core UART system integrating transmit/receive FIFOs and UART logic. Generates baud clock, status flags, and supports loopback.
   ![image](https://github.com/user-attachments/assets/36260ebf-2a7f-45e8-a940-a86275362a1e)
## UART_TX.v
   Serializes 8-bit data into UART format (start bit + 8 data bits + stop bit). Uses FSM and baud clock.
   ![image](https://github.com/user-attachments/assets/abd11b34-f824-4f15-ba7d-6ba904891865)
## UART_RX.v
   Deserializes UART input into parallel data. Detects start bit, samples, and validates received byte.
   ![image](https://github.com/user-attachments/assets/7a71beb5-cfd3-4859-8eef-79bce13c5f79)
## FIFOs
   Implements simple synchronous FIFOs for TX and RX buffering.
   ![image](https://github.com/user-attachments/assets/6c678d57-4720-4f66-b638-493bc325bc15)

# UART Control & Status Register Format

## UART Control Register (ADDR = 0x04)
| Bit(s)   | Function                      |
|----------|-------------------------------|
| [0]      | TX Enable                     |
| [1]      | Unused                        |  
| [4:2]    | Baudrate Selector             |
| [5]      | Loopback Enable (TX → RX)     |
| [31:6]   | Reserved                      |

## UART Status Register (ADDR = 0x08)
| Bit(s) | Function             |
|--------|----------------------|
| [0]    | TX BUSY              |
| [1]    | TX DONE              |
| [2]    | TX FIFO EMPTY        |
| [3]    | TX FIFO FULL         |
| [4]    | RX BUSY              |
| [5]    | RX OVERRUN           |
| [6]    | RX FIFO EMPTY        |
| [7]    | RX FIFO FULL         |
| [31:8] | Reserved             |

# Testbench
Simulates a loopback test where:
- UART is configured via APB.
- 5 random bytes are sent to TX FIFO.
- They loop back into RX.
- After RX FIFO fills, data is read and compared.

Features include register writes, polling for RX FIFO full, reading back received data, and displaying success/failure.

# Simulation 
## Results Given Below
![image](https://github.com/user-attachments/assets/9d97e707-9728-49d0-81f7-8d4706ff7509)
![image](https://github.com/user-attachments/assets/28f655c8-8894-42e4-a2a2-9f8c268817b0)
RX_DATA_LIST Equals TX_DATA_LIST(Loopback SUCCESS)
![image](https://github.com/user-attachments/assets/61d830e2-f1b6-40ed-a50c-c80d98098c37)

TCL_CONSOLE OUTPUT

# Important Notes
1. This design assumes a 100 MHz system clock.
2. Baudrate is set for 115200 bps by setting up the control register bits [4:2] as 1_0_1.
3. FIFO depth is parameterized and defaults to 5.(Can Be modified)




