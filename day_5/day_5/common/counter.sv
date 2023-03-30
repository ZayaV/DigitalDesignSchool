`include "config.vh"

`ifdef  USE_STRUCTURAL_IMPLEMENTATION

module counter
#(
	parameter w = 1
) 
(
	input		logic						clk,
	input		logic						reset,
	input		logic						en,
	output	logic [w - 1:0] cnt
);

	logic [w - 1:0] q;
	wire [w - 1:0] d = q + 1'b1;

	register #(w) i_reg(clk, reset, en, d, q);
    
	assign cnt = q;

endmodule: counter

`else

module counter
#(
	parameter w = 1
) 
(
	input		logic						clk,
	input		logic						reset,
	input		logic						en,
	output	logic [w - 1:0] cnt
);

	always_ff @(posedge clk or posedge reset)
		if (reset)
			cnt <= '0;
		else if (en)
			cnt <= cnt + 1'b1;

endmodule: counter

`endif
