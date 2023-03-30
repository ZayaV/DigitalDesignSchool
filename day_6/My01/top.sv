
module top
#(
  parameter clk_mhz = 50
)
(
  input   logic       clk_50,
  input   logic [0:0] b_sw,

  output  logic [7:0] seg,
  output  logic [3:0] dig,

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


  logic [15:0] prev_value;
  logic [19:0] counter;
  logic [19:0] distance;

  localparam [15:0] threshold = 16'h1100; // threshold for note. higher than zero for noise filtration

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

    
  // Задание 1. Заполнить таблицу параметров в соответствии с частотами нот четвертой октавы в Гц.
  // Сейчас здесь правильная нота только C(До)=261.63 Гц и A(Ля)=440.00 Гц

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

  function [19:0] high_distance(input [18:0] freq_100);            // Пересчёт частоты ноты в число тактов 
    high_distance = clk_mhz * 1000 * 1000 / freq_100 * 104;        // основной частоты clk_50 50MHZ +4% (50MHz/f)*(104/100)
  endfunction

  //------------------------------------------------------------------------

  function [19:0] low_distance(input [18:0] freq_100);             // Пересчёт частоты ноты в число тактов 
    low_distance = clk_mhz * 1000 * 1000 / freq_100 * 96;          // основной частоты clk_50 50MHZ -4% (50MHz/f)*(96/100)
  endfunction

  //------------------------------------------------------------------------

  function [19:0] check_freq_single_range(input [18:0] freq_100);  // Проверяем входит ли число посчитанных тактов distance 
    check_freq_single_range = distance > low_distance(freq_100)    // в диапазон тактов, который вычисляли выше
                            & distance < high_distance(freq_100);
  endfunction

  //------------------------------------------------------------------------

  function [19:0] check_freq(input [18:0] freq_100);               // Проверяем ноту на следующие две верхних октавы, 
    check_freq = check_freq_single_range(freq_100 * 4)             // так как частота каждой октавы отличается ровно в 2 раза
               | check_freq_single_range(freq_100 * 2)
               | check_freq_single_range(freq_100);
  endfunction

  //------------------------------------------------------------------------

  wire check_C = check_freq(freq_100_C);
  wire check_Cs = check_freq(freq_100_Cs);
  wire check_D = check_freq(freq_100_D);
  wire check_Ds = check_freq(freq_100_Ds);
  wire check_E = check_freq(freq_100_E);
  wire check_F = check_freq(freq_100_F);
  wire check_Fs = check_freq(freq_100_Fs);
  wire check_G = check_freq(freq_100_G);
  wire check_Gs = check_freq(freq_100_Gs);
  wire check_A = check_freq(freq_100_A);
  wire check_As = check_freq(freq_100_As);
  wire check_B = check_freq(freq_100_B);

  //------------------------------------------------------------------------

  localparam w_note = 12;

  wire [w_note - 1:0] note = {check_C, check_Cs, check_D, check_Ds,
                              check_E, check_F, check_Fs, check_G,
                              check_Gs, check_A, check_As, check_B};

  localparam [w_note - 1:0] no_note = '0,
                            C = 12'b1000_0000_0000,
                            Cs = 12'b0100_0000_0000,
                            D = 12'b0010_0000_0000,
                            Ds = 12'b0001_0000_0000,
                            E = 12'b0000_1000_0000,
                            F = 12'b0000_0100_0000,
                            Fs = 12'b0000_0010_0000,
                            G = 12'b0000_0001_0000,
                            Gs = 12'b0000_0000_1000,
                            A = 12'b0000_0000_0100,
                            As = 12'b0000_0000_0010,
                            B = 12'b0000_0000_0001;

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
  //  The output to seven segment display
  //
  //------------------------------------------------------------------------

  always_ff @(posedge clk_50 or posedge reset)
    if (reset)
      seg <= 8'b11111111;
    else
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

  assign dig = 4'b1110;

  //------------------------------------------------------------------------
  // Задание 2. Вывести на семисегментные индикаторы буквы С О Л Ь, когда микрофон распознает ноту G
  // Сейчас здесь выводится "0" на все разряды

  logic [31:0] cnt;
    
  always_ff @(posedge clk_50 or posedge reset)
    if (reset)
      cnt <= '0;
    else
      cnt <= cnt + 1'b1;

  wire enable = (cnt [17:0] == '0);
  logic [3:0] shift_reg;
    
  always_ff @(posedge clk_50 or posedge reset)
    if (reset)
      shift_reg <= 4'b0001;
    else if (enable)
      shift_reg <= {shift_reg [0], shift_reg [3:1]};

    
  enum bit [7:0] 
    {
        o = 8'b00000011,
        n = 8'b00010011,
        c = 8'b01100011,
        b = 8'b11000001,
        x = 8'b11111111
    } letter;
    
  always_comb
    case (shift_reg)
      4'b1000: letter = c;
      4'b0100: letter = o;
      4'b0010: letter = n;
      4'b0001: letter = b;
      default: letter = c;
    endcase

//  assign seg = (t_note == C) ? letter : x;
//  assign digit = ~shift_reg;

endmodule
