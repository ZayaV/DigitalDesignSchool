module fsm
(
  input		logic clk,
	input		logic reset,
	input		logic [3:0] in,
  input   logic res,
	output	logic [3:0] out,
  output  logic outwin,
  output  logic outnotwin
);

	typedef enum int unsigned
		{IDLE,
		 K1,
		 K2,
		 K3,
		 K4,
     WIN,
     NOTWIN,
     XXX} state_e;
		 
	state_e state, next_state;
  
	// State register
	always_ff @(posedge clk or posedge reset)
		if (reset)
			state <= IDLE;
		else
			state <= next_state;
      
  always_comb
    begin
      next_state = XXX;
      
      case (state)
        IDLE:
          if (in[0])
            next_state = K1;
          else if (|in[3:1])
            next_state = NOTWIN;
          else
            next_state = IDLE;
            
        K1:
          if (in[1])
            next_state = K2;
          else if (|in[3:2])
            next_state = NOTWIN;
          else
            next_state = K1;
            
        K2:
          if (in[2])
            next_state = K3;
          else if (in[3])
            next_state = NOTWIN;
          else
            next_state = K2;
            
        K3:
          if (in[3])
            next_state = K4;
          else
            next_state = K3;
            
        K4:
          if (res)
            next_state = WIN;
          else
            next_state = NOTWIN;
            
        WIN:
          if (|in)
            next_state = IDLE;
          else
            next_state = WIN;
            
        NOTWIN:
          if (|in)
            next_state = IDLE;
          else
            next_state = NOTWIN;
            
        default:
          next_state = XXX;
      endcase
    end
    
  always_ff @(posedge clk or posedge reset)
    if (reset)
      begin
        out <= '0;
        outwin <= '0;
        outnotwin <= '0;
      end
    else
      case (next_state)
        K1:
          out <= 4'b0001;
        K2:
          out <= 4'b0011;
        K3:
          out <= 4'b0111;
        K4:
          out <= '1;
        WIN:
          begin
            out <= '1;
            outwin <= '1;
          end
        NOTWIN:
          begin
            out <= '1;
            outnotwin <= '1;
          end
        default:
          begin
            out <= '0;
            outwin <='0;
            outnotwin <= '0;
          end
      endcase

endmodule: fsm