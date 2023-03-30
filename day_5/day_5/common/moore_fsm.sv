`include "config.vh"

module moore_fsm
(
	input		logic clk,
	input		logic reset,
	input		logic en,
	input		logic a,
	output	logic y
);

	parameter [1:0] S0 = 0, S1 = 1, S2 = 2;

	logic [1:0] state, next_state;

	// State register
	always_ff @(posedge clk or posedge reset)
		if (reset)
			state <= S0;
		else if (en)
			state <= next_state;

	// Next state logic
	always_comb
		case (state)
			S0:
				if (a)
					next_state = S0;
				else
					next_state = S1;

			S1:
				if (a)
					next_state = S2;
				else
					next_state = S1;

			S2:
				if (a)
					next_state = S0;
				else
					next_state = S1;

			default:
				next_state = S0;
	endcase

	// Output logic based on current state
	assign y = (state == S2);

endmodule: moore_fsm
