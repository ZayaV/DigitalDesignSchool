module new_moore_fsm
(
	input		logic				clk,
	input		logic				reset,
	input		logic				en,
	input		logic [3:0] keys,
	input		logic				anykey,
	output	logic				y,
	output	logic				ny
);

	typedef enum int unsigned
		{IDLE,
		 K1,
		 K2,
		 K3,
		 K4,
		 NK1,
		 NK2,
		 NK3,
		 NK4} state_e;
		 
	state_e state, next_state;
	
	// State register
	always_ff @(posedge clk or posedge reset)
		if (reset)
			state <= IDLE;
		else if (en)
			state <= next_state;
	
	// Next state logic
	always_comb
		case (state)
			IDLE:
				if (!anykey)
					next_state = IDLE;
				else
					if (keys[3])
						next_state = K1;
					else
						next_state = NK1;

			K1:
				if (!anykey)
					next_state = K1;
				else
					if (keys[0])
						next_state = K2;
					else
						next_state = NK2;

			K2:
				if (!anykey)
					next_state = K2;
				else
					if (keys[2])
						next_state = K3;
					else
						next_state = NK3;
						
			K3:
				if (!anykey)
					next_state = K3;
				else
					if (keys[3])
						next_state = K4;
					else
						next_state = NK4;
						
			K4:
				next_state = IDLE;
				
			NK1:
				if (~anykey)
					next_state = NK1;
				else
					next_state = NK2;
					
			NK2:
				if (~anykey)
					next_state = NK2;
				else
					next_state = NK3;
					
			NK3:
				if (~anykey)
					next_state = NK3;
				else
					next_state = NK4;
					
			NK4:
				next_state = IDLE;

			default:
				next_state = IDLE;
	endcase
	
	// Output logic based on current state
	assign y = (state == K4);
	assign ny = (state == NK4);

endmodule: new_moore_fsm