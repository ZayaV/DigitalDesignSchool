`include "config.vh"

module strobe_gen
#(
	parameter w = 24
)
(
	input		logic clk,
	input		logic reset,
	output	logic strobe
);

	logic [w - 1:0] count; 

	counter #(w) i_counter(clk, reset, 1'b1, count);
	
	assign strobe = (count == '0);

endmodule: strobe_gen
