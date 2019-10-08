//PAL16L8_053326_D21.v
//Implementation of PAL 053327-D20 combinatorial logic
//used in Aliens Konami Arcade PCB.
//Converted to Verilog By RndMnkIII. 10/2019. (@RndMnkIII).
//---------------------------------------------------------
//Dumped from an unsecured PAL16L8, 
//converted to GAL16V8 with PALTOGAL 
//and tested by Caius (@Caius63417737).
//---------------------------------------------------------

module PAL16L8_053327_D20(in, out);
	input [11:0] in;
	output [4:0] out;
	wire o14, o15;
	
	assign o14 = in[4] & in[5] & in[6] & ~in[8] & ~in[10];
	
	assign o15 = ~in[0] & ~in[2] & ~in[3] & ~in[4] & ~in[5] & ~in[6] & ~in[8] & ~in[9] & ~in[11] + ~in[0] & ~in[2] & in[3] & ~in[11];
	
	assign out[0] = ~(~in[0] & ~in[2] & ~in[3] & ~in[4] & ~in[5] & ~in[6] & ~in[8] & ~in[9] & ~in[11] + ~in[0] & ~in[2] & in[3] & ~in[11] + ~in[0] & ~in[1] & o14 & o15);
	
	assign out[1] = ~o14;
	   
	assign out[2] = ~(~in[0] & ~in[7]);

	assign out[3]  = ~(~in[0] & ~in[1] & in[7] & o14 & o15);

	assign out[4]  = ~(~in[0] & ~in[2] & ~in[3] & ~in[4] & ~in[5] & ~in[6] & ~in[8] & ~in[9] & ~in[11] + ~in[0] & ~in[2] & in[3] & ~in[11]);
endmodule	   