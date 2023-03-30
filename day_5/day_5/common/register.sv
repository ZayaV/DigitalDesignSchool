`include "config.vh"

module register
#(
	parameter w = 1
) 
(
	input		logic						clk,
	input		logic						reset,
	input		logic						en,
	input		logic [w - 1:0] d,
	output	logic [w - 1:0] q
);

	always_ff @(posedge clk or posedge reset)
		if (reset)
			q <= '0;
		else if (en)
			q <= d;

endmodule: register
