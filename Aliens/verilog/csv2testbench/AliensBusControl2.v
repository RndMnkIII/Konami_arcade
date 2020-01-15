//`default_nettype none// turn off implicit data types
`timescale 1 ns / 100 ps
module AliensBusControl2
(
	input AS, BK4, INIT, 
	input [12:0] ADRF3,
	input WOCO, 
	input RMRD,
	
	input SYSCLK, CK12_CE, NCK12_CE, CKE, CKQ, CKQ_CE,
	
	output PROG, BANK, WORK,
	output OBJCS, VRAMCS, CRAMCS, IOCS,
	
	output DTAC
);

	wire D21_12, D21_15, D21_16, D21_17, D21_19; //D21 outputs

	wire D20_12; //D20 outputs
	
	wire ASb;
	
	wire C20_6;
	wire C20_3;
	wire C19_3;
	wire C19_6;
	
	wire D18_5;
	wire D18_9;

	assign #7 C20_6 = ADRF3[3] | ADRF3[2];
	
	assign #7 C20_3 = ADRF3[1] | ADRF3[0];
	
	assign #7 C19_3 = D21_19 & IOCS;
	
	assign #7 ASb = ~AS;
	
	PAL16L8_053326_D21 D21(AS, BK4, INIT, ADRF3[12], ADRF3[11], ADRF3[10], ADRF3[9], ADRF3[8], ADRF3[7], WOCO,
   							D21_12, WORK, BANK, D21_15, D21_16, D21_17, PROG, D21_19);
	
	DFFasync D18_1( .clk(CKQ), .d(D21_17), .ps(ASb), .q(D18_5));
	
	DFFasync D18_2( .clk(CK12_CE), .d(C19_3), .ps(ASb), .q(D18_9));
	
	PAL16L8_053327_D20 D20(D18_5, D21_17, RMRD, ADRF3[7], ADRF3[6], ADRF3[5], ADRF3[4], 
	                       D21_12, C20_6, C20_3, D21_15, D21_16,
	                       D20_12, IOCS, CRAMCS, VRAMCS, OBJCS);
	
	assign #7 C19_6 = D18_9 & (~(CKE & CKQ) | D20_12);
	
	//Generates Konami-2 CPU DTAC control input signal
	DFFasync F11_1(.clk(NCK12_CE), .d(C19_6), .ps(ASb), .q(DTAC));
endmodule	