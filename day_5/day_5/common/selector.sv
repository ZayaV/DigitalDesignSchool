`include "config.vh"

module selector
#(
	parameter w = 8,
						n = 2
) 
(
	input		logic [n * w - 1:0]	d,
	input		logic [n     - 1:0]	sel,
	output	logic [w     - 1:0] y
);

	integer i;

	always_comb
    begin
			y = '0;
        
			for (i = 0; i < n; i++) 
				y = y | (d[i * w +: w] & {w {sel[i]}});
		end

endmodule: selector
