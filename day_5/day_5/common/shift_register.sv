`include "config.vh"

`ifdef  USE_STRUCTURAL_IMPLEMENTATION

module shift_register
#(
	parameter w = 1
) 
(
	input		logic						clk,
	input		logic						reset,
	input		logic						en,
	input		logic						in,
	output	logic [w - 1:0] out_reg
);

	logic [w - 1:0] q;
	wire [w - 1:0] d = {in, q[w - 1:1]};

	register #(w) i_reg(clk, reset, en, d, q);
    
	assign out_reg = q;

endmodule: shift_register

`else

module shift_register
#(
	parameter w = 1
) 
(
	input		logic						clk,
	input		logic						reset,
	input		logic						en,
	input		logic						in,
	output	logic [w - 1:0] out_reg
);

	always_ff @(posedge clk or posedge reset)
		if (reset)
			out_reg <= '0;
		else if (en)
			out_reg <= {in, out_reg[w - 1:1]};

endmodule: shift_register

`endif