module top
#(
  parameter debounce_depth             = 8,
            shift_strobe_width         = 23,
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

//    output       buzzer,

//    output       hsync,
//    output       vsync,
//    output [2:0] rgb
);

//    assign buzzer = 1'b0;
//    assign hsync  = 1'b1;
//    assign vsync  = 1'b1;
//    assign rgb    = 3'b0;
    
  //------------------------------------------------------------------------

  wire reset = ~b_sw;

  //------------------------------------------------------------------------

  logic [3:0] key_db;
  logic [3:0] key_reg1, key_reg2;
  logic [3:0] key_sync;

  sync_and_debounce
      #(.w(4), .depth(debounce_depth))
    i_sync_and_debounce_key
      (clk_50, reset, ~btn, key_db);

  
  register #(4)
    i_keys_register1
      (clk_50, reset, shift_strobe, key_db, key_reg1);
      
  register #(4)
    i_keys_register2
      (clk_50, reset, shift_strobe, key_reg1, key_reg2);
      
  assign key_sync = key_reg1 & ~key_reg2;
  wire anykey = |key_sync;

  //------------------------------------------------------------------------

  logic shift_strobe;

  strobe_gen
      #(.w(shift_strobe_width))
    i_shift_strobe
      (clk_50, reset, shift_strobe);

//  logic [3:0] out_reg;
//
//  shift_register #(.w(4))
//    i_shift_reg
//      (
//        .clk    (clk_50      ),
//        .reset  (reset       ),
//        .en     (shift_strobe),
//        .in     (key_db[3]   ),
//        .out_reg(out_reg     )
//      );

  assign ledg = {~out_moore_fsm, ~out_mealy_fsm, 2'b11, ~key_sync};
  assign ledr = {~nout_moore_fsm, ~nout_mealy_fsm, 8'b11111111};

  //------------------------------------------------------------------------

  logic [7:0] shift_strobe_count;

  counter #(8)
    i_shift_strobe_counter
      (
        .clk  (clk_50            ),
        .reset(reset             ),
        .en   (shift_strobe      ),
        .cnt  (shift_strobe_count)
      );

  //------------------------------------------------------------------------

  logic out_moore_fsm, nout_moore_fsm;
  
  new_moore_fsm
    i_new_moore_fsm
      (
        .clk   (clk_50        ),
        .reset (reset         ),
        .en    (shift_strobe  ),
        .keys  (key_sync      ),
        .anykey(anykey        ),
        .y     (out_moore_fsm ),
        .ny    (nout_moore_fsm)
      );
      

//  moore_fsm
//    i_moore_fsm
//      (
//        .clk  (clk_50       ),
//        .reset(reset        ),
//        .en   (shift_strobe ),
//        .a    (out_reg[0]   ),
//        .y    (out_moore_fsm)
//      );
    
  logic [3:0] moore_fsm_out_count;

  counter #(4)
    i_moore_fsm_out_counter
      (
        .clk  (clk_50                      ),
        .reset(reset                       ),
        .en   (shift_strobe & out_moore_fsm),
        .cnt  (moore_fsm_out_count         )
      );

  //------------------------------------------------------------------------

  logic out_mealy_fsm, nout_mealy_fsm;
  
  new_mealy_fsm
    i_new_mealy_fsm
      (
        .clk   (clk_50        ),
        .reset (reset         ),
        .en    (shift_strobe  ),
        .keys  (key_sync      ),
        .anykey(anykey        ),
        .y     (out_mealy_fsm ),
        .ny    (nout_mealy_fsm)
      );

//  mealy_fsm
//    i_mealy_fsm
//      (
//        .clk  (clk_50       ),
//        .reset(reset        ),
//        .en   (shift_strobe ),
//        .a    (out_reg[0]   ),
//        .y    (out_mealy_fsm)
//      );

  logic [3:0] mealy_fsm_out_count;

  counter #(4)
    i_mealy_fsm_out_counter
      (
        .clk  (clk_50                      ),
        .reset(reset                       ),
        .en   (shift_strobe & out_mealy_fsm),
        .cnt  (mealy_fsm_out_count         )
      );

  //------------------------------------------------------------------------

  wire [15:0] number_to_display =
    {
      shift_strobe_count,
      moore_fsm_out_count,
      mealy_fsm_out_count
    };

  //------------------------------------------------------------------------

  logic seven_segment_strobe;

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
