module I2CDevice(
	input i_clk,
	input [3:0] i_sw,
	input i_scl,
	inout io_sda,
	output [7:0] o_led);
	
	localparam DEBOUNCE_LIMIT = 5000000;
	localparam SLAVE_ADDR = 7'h50;
	wire [3:0] w_sw;
	wire [7:0] w_rddata;
	
	StateMachineI2C state_inst(
	.i_clk(i_clk),
	.i_data(w_sw),
	.i_scl(i_scl),
	.i_addr(SLAVE_ADDR),
	.io_sda(io_sda),
	.o_rddata(w_rddata));
	
	DebounceFilter #(.DEBOUNCE_LIMIT(DEBOUNCE_LIMIT)) debounce_sw0(
		.i_clk(i_clk),
		.i_bouncy(i_sw[0]),
		.o_debounced(w_sw[0]));
		
	DebounceFilter #(.DEBOUNCE_LIMIT(DEBOUNCE_LIMIT)) debounce_sw1(
		.i_clk(i_clk),
		.i_bouncy(i_sw[1]),
		.o_debounced(w_sw[1]));
		
	DebounceFilter #(.DEBOUNCE_LIMIT(DEBOUNCE_LIMIT)) debounce_sw2(
		.i_clk(i_clk),
		.i_bouncy(i_sw[2]),
		.o_debounced(w_sw[2]));
		
	DebounceFilter #(.DEBOUNCE_LIMIT(DEBOUNCE_LIMIT)) debounce_sw3(
		.i_clk(i_clk),
		.i_bouncy(i_sw[3]),
		.o_debounced(w_sw[3]));
		
	assign o_led[0] = w_rddata[0];
	assign o_led[1] = w_rddata[1];
	assign o_led[2] = w_rddata[2];
	assign o_led[3] = w_rddata[3];
	assign o_led[4] = w_rddata[4];
	assign o_led[5] = w_rddata[5];
	assign o_led[6] = w_rddata[6];
	assign o_led[7] = w_rddata[7];
		
endmodule
	