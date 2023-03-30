module top
#(
  parameter clk_mhz = 50
)
(
  input   logic        clk_50,
  input   logic [0:0]  b_sw,

  output  logic [7:0]  seg,
  output  logic [3:0]  dig,

  inout   logic [13:0] gpio
);

  wire reset = ~b_sw;

  //------------------------------------------------------------------------
  //
  //  The microphone receiver
  //
  //------------------------------------------------------------------------

  wire [15:0] value;

  digilent_pmod_mic3_spi_receiver
    i_microphone
      (
        .clk  (clk_50 ),
        .reset(reset  ),
        .cs   (gpio[0]), 
        .sck  (gpio[6]),
        .sdo  (gpio[4]),
        .value(value  )
      );

  assign gpio [8] = '0;  // GND
  assign gpio [10] = '1; // VCC

  //------------------------------------------------------------------------
  //
  //  Measuring frequency
  //
  //------------------------------------------------------------------------

  // It is enough for the counter to be 20 bit. Why?

  logic [15:0] prev_value;
  logic [19:0] counter;
  logic [19:0] distance;

  localparam [15:0] threshold = 16'h1100;

  always_ff @(posedge clk_50 or posedge reset)
    if (reset)
      begin
        prev_value <= '0;
        counter <= '0;
        distance <= '0;
      end
     else
      begin
        prev_value <= value;

        if (value >= threshold
            & prev_value < threshold)
          begin
            distance <= counter;
            counter <= '0;
          end
        else if (counter != '1)  // To prevent overflow
          counter <= counter + 1'b1;
      end

  //------------------------------------------------------------------------
  //
  //  Determining the note
  //
  //------------------------------------------------------------------------

  // Custom measured frequencies

  localparam freq_100_C  = 26163,
             freq_100_Cs = 27718,
             freq_100_D  = 29366,
             freq_100_Ds = 31113,
             freq_100_E  = 32963,
             freq_100_F  = 34923,
             freq_100_Fs = 36999,
             freq_100_G  = 39200,
             freq_100_Gs = 41530,
             freq_100_A  = 44000,
             freq_100_As = 46616,
             freq_100_B  = 49388;


  //------------------------------------------------------------------------

  function [19:0] high_distance(input [18:0] freq_100);
    high_distance = clk_mhz * 1000 * 1000 / freq_100 * 104;
  endfunction

  //------------------------------------------------------------------------

  function [19:0] low_distance(input [18:0] freq_100);
    low_distance = clk_mhz * 1000 * 1000 / freq_100 * 96;
  endfunction

  //------------------------------------------------------------------------

  function [19:0] check_freq_single_range(input [18:0] freq_100);
    check_freq_single_range = distance > low_distance(freq_100)
                            & distance < high_distance(freq_100);
  endfunction

  //------------------------------------------------------------------------

  function [19:0] check_freq(input [18:0] freq_100);
    check_freq = check_freq_single_range(freq_100 * 4)
               | check_freq_single_range(freq_100 * 2)
               | check_freq_single_range(freq_100);

  endfunction

  //------------------------------------------------------------------------

  wire check_C  = check_freq(freq_100_C );
  wire check_Cs = check_freq(freq_100_Cs);
  wire check_D  = check_freq(freq_100_D );
  wire check_Ds = check_freq(freq_100_Ds);
  wire check_E  = check_freq(freq_100_E );
  wire check_F  = check_freq(freq_100_F );
  wire check_Fs = check_freq(freq_100_Fs);
  wire check_G  = check_freq(freq_100_G );
  wire check_Gs = check_freq(freq_100_Gs);
  wire check_A  = check_freq(freq_100_A );
  wire check_As = check_freq(freq_100_As);
  wire check_B  = check_freq(freq_100_B );

  //------------------------------------------------------------------------

  localparam w_note = 12;

  wire [w_note - 1:0] note = {check_C, check_Cs, check_D, check_Ds,
                              check_E, check_F, check_Fs, check_G,
                              check_Gs, check_A, check_As, check_B};

  localparam [w_note - 1:0] no_note = '0,
                            C  = 12'b1000_0000_0000,
                            Cs = 12'b0100_0000_0000,
                            D  = 12'b0010_0000_0000,
                            Ds = 12'b0001_0000_0000,
                            E  = 12'b0000_1000_0000,
                            F  = 12'b0000_0100_0000,
                            Fs = 12'b0000_0010_0000,
                            G  = 12'b0000_0001_0000,
                            Gs = 12'b0000_0000_1000,
                            A  = 12'b0000_0000_0100,
                            As = 12'b0000_0000_0010,
                            B  = 12'b0000_0000_0001;

  localparam [w_note - 1:0] Df = Cs, Ef = Ds, Gf = Fs, Af = Gs, Bf = As;

  //------------------------------------------------------------------------
  //
  //  Note filtering
  //
  //------------------------------------------------------------------------

  logic [w_note - 1:0] d_note;  // Delayed note

  always_ff @(posedge clk_50 or posedge reset)
    if (reset)
      d_note <= no_note;
    else
      d_note <= note;

  logic [17:0] t_cnt;           // Threshold counter
  logic [w_note - 1:0] t_note;  // Thresholded note

  always_ff @(posedge clk_50 or posedge reset)
    if (reset)
      t_cnt <= '0;
    else
      if (note == d_note)
        t_cnt <= t_cnt + 1;
      else
        t_cnt <= '0;

  always_ff @(posedge clk_50 or posedge reset)
    if (reset)
      t_note <= no_note;
    else
      if (&t_cnt)
        t_note <= d_note;

  //------------------------------------------------------------------------
  //
  //  FSMs
  //
  //------------------------------------------------------------------------

  localparam w_state = 4;  // Let's keep to 16 states
  localparam n_fsms  = 3;

  localparam [3:0] recognized = '1;

  logic [w_state - 1:0] states[0:n_fsms - 1];

  //------------------------------------------------------------------------

  /*
   * Задание 1:
   * Изменить набор мелодий. Закодировать свою мелодию
   */

//`define SONGS_123
`define SONGS_456

`ifdef SONGS_123

  // No 1. Simple sequence

  always_ff @(posedge clk_50 or posedge reset)
    if (reset)
      states[2] <= '0;
    else
      case (states[2])
        0: if (t_note == C) states[2] <= 'd1;
        1: if (t_note == A) states[2] <= 'd2;
        2: if (t_note == D) states[2] <= 'd3;
        3: if (t_note == C) states[2] <= 'd4;
        4: if (t_note == A) states[2] <= recognized;            
      endcase

  // No 2. Fur Elize

  always_ff @(posedge clk_50 or posedge reset)
    if (reset)
      states[0] <= '0;
    else
      case (states[0])
        0: if (t_note == E) states[0] <= 'd1;
        1: if (t_note == Ef) states[0] <= 'd2;
        2: if (t_note == E) states[0] <= 'd3;
        3: if (t_note == Ef) states[0] <= 'd4;
        4: if (t_note == E) states[0] <= 'd5;
        5: if (t_note == B) states[0] <= 'd6;
        6: if (t_note == D) states[0] <= 'd7;
        7: if (t_note == C) states[0] <= 'd8;
        8: if (t_note == A) states[0] <= recognized;
      endcase

  // No 3. Godfather

  always_ff @(posedge clk_50 or posedge reset)
    if (reset)
      states[1] <= '0;
    else
      case (states[1])
        0: if (t_note == G) states[1] <= 'd1;
        1: if (t_note == C) states[1] <= 'd2;
        2: if (t_note == Ef) states[1] <= 'd3;
        3: if (t_note == D) states[1] <= 'd4;
        4: if (t_note == C) states[1] <= 'd5;
        5: if (t_note == Ef) states[1] <= 'd6;
        6: if (t_note == C) states[1] <= 'd7;
        7: if (t_note == D) states[1] <= 'd8;
        8: if (t_note == C) states[1] <= 'd9;
        9: if (t_note == Af) states[1] <= 'd10;
       10: if (t_note == Bf) states[1] <= 'd11;
       11: if (t_note == G) states[1] <= recognized;
      endcase

`elsif SONGS_456

  // No 4. Fly away on the wings of wind

  always_ff @(posedge clk_50 or posedge reset)
    if (reset)
      states[0] <= '0;
    else
      case (states[0])
        0: if (t_note == G) states[0] <= 'd1;
        1: if (t_note == D) states[0] <= 'd2;
        2: if (t_note == C) states[0] <= 'd3;
        3: if (t_note == D) states[0] <= 'd4;
        4: if (t_note == Bf) states[0] <= 'd5;
        5: if (t_note == A) states[0] <= 'd6;
        6: if (t_note == G) states[0] <= 'd7;
        7: if (t_note == A) states[0] <= 'd8;
        8: if (t_note == Bf) states[0] <= 'd9;
        9: if (t_note == C) states[0] <= 'd10;
        10: if (t_note == D) states[0] <= 'd11;
        11: if (t_note == A) states[0] <= 'd12;
        12: if (t_note == G) states[0] <= 'd13;
        13: if (t_note == F) states[0] <= 'd14;
        14: if (t_note == D) states[0] <= recognized;
      endcase

  // No 5. Winged Swing

  always_ff @(posedge clk_50 or posedge reset)
    if (reset)
      states[1] <= '0;
    else
      case (states[1])
        0: if (t_note == A) states[1] <= 'd1;
        1: if (t_note == Fs) states[1] <= 'd2;
        2: if (t_note == G) states[1] <= 'd3;
        3: if (t_note == Fs) states[1] <= 'd4;
        4: if (t_note == E) states[1] <= 'd5;
        5: if (t_note == B) states[1] <= 'd6;
        6: if (t_note == A) states[1] <= 'd7;
        7: if (t_note == Gs) states[1] <= 'd8;
        8: if (t_note == A) states[1] <= 'd9;
        9: if (t_note == D) states[1] <= 'd10;
        10: if (t_note == C) states[1] <= 'd11;
        11: if (t_note == Bf) states[1] <= 'd12;
        12: if (t_note == A) states[1] <= 'd13;
        13: if (t_note == B) states[1] <= 'd14;
        14: if (t_note == A) states[1] <= recognized;
      endcase

  // No 6. Yesterday by Beatles

  always_ff @(posedge clk_50 or posedge reset)
    if (reset)
      states[2] <= '0;
    else
      case (states[2])
        0: if (t_note == G) states[2] <= 'd1;
        1: if (t_note == F) states[2] <= 'd2;
        2: if (t_note == A) states[2] <= 'd3;
        3: if (t_note == B) states[2] <= 'd4;
        4: if (t_note == Cs) states[2] <= 'd5;
        5: if (t_note == D) states[2] <= 'd6;
        6: if (t_note == E) states[2] <= 'd7;
        7: if (t_note == F) states[2] <= 'd8;
        8: if (t_note == E) states[2] <= 'd9;
        9: if (t_note == D) states[2] <= 'd10;
        10: if (t_note == C) states[2] <= 'd11;
        11: if (t_note == Bf) states[2] <= 'd12;
        12: if (t_note == A) states[2] <= 'd13;
        13: if (t_note == G) states[2] <= 'd14;
        14: if (t_note == Bf) states[2] <= recognized;
      endcase

`endif

  //------------------------------------------------------------------------
  //
  //  The dynamic seven segment display logic
  //
  //------------------------------------------------------------------------

  logic [15:0] digit_enable_cnt;

  always_ff @(posedge clk_50 or posedge reset)
    if (reset)
      digit_enable_cnt <= '0;
    else
      digit_enable_cnt <= digit_enable_cnt + 1'b1;

  wire digit_enable = &digit_enable_cnt;

  //------------------------------------------------------------------------

  logic [1:0] i_digit_r;
  wire [1:0] i_digit = i_digit_r + 1'b1;

  always_ff @(posedge clk_50 or posedge reset)
    if (reset)
      begin
        i_digit_r <= '0;
        dig <= '0;
      end
    else if (digit_enable)
      begin
        i_digit_r <= i_digit;
        dig <= ~(4'b1 << i_digit);
      end

  //------------------------------------------------------------------------
  //
  //  The output to seven segment display
  //
  //------------------------------------------------------------------------

    always_ff @ (posedge clk_50 or posedge reset)
      if (reset)
        seg <= '1;
      else if (digit_enable)
        if (i_digit == '1)
          case (t_note)
            C  : seg <= 8'b01100011;  // C   // seg
            Cs : seg <= 8'b01100010;  // C#
            D  : seg <= 8'b10000101;  // D   //   --a-- 
            Ds : seg <= 8'b10000100;  // D#  //  |     |
            E  : seg <= 8'b01100001;  // E   //  f     b
            F  : seg <= 8'b01110001;  // F   //  |     |
            Fs : seg <= 8'b01110000;  // F#  //   --g-- 
            G  : seg <= 8'b01000011;  // G   //  |     |
            Gs : seg <= 8'b01000010;  // G#  //  e     c
            A  : seg <= 8'b00010001;  // A   //  |     |
            As : seg <= 8'b00010000;  // A#  //   --d--  h
            B  : seg <= 8'b11000001;  // B
            default : seg <= 8'b11111111;
          endcase
        else if (i_digit < n_fsms)
          case (states [n_fsms - 1 - i_digit])
            4'h0: seg <= 8'b00000011;
            4'h1: seg <= 8'b10011111;
            4'h2: seg <= 8'b00100101;
            4'h3: seg <= 8'b00001101;
            4'h4: seg <= 8'b10011001;
            4'h5: seg <= 8'b01001001;
            4'h6: seg <= 8'b01000001;
            4'h7: seg <= 8'b00011111;
            4'h8: seg <= 8'b00000001;
            4'h9: seg <= 8'b00011001;
            4'ha: seg <= 8'b00010001;
            4'hb: seg <= 8'b11000001;
            4'hc: seg <= 8'b01100011;
            4'hd: seg <= 8'b10000101;
            4'he: seg <= 8'b01100001;
            // 4'hf: seg <= 8'b01110001;  // F
            4'hf: seg <= 8'b00111001;  // Upper o - recognized
          endcase
        else
          seg <= 8'b11111111;

endmodule: top
