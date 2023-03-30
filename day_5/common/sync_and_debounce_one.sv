`include "config.vh"

module sync_and_debounce_one
#(
	parameter depth = 8
)
(   
	input		logic clk,
	input		logic reset,
	input		logic sw_in,
	output	logic sw_out
);

	logic [depth - 1:0] cnt;
	logic [2:0] sync;
	logic sw_in_s;

	assign sw_in_s = sync [2];

	always_ff @(posedge clk or posedge reset)
		if (reset)
			sync <= '0;
		else
			sync <= {sync [1:0], sw_in};

	always_ff @(posedge clk or posedge reset)
		if (reset)
			cnt <= '0;
		else if (sw_out ^ sw_in_s)
			cnt <= cnt + 1'b1;
		else
			cnt <= '0;

	always_ff @(posedge clk or posedge reset)
		if (reset)
			sw_out <= '0;
		else if (cnt == '1)
			sw_out <= sw_in_s;

endmodule: sync_and_debounce_one