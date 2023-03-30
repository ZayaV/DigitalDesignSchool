module rand_shift
(
  input   logic       clk,
  input   logic       reset,
  input   logic       en,
  output  logic [3:0] cnt
);

  always_ff @(posedge clk or posedge reset)
    if (reset)
      cnt <= '1;
    else if (en)
      cnt[3:0] <= {cnt[2:0], cnt[3] ^ cnt[2]};

endmodule: rand_shift