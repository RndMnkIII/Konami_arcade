//PAL16L8_053326_D21.v
//Implementation of PAL 053326-D21 combinatorial logic
//used in Aliens Konami Arcade PCB.
//Converted to Verilog By RndMnkIII. 10/2019. (@RndMnkIII).
//---------------------------------------------------------
//Dumped from an unsecured PAL16L8, 
//converted to GAL16V8 with PALTOGAL 
//and tested by Caius (@Caius63417737).
//---------------------------------------------------------
`timescale 1ns / 1ns
module PAL16L8_053326_D21(in, out);
	input [9:0] in;
	//wire [9:0] in;
	output [7:0] out;
	
	assign #5 out[0] =  ~(~in[3] & ~in[4] & ~in[5] & ~in[6] & ~in[7] & ~in[8] & in[9]);
	
	assign #5 out[1] =  ~((~in[0] & ~in[3] & ~in[4] & ~in[5] & ~in[6] & ~in[7] & in[8]) |
       (~in[0] & ~in[3] & ~in[4] & ~in[5] & ~in[6] & in[7]) |
       (~in[0] & ~in[3] & ~in[4] & ~in[5] & in[6]) |
       (~in[0] & ~in[3] & ~in[4] & ~in[5] & ~in[6] & ~in[7] & ~in[8] & ~in[0]));
	   
	   
	assign #5 out[2] = ~(~in[0] & ~in[1] & ~in[3] & ~in[4] & in[5]);
	   
	assign #5 out[3] = ~(~in[0] & ~in[3] & in[4] & ~in[5] & in[6] & in[7] & in[8]);
	   
	assign #5 out[4] = ~(in[2] & ~in[3] & in[4] & in[5] & in[6] & in[7]);

	assign #5 out[5] = ~((~in[0] & ~in[3] & in[4]) |
       (~in[0] & ~in[3] & ~in[4] & ~in[5] & ~in[6] & ~in[7] & ~in[8] & in[9]));

	assign #5 out[6] = ~((~in[0] & in[3]) |
       (~in[0] & in[1] & ~in[3] & ~in[4] & in[5]));

	assign #5 out[7] = ~((~in[0] & in[3]) |
       (~in[0] & in[1] & ~in[3] & ~in[4] & in[5]) |
       (~in[0] & ~in[3] & ~in[4] & ~in[5] & ~in[6] & ~in[7] & in[8]) |
       (~in[0] & ~in[3] & ~in[4] & ~in[5] & ~in[6] & in[7]) |
       (~in[0] & ~in[3] & ~in[4] & ~in[5] & in[6]) |
       (~in[0] & ~in[3] & ~in[4] & ~in[5] & ~in[6] & ~in[7] & ~in[8] & ~in[9]) |
       (~in[0] & ~in[1] & ~in[3] & ~in[4] & in[5]));
endmodule	   