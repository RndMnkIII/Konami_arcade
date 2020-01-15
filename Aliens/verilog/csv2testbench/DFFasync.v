// D Flip Flop with async PRESET
// synchronized with global clock sysclk, 
// uses ck_ce clock enable signal to set the FF value
`default_nettype none
`timescale 1 ns / 100 ps
module DFFasync
( 
	input clk, d, ps,
	output reg q
);
	always @(posedge clk or negedge ps) 
	begin
	 if(!ps) //Preset signal active low
	  q  = #10 1'b1; 
	 else
	  q <= #10 d; 
	end 
endmodule