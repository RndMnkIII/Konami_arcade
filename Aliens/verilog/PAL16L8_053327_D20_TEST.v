//PAL16L8_053327_D20_TEST.v
//PAL 053327-D20 Testbench.
//used in Aliens Konami Arcade PCB.
//Author: RndMnkIII. 10/2019. (@RndMnkIII).
//---------------------------------------------------------
//iverilog -o pald20_sim PAL16L8_053327_D20.v PAL16L8_053327_D20_TEST.v
//vvp pald20_sim
//gtkwave PAL16L8_053327_D20_TEST.vcd

`timescale 1ns / 1ns
module PAL16L8_053327_D20_TEST;
  reg [12:0] x;
  reg D18_5, D21_17, RMRD, MAA, MA9, MA8, MA7, D21_12, C20_6, C20_3, D21_15, D21_16;
  wire C20_9, IOCS, CRAMCS, VRAMCS, OBJCS;

  PAL16L8_053327_D20 pald20(.in({D18_5, D21_17, RMRD, MAA, MA9, MA8, MA7, D21_12, C20_6, C20_3, D21_15, D21_16}), .out({C20_9, IOCS, CRAMCS, VRAMCS, OBJCS}));
  
  initial
    begin
	  $dumpfile ("PAL16L8_053327_D20_TEST.vcd");
	  $dumpvars (0, PAL16L8_053327_D20_TEST); //0 all variables included
	  $monitor ($time,"\nInputs:\nD18_5\tD21_17\tRMRD\tMAA\tMA9\tMA8\tMA7\tD21_12\tC20_6\tC20_3\tD21_15\tD21_16\n-----\t------\t----\t---\t---\t---\t---\t------\t-----\t-----\t------\t------\n%b\t%b\t%b\t%b\t%b\t%b\t%b\t%b\t%b\t%b\t%b\t%b\n\nOutputs:\nC20_9\tIOCS\tCRAMCS\tVRAMCS\tOBJCS\n-----\t----\t------\t------\t-----\n%b\t%b\t%b\t%b\t%b\n\n----------------------------------------------------------------------------\n\n",D18_5, D21_17, RMRD, MAA, MA9, MA8, MA7, D21_12, C20_6, C20_3, D21_15, D21_16, C20_9, IOCS, CRAMCS, VRAMCS, OBJCS);
	  
	for (x=0; x < 4096; x= x+1)
		begin
    //Suponemos un periodo máximo de 1/25MHz
			#40 ; {D18_5, D21_17, RMRD, MAA, MA9, MA8, MA7, D21_12, C20_6, C20_3, D21_15, D21_16} = x[11:0];
		end // end of for loop 
      #40 $finish;
    end
endmodule