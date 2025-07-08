module StateMachineI2C(
	input i_clk,
	input [7:0] i_data,
	input i_scl,
	input [6:0] i_addr,
	inout io_sda,
	output  [7:0] o_rddata);
	
	localparam IDLE = 3'd0;
	localparam SHIFT_ADDR = 3'd1;
	localparam ADDR_ACK = 3'd2;
	localparam DATA_RX = 3'd3;
	localparam RX_ACK = 3'd4;
	localparam DATA_TX = 3'd5;
	localparam TX_ACK = 3'd6;
	
	reg [2:0] r_state;
	reg [1:0] r_sda_sync, r_scl_sync;
	reg r_drive_en;
	reg r_sda_out;
	reg [3:0] r_count;
	reg [7:0] r_addr_read;
	reg r_acked;
	
	wire w_sda_fall = r_sda_sync[1] && !r_sda_sync[0] && r_scl_sync[1];
	wire w_sda_rise = !r_sda_sync[1] && r_sda_sync[0] && r_scl_sync[1];
	wire w_scl_rise = !r_scl_sync[1] && r_scl_sync[0];
	wire w_scl_fall = r_scl_sync[1] && !r_scl_sync[0];
	
	always @(posedge i_clk)
	begin
		if (w_sda_fall)
		begin
			r_state <= SHIFT_ADDR;
			r_drive_en <= 0;
			r_count <= 0;
			r_acked <= 0;
		end
		else if (w_sda_rise)
			r_state <= IDLE;
		else
		begin
			case (r_state)
			
			IDLE:
			begin
				r_drive_en <= 0;
				r_count <= 0;
				r_acked <= 0;
			end
			
			SHIFT_ADDR:
			begin
				if (r_count <= 3'd7)
				begin
					if (w_scl_rise)
					begin
						r_addr_read <= {r_addr_read[6:0], r_sda_sync[1]};
						r_count <= r_count + 1;
					end
				end
				else
				begin
					r_state <= ADDR_ACK;
					r_count <= 0;
				end
			end
			
			ADDR_ACK:
			begin
				if (w_scl_fall & !r_acked)
				begin
					r_acked <= 1'b1;
					if (i_addr == r_addr_read[7:1])
					begin
						r_drive_en <= 1'b1;
						r_sda_out <= 1'b0;
					end
					else
						r_state <= IDLE;
				end
				else if (w_scl_fall & r_acked)
				begin
					r_acked <= 1'b0;
					if (r_addr_read[0])
					begin
						r_drive_en <= 1'b1;
						r_state <= DATA_TX;
						r_sda_out <= i_data[7];
						r_count <= r_count + 1;
					end
					else
					begin
						r_state <= DATA_RX;
						r_drive_en <= 1'b0;
					end
				end
			end
			
			DATA_RX:
			begin
				if (r_count <= 7)
				begin
					if (w_scl_rise)
					begin
//						o_rddata <= {o_rddata[6:0], r_sda_sync[1]};
						r_count <= r_count + 1;
					end
				end
				else
				begin
					r_state <= RX_ACK;
					r_count <= 0;
				end
			end
			
			RX_ACK:
			begin
				if (w_scl_fall & !r_acked)
				begin
					r_acked <= 1'b1;
					r_drive_en <= 1'b1;
					r_sda_out <= 1'b0;
				end
				else if (w_scl_fall & r_acked)
				begin
					r_acked <= 1'b0;
					r_drive_en <= 1'b0;
					r_state <= DATA_RX;
				end
			end
			
			DATA_TX:
			begin
				if (w_scl_fall)
				begin
					if (r_count <= 3'd7)
					begin
						r_sda_out <= i_data[7 - r_count];
						r_count <= r_count + 1;
					end
					else
					begin
						r_count <= 0;
						r_drive_en <= 1'b0;
						r_state <= TX_ACK;
					end
				end
			end
			
			TX_ACK:
			begin
				if (w_scl_rise)
				begin
					if (!r_sda_sync[0])
					begin
						r_state <= DATA_TX;
						r_sda_out <= i_data[0];
						r_count <= r_count + 1;
					end
					else
						r_state <= IDLE;
				end
				
			end	
			
			default:
			begin
				r_state <= IDLE;
			end
			endcase	
		end
	
	end
	
	always @(posedge i_clk)
	begin
		r_sda_sync[0] <= io_sda;
		r_scl_sync[0] <= i_scl;
		r_sda_sync[1] <= r_sda_sync[0];
		r_scl_sync[1] <= r_scl_sync[0];
		
	end
	
	assign io_sda = r_drive_en ? r_sda_out : 1'bz;
	assign o_rddata = r_state;
	
endmodule	
	