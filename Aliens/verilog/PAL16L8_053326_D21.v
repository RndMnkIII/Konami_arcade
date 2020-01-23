//PAL16L8_053326_D21.v
//Implementation of PAL 053326-D21 combinatorial logic
//used in Aliens Konami Arcade PCB.
//Converted to Verilog By RndMnkIII. 10/2019. (@RndMnkIII).
//---------------------------------------------------------
//Dumped from an unsecured PAL16L8, 
//converted to GAL16V8 with PALTOGAL 
//and tested by Caius (@caiusarcade).
// https://jammarcade.net
//---------------------------------------------------------
`default_nettype none
`timescale 1 ns / 100 ps
module PAL16L8_053326_D21( 
	input AS, BK4, INIT, MAF, MAE, MAD, MAC, MAB, MAA, WOCO,
	output D21_12, WORK, BANK, D21_15, D21_16, D21_17, PROG, D21_19);
	
	assign #7 D21_12 = ~(~MAF & ~MAE & ~MAD & ~MAC & ~MAB & ~MAA & WOCO);
	
	assign #7 WORK = ~((~AS & ~MAF & ~MAE & ~MAD & ~MAC & ~MAB & MAA) |
       (~AS & ~MAF & ~MAE & ~MAD & ~MAC & MAB) |
       (~AS & ~MAF & ~MAE & ~MAD & MAC) |
       (~AS & ~MAF & ~MAE & ~MAD & ~MAC & ~MAB & ~MAA & ~WOCO));
	   
	assign #7 BANK = ~(~AS & ~BK4 & ~MAF & ~MAE & MAD);
	
	assign #7 D21_15 = ~(~AS & ~MAF & MAE & ~MAD & MAC & MAB & MAA);
	
	assign #7 D21_16 = ~(INIT & ~MAF & MAE & MAD & MAC & MAB);
	
	assign #7 D21_17 = ~((~AS & ~MAF & MAE) |
       (~AS & ~MAF & ~MAE & ~MAD & ~MAC & ~MAB & ~MAA & WOCO));
	
	assign #7 PROG = ~((~AS & MAF) |
       (~AS & BK4 & ~MAF & ~MAE & MAD));
	   
	assign #7 D21_19 = ~((~AS & MAF) |
       (~AS & BK4 & ~MAF & ~MAE & MAD) |
       (~AS & ~MAF & ~MAE & ~MAD & ~MAC & ~MAB & MAA) |
       (~AS & ~MAF & ~MAE & ~MAD & ~MAC & MAB) |
       (~AS & ~MAF & ~MAE & ~MAD & MAC) |
       (~AS & ~MAF & ~MAE & ~MAD & ~MAC & ~MAB & ~MAA & ~WOCO) |
       (~AS & ~BK4 & ~MAF & ~MAE & MAD));
endmodule
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
