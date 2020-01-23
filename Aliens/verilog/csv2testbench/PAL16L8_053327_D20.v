//PAL16L8_053327_D20.v
//Implementation of PAL 053327-D20 combinatorial logic
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
module PAL16L8_053327_D20( 
	input D18_5, D21_17, RMRD, MAA, MA9, MA8, MA7, D21_12, C20_6, C20_3, D21_15, D21_16,
	output D20_12, IOCS, CRAMCS, VRAMCS, OBJCS);
	
	wire R14, R15;
	
	assign #10 D20_12 = ~((~D18_5 & ~RMRD & ~MAA & ~MA9 & ~MA8 & ~MA7 & ~C20_6 & ~C20_3 & ~D21_16) |
       (~D18_5 & ~RMRD & MAA & ~D21_16) |
       (~D18_5 & ~D21_17 & R14 & R15));
	   
	assign #7 R14 = ~(MA9 & MA8 & MA7 & ~C20_6 & ~D21_15);
	
	assign #7 IOCS = R14;
	
	assign #7 R15 = ~((~D18_5 & ~RMRD & ~MAA & ~MA9 & ~MA8 & ~MA7 & ~C20_6 & ~C20_3 & ~D21_16) |
       (~D18_5 & ~RMRD & MAA & ~D21_16));
	   
	assign #7 CRAMCS = ~(~D18_5 & ~D21_12);

	assign #10 VRAMCS = ~(~D18_5 & ~D21_17 & D21_12 & R14 & R15);
	
	assign #7 OBJCS = ~((~D18_5 & ~RMRD & ~MAA & ~MA9 & ~MA8 & ~MA7 & ~C20_6 & ~C20_3 & ~D21_16) |
       (~D18_5 & ~RMRD & MAA & ~D21_16));
endmodule   
