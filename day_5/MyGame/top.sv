module top
#(
  parameter debounce_depth             = 8,
            num_strobe_width           = 26,
            seven_segment_strobe_width = 10
)
(
  input   logic       clk_50,
  input   logic [0:0] b_sw,
    
  input   logic [3:0] btn,
  output  logic [7:0] ledg,
  output  logic [9:0] ledr,

  output  logic [7:0] seg,
  output  logic [3:0] dig
);
    
  //------------------------------------------------------------------------

  wire reset = ~b_sw;

  //------------------------------------------------------------------------

  logic [3:0] key_db, key_sync, key_in;

  sync_and_debounce #(.w(4), .depth(debounce_depth))
    i_sync_and_debounce_key
      (clk_50, reset, ~btn, key_db);
      
  register #(4)
    i_key_reg
      (clk_50, reset, '1, key_db, key_sync);
      
  assign key_in = key_db & ~key_sync;

  wire [3:0] sw_db;

  //------------------------------------------------------------------------
  
  wire res, outwin, outnotwin;
  
  assign res = (num_count3 == 'd7) & (num_count2 == 'd4) & (num_count1 == 'd8) & (num_count0 == 'd9);
  
  fsm
    i_fsm
      (
        clk_50,
        reset,
        key_in,
        res,
        sw_db,
        outwin,
        outnotwin
      );
      
  assign ledr = {~outnotwin, 9'b111111111};
  assign ledg = {~outwin, 7'b1111111};

  wire num_strobe;

  wire num_strobe0, num_strobe_0;
  wire num_strobe1, num_strobe_1;
  wire num_strobe2, num_strobe_2;
  wire num_strobe3, num_strobe_3;

  strobe_gen #(.w(num_strobe_width))
    i_num_strobe0
      (clk_50, reset, num_strobe_0);

  strobe_gen #(.w(num_strobe_width - 1))
    i_num_strobe1
      (clk_50, reset, num_strobe_1);
      
  strobe_gen #(.w(num_strobe_width - 2))
    i_num_strobe2
      (clk_50, reset, num_strobe_2);
      
  strobe_gen #(.w(num_strobe_width - 3))
    i_num_strobe3
      (clk_50, reset, num_strobe_3);
      
  assign num_strobe0 = num_strobe_0 & ~sw_db[0];
  assign num_strobe1 = num_strobe_1 & ~sw_db[1];
  assign num_strobe2 = num_strobe_2 & ~sw_db[2];
  assign num_strobe3 = num_strobe_3 & ~sw_db[3];

  //------------------------------------------------------------------------

  wire [3:0] num_count0;
  wire [3:0] num_count1;
  wire [3:0] num_count2;
  wire [3:0] num_count3;

//  counter #(4)
//    i_num_counter0
//      (
//        .clk  (clk_50     ),
//        .reset(reset      ),
//        .en   (num_strobe0),
//        .cnt  (num_count0 )
//      );
//
//  counter #(4)
//    i_num_counter1
//      (
//        .clk  (clk_50     ),
//        .reset(reset      ),
//        .en   (num_strobe1),
//        .cnt  (num_count1 )
//      );
//
//  counter #(4)
//    i_num_counter2
//      (
//        .clk  (clk_50     ),
//        .reset(reset      ),
//        .en   (num_strobe2),
//        .cnt  (num_count2 )
//      );
//
//  counter #(4)
//    i_num_counter3
//      (
//        .clk  (clk_50     ),
//        .reset(reset      ),
//        .en   (num_strobe3),
//        .cnt  (num_count3 )
//      );

  rand_shift
    i_rand_shift0
      (
        .clk  (clk_50     ),
        .reset(reset      ),
        .en   (num_strobe0),
        .cnt  (num_count0 )
      );

  rand_shift
    i_rand_shift1
      (
        .clk  (clk_50     ),
        .reset(reset      ),
        .en   (num_strobe1),
        .cnt  (num_count1 )
      );
      
  rand_shift
    i_rand_shift2
      (
        .clk  (clk_50     ),
        .reset(reset      ),
        .en   (num_strobe2),
        .cnt  (num_count2 )
      );
      
  rand_shift
    i_rand_shift3
      (
        .clk  (clk_50     ),
        .reset(reset      ),
        .en   (num_strobe3),
        .cnt  (num_count3 )
      );

  //------------------------------------------------------------------------

  wire [15:0] number_to_display =
    {
      num_count3,
      num_count2,
      num_count1,
      num_count0
    };

  //------------------------------------------------------------------------

  wire seven_segment_strobe;

  strobe_gen #(.w(seven_segment_strobe_width))
    i_seven_segment_strobe
      (clk_50, reset, seven_segment_strobe);

  seven_segment #(.w(16))
    i_seven_segment
      (
        .clk   (clk_50              ),
        .reset (reset               ),
        .en    (seven_segment_strobe),
        .num   (number_to_display   ),
        .dots  (key_sync            ),
        .seg   (seg[7:1]            ),
        .dot   (seg[0]              ),
        .anodes(dig                 )
      );

endmodule: top