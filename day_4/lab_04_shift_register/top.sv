// Asynchronous reset here is needed for the FPGA board we use

module top
(
    input        clk_50,
    input  [1:0]      b_sw,
    
    input  [3:0] btn,
    output [3:0] ledg,

    output [7:0] seg,
    output [3:0] dig

//    output       buzzer,

//    output       hsync,
//    output       vsync,
//    output [2:0] rgb
);

    wire reset = ~ b_sw[0];

//    assign seg  = 8'hff;
//    assign dig     = 4'hf;
//    assign buzzer    = 1'b0;
//    assign hsync     = 1'b1;
//    assign vsync     = 1'b1;
//    assign rgb       = 3'b0;
    
    //------------------------------------------------------------------------

    logic [31:0] cnt;
    
    always_ff @ (posedge clk_50 or posedge reset)
      if (reset)
        cnt <= 32'b0;
      else
        cnt <= cnt + 32'b1;
        
    wire enable = (cnt [22:0] == 23'b0);

    //------------------------------------------------------------------------

    wire button_on = ~btn[0];
	 wire button_off = ~btn[1];

    logic [5:0] shift_reg;
    
    always_ff @ (posedge clk_50 or posedge reset)
      if (reset)
        shift_reg <= 6'b0;
      else if (enable)
			if (button_on)
				shift_reg <= {shift_reg[4:0], button_on};
			else
				shift_reg <= { shift_reg [4:0], shift_reg[5] };
		else if (button_off)
			shift_reg <= '0;

    assign seg = ~{shift_reg, 2'b0};
	 assign dig = 4'b1010;
	 assign ledg = '1;

    // Exercise 1: Make the light move in the opposite direction.

    // Exercise 2: Make the light moving in a loop.
    // Use another key to reset the moving lights back to no lights.

    // Exercise 3: Display the state of the shift register
    // on a seven-segment display, moving the light in a circle.

endmodule
