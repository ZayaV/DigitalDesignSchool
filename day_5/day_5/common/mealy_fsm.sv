`include "config.vh"

module mealy_fsm
(
	input		logic clk,
	input		logic reset,
	input		logic en,
	input		logic a,
	output	logic y
);

	parameter [0:0] S0 = 1'b0, S1 = 1'b1;

	logic state, next_state;

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
					next_state = S0;
				else
					next_state = S1;
			default:
				next_state = S0;
		endcase

	// Output logic based on current state and inputs
	assign y = (a & state == S1);

endmodule: mealy_fsm
