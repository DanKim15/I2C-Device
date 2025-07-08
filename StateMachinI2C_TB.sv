`timescale 1ns/1ps

module StateMachineI2C_TB;

	reg r_clk;
	initial 
	begin
		r_clk = 1'b0;
		forever #5 r_clk = ~r_clk;
	end

	reg  r_sda_drv, r_sda_out;
	reg  r_scl;

	tri io_sda;
	pullup p1 (io_sda);

	assign io_sda = r_sda_drv ? r_sda_out : 1'bz;

	localparam [6:0] SLV_ADDR = 7'b1000010;
	localparam [7:0] SLV_TX   = 8'b10100101;

	wire [7:0] w_rddata;

	StateMachineI2C dut (
		.i_clk   (r_clk),
		.i_data  (SLV_TX),
		.i_scl   (r_scl),
		.i_addr  (SLV_ADDR),
		.io_sda  (io_sda),
		.o_rddata(w_rddata)
	);

	
	task clk_high(); 
	begin 
		r_scl <= 1'b1; 
		#5000; 
	end 
	endtask
	
	task clk_low(); 
	begin 
		r_scl <= 1'b0; 
		#2500; 
	end 
	endtask

	task i2c_start;
	begin
		r_sda_drv <= 1'b1;
		r_sda_out <= 1'b1;
		clk_high();
		#1000  r_sda_out <= 1'b0; 
		#1000  clk_low();
	end
	endtask

	task i2c_stop;
	begin
		r_sda_drv <= 1'b1;
		r_sda_out <= 1'b0;
		clk_high();
		#1000  r_sda_out <= 1'b1;
		#1000;
	end
	endtask

	task i2c_write_bit (input bit b);
	begin
		clk_low();
		r_sda_drv <= 1'b1;
		r_sda_out <= b;
		clk_low();
		clk_high();
	end
	endtask

	task automatic i2c_read_bit (output bit value);
	begin
		clk_low();
		clk_low();
		r_sda_drv <= 1'b0;
		value = io_sda;
		clk_high();
	end
	endtask

	task i2c_write_byte (input [7:0] i_byte);
	integer i;
	begin
		for (i = 7; i >= 0; i--) 
			i2c_write_bit(i_byte[i]);
	end
	endtask

	task automatic i2c_get_ack (output bit ack);
	bit tmp;
	begin
		i2c_read_bit(tmp);
		ack = ~tmp;
	end
	endtask

	task automatic i2c_read_byte (output byte data);
	integer i;
	bit bit_val;
	begin
		for (i = 7; i >= 0; i--) 
		begin
			i2c_read_bit(bit_val);
			data[i] = bit_val;
		end
	end
	endtask


	initial 
	begin
		byte wr_data;
		byte rd_data;
		bit ack_ok;

		r_scl = 1'b1;
		r_sda_drv = 1'b1;
		r_sda_out = 1'b1;
		
		

		repeat (10) @(posedge r_clk);

		wr_data = 8'b00111100;

		// WRITE OPERATION
		i2c_start();

		// Address + WRITE (0)
		i2c_write_byte({SLV_ADDR, 1'b0});
		
		i2c_get_ack(ack_ok);
		// Data byte
		i2c_write_byte(wr_data);
		i2c_get_ack(ack_ok);
		clk_low();
		clk_low();
		
		i2c_stop();

		// READ OPERATION
		i2c_start();

		// Address + READ (1)
		i2c_write_byte({SLV_ADDR, 1'b1});
		i2c_get_ack(ack_ok);
		// Read byte
		i2c_read_byte(rd_data);

		// Master NACK
		i2c_write_bit(1'b1);
		clk_low();
		clk_low();
		
		i2c_stop();


		#20_000 $finish;
	end

endmodule
