module DebounceFilter #(DEBOUNCE_LIMIT = 5000000)(
	input i_clk,
	input i_bouncy,
	output o_debounced);
	
	reg [$clog2(DEBOUNCE_LIMIT):0] r_count;
	reg r_state;
	always @(posedge i_clk)
	begin
		if (i_bouncy != r_state && r_count < DEBOUNCE_LIMIT - 1)
			r_count <= r_count + 1;
		else if (r_count == DEBOUNCE_LIMIT - 1)
		begin
			r_state <= i_bouncy;
			r_count <= 0;
		end
		else
			r_count <= 0;
	end
	assign o_debounced = r_state;
endmodule