# I2C-Device

An I²C communication system implemented by creating an I²C slave with Verilog, supporting standard I²C operations such as START, STOP, ACK/NACK, and read/write transactions.

## Description

This project implements a hardware I²C slave using Verilog. To begin, the [NXP I²C-bus specification and user manual](https://www.nxp.com/docs/en/user-guide/UM10204.pdf) was consulted to define the required timing and protocol. Based on this specification, a finite state machine was designed to handle all I²C bus states.

**State Machine Diagram**  
![State Machine Diagram](https://github.com/DanKim15/I2C-Device/blob/main/i2c_state_diagram.jpg)

## Detailed Code Explanation

### I2CDevice (top-level)
Combines the debounce filters, the I²C FSM, and LED outputs:
- **Parameters:**
  - `SLAVE_ADDR` is the 7-bit I²C address (0x50).
- **StateMachineI2C Instance:**
  Handles all I²C protocol details, driving the bidirectional `io_sda` line and sampling `i_scl`.

### StateMachineI2C (FSM core)
Implements the I²C slave protocol as a seven-state FSM:

| State         | Code | Description |
|---------------|------|-------------|
| IDLE          | 000  | Waiting for START condition |
| SHIFT_ADDR    | 001  | Shift in 7-bit address+R/W bit |
| ADDR_ACK      | 010  | Drive ACK/NACK for address acknowledge |
| DATA_RX       | 011  | Receive data byte from master |
| RX_ACK        | 100  | Acknowledge received byte |
| DATA_TX       | 101  | Transmit data byte to master |
| TX_ACK        | 110  | Receive ACK/NACK from master |

**Key registers & signals:**
- `r_sda_sync`, `r_scl_sync`: two-stage synchronizers for sampling the asynchronous `io_sda` and `i_scl`.
- Edge detectors:
  - `w_sda_fall`: detects START (SDA fall while SCL high).
  - `w_sda_rise`: detects STOP (SDA rise while SCL high).
  - `w_scl_rise` / `w_scl_fall`: clock edges for bit sampling and driving.
- `r_addr_read`: used for shifting in the address and R/W bit.
- `r_drive_en` & `r_sda_out`: controls the tri-state `io_sda` driver for ACK/NACK and data bits.
- `r_count`: bit counter (0–7) for shifting within each byte.
- `r_acked`: internal flag to check for acknoledgement.

**State machine flow:**
1. **START Detection:** On `w_sda_fall`, enter `SHIFT_ADDR` while resetting counters and flags.
2. **Address Phase:** In `SHIFT_ADDR`, on each `w_scl_rise`, shift `r_sda_sync[1]` (the sampled SDA) into `r_addr_read` MSB-first. After 8 bits, transition to `ADDR_ACK`.
3. **Address ACK:** On the first `w_scl_fall` in `ADDR_ACK`, if the first 7 bits of `r_addr_read` match `i_addr`, pull SDA low (`r_drive_en=1, r_sda_out=0`) to ACK. Otherwise, return to `IDLE`. On the next `w_scl_fall`, if it was a read command (`r_addr_read[0]==1`), enable drive, move to `DATA_TX`, and output the MSB. If it was a write bit (`r_addr_read[0]==0`), disable drive and move to `DATA_RX`.
4. **Data Receive:** In `DATA_RX`, sample SDA on `w_scl_rise` until 8 bits are received, then transition to `RX_ACK`. Then in `RX_ACK`, drive SDA low on the first `w_scl_fall` to ACK, then clear drive and return to `DATA_RX` to receive more bytes.
5. **Data Transmit:** In `DATA_TX`, on each `w_scl_fall`, output the next data bit (`i_data[7 - r_count]`). After 8 bits, disable drive and enter `TX_ACK`. In `TX_ACK`, on `w_scl_rise`, sample SDA: if pulled low by master (ACK), send the next byte. if left high (NACK), return to `IDLE`.
6. **STOP Detection:** If the state machine detects a high `w_sda_rise` at any point of the transmission process, set the state to `IDLE`.

All SDA driving uses a tri-state buffer: `io_sda = r_drive_en ? r_sda_out : 1'bz`.

### Testbench (`StateMachineI2C_TB.sv`)
Verifies the FSM by emulating I²C master operations using tasks and displaying `io_sda` and `r_scl` on a waveform:

- **Clock generation:** 10 ns period (`r_clk` toggles every 5 ns).
- **I/O modeling:** `io_sda` is a tri-state net with a pull-up, and `r_sda_drv` controls whether the testbench drives it.
- **Tasks:**
  - `clk_high` / `clk_low`: drive `r_scl` high or low for delays.
  - `i2c_start`: pull SDA low while SCL is high to START.
  - `i2c_stop`: release SDA high while SCL is high to generate STOP.
  - `i2c_write_bit`: drive SDA to a bit value, then toggle SCL.
  - `i2c_read_bit`: release SDA, then sample it while SCL is high.
  - `i2c_write_byte`: loop `i2c_write_bit` over 8 bits.
  - `i2c_get_ack`: read a bit and invert it to represent ACK/NACK.
  - `i2c_read_byte`: read 8 bits using `i2c_read_bit`.

- **Testbench sequence:**
  1. **Write transaction:**
     - `i2c_start()`
     - Send `{SLV_ADDR,0}` (write) then ACK (`SLV_ADDR` = 1000010).
     - Send data byte (`00111100`) then ACK.
     - `i2c_stop()`
  2. **Read transaction:**
     - `i2c_start()`
     - Send `{SLV_ADDR,1}` (read) then ACK.
     - `i2c_read_byte(rd_data)` to capture slave’s response.
     - Master NACK (`i2c_write_bit(1)`) then `i2c_stop()`.

Initial FSM bugs such as missing ACK drive, timing issues, and incorrect bit shifting were identified and corrected by observing the SDA/SCL waveform and verifying that each bit, ACK, and STOP condition matches the correct spec standards.

**Annotated I2C Waveform**  
![Expected I2C Waveform](https://github.com/DanKim15/I2C-Device/blob/main/annotated_statemachineI2C_waveform.jpg)

## Future Steps

- Connect this module using a physical FPGA board to an I²C master device, such as a microcontroller, to perform physical data transfers.  

