`include "config.vh"

module register_no_rst
#(
	parameter w = 1
) 
(
	input		logic						clk,
	input		logic						en,
	input		logic [w - 1:0]	d,
	output	logic [w - 1:0] q
);

	always_ff @ (posedge clk)
		if (en)
			q <= d;

endmodule: register_no_rst