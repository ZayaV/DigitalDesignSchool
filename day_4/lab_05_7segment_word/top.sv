// Asynchronous reset here is needed for the FPGA board we use

module top
(
    input        clk_50,
    input  [1:0] b_sw,
    
    input  [3:0] btn,
    output [3:0] ledg,

    output [7:0] seg,
    output [3:0] dig

//    output       buzzer,
//
//    output       hsync,
//    output       vsync,
//    output [2:0] rgb
);

    wire reset = ~b_sw[0];

//    assign buzzer = 1'b0;
//    assign hsync  = 1'b1;
//    assign vsync  = 1'b1;
//    assign rgb    = 3'b0;
    
    //------------------------------------------------------------------------

    logic [31:0] cnt;
    
    always_ff @ (posedge clk_50 or posedge reset)
      if (reset)
        cnt <= '0;
      else
        cnt <= cnt + 32'b1;

    wire enable = (cnt [16:0] == 17'b0);

    //------------------------------------------------------------------------

    logic [3:0] shift_reg;
    
    always_ff @ (posedge clk_50 or posedge reset)
      if (reset)
        shift_reg <= 4'b0001;
      else if (enable)
        shift_reg <= { shift_reg [0], shift_reg [3:1] };

    assign ledg = ~ shift_reg;

    //------------------------------------------------------------------------

    //   --a--
    //  |     |
    //  f     b
    //  |     |
    //   --g--
    //  |     |
    //  e     c
    //  |     |
    //   --d--  h
    //
    //  0 means light

    enum bit [7:0]
    {
        A = 8'b00010001,
        B = 8'b11000001,
        C = 8'b01100011,
		  E = 8'b01100001,
		  H = 8'b10010001,
		  I = 8'b10011111,
        K = 8'b01010001,
		  P = 8'b00110001,
        U = 8'b10000011
    }
    letter;
    
    always_comb
    begin
      case (shift_reg)
      4'b1000: letter = B;
      4'b0100: letter = A;
      4'b0010: letter = C;
      4'b0001: letter = K;
      default: letter = E;
      endcase
    end

    assign seg = letter;
    assign dig = shift_reg;

    // Exercise 1: Increase the frequency of enable signal
    // to the level your eyes see the letters as a solid word
    // without any blinking. What is the threshold of such frequency?

    // Exercise 2: Put your name or another word to the display.

    // Exercise 3: Comment out the "default" clause from the "case" statement
    // in the "always" block,and re-synthesize the example.
    // Are you getting any warnings or errors? Try to explain why.

endmodule
