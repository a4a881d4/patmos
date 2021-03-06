`timescale 1 ns / 100 ps

module Patmos_tb();
   Patmos patmos(.clk(clk), .reset(reset),
				 .io_dummy(io_dummy),
				 .io_led(io_led),
				 .io_uartPins_tx(io_uartPins_tx),
				 .io_uartPins_rx(io_uartPins_rx));

   reg clk_reg;
   reg reset_reg;   
   assign clk = clk_reg;
   assign reset = reset_reg;   
   
   initial
	 begin
		$display($time, " << Starting the Simulation >>");
		clk_reg = 1'b0;
		reset_reg = 1'b1;
		#100 reset_reg = 1'b0;
	 end
   always
	 #5 clk_reg = ~clk_reg;

   reg [9:0] data;
   integer i;
   reg rx;
   assign io_uartPins_rx = rx;
   
   always
	 begin
		#1000 rx = 1'b1;

   		data = 10'b0010101011;
		for (i = 9; i >= 0; i = i-1)
		  begin
			 #8681 rx = data[i];
		  end
	 end
   
endmodule