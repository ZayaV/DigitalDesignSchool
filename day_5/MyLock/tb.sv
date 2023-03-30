`timescale 1 ns / 1 ps

module tb();
	logic clk;
	logic reset;
	logic sw_in;
	logic sw_out;
	
	sync_and_debounce_one DUT(.*);
	
	initial
		begin
			clk = 1'b0;

			forever
				# 10 clk = ~clk;
		end
		
	initial
		begin
			reset = '0;
			sw_in = '0;
			
			#5 reset = '1;
			#20 reset = '0;
			
			
			#10 sw_in = '1;
			
			#20000 sw_in = '0;
			
			#10000
			$finish;
		end

endmodule //tb