// Asynchronous reset here is needed for the FPGA board we use

module top
(
    input        clk_50,
    input  [0:0]      b_sw,
    
    input  [3:0] btn,
    output [3:0] ledg,
	 output [3:0] ledr

//    output [7:0] seg,
//    output [3:0] dig,

//    output       buzzer,

//    output       hsync,
//    output       vsync,
//    output [2:0] rgb
);

    wire reset = ~ b_sw[0];

//    assign abcdefgh  = 8'hff;
//    assign digit     = 4'hf;
//    assign buzzer    = 1'b0;
//    assign hsync     = 1'b1;
//    assign vsync     = 1'b1;
//    assign rgb       = 3'b0;

    // Exercise 1: Free running counter.
    // How do you change the speed of LED blinking?
    // Try different bit slices to display.

//    logic [31:0] cnt;
//    
//    always_ff @ (posedge clk_50 or posedge reset)
//      if (reset)
//        cnt <= 32'b0;
//      else
//        cnt <= cnt + 32'b1;
//
//    assign ledg = ~ cnt [27:24];

    // Exercise 2: Key-controlled counter.
    // Comment out the code above.
    // Uncomment and synthesize the code below.
    // Press the key to see the counter incrementing.
    //
    // Change the design, for example:
    //
    // 1. One key is used to increment, another to decrement.
    //
    // 2. Two counters controlled by different keys
    // displayed in different groups of LEDs.

    

    wire key1 = btn[0];
	 wire key2 = btn[1];

    logic key_r1, key_r2;
    
    always_ff @ (posedge clk_50 or posedge reset)
      if (reset)
			begin
				key_r1 <= '0;
				key_r2 <= '0;
			end
      else
			begin
				key_r1 <= key1;
				key_r2 <= key2;
			end
        
    wire key_pressed1 = ~ key1 & key_r1;
	 wire key_pressed2 = ~ key2 & key_r2;

    logic [3:0] cnt1, cnt2;
    
    always_ff @ (posedge clk_50 or posedge reset)
      if (reset)
			begin
				cnt1 <= 4'b0;
				cnt2 <= '0;
			end
      else if (key_pressed1)
        cnt1 <= cnt1 + 4'b1;
		else if (key_pressed2)
			cnt2 <= cnt2 + 4'b1;

    assign ledg = ~cnt1;
	 assign ledr = ~cnt2;

endmodule
