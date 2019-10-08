//PAL16L8_053326_D21_TEST.v
//PAL 053327-D21 Testbench.
//used in Aliens Konami Arcade PCB.
//Author: RndMnkIII. 10/2019. (@RndMnkIII).
//---------------------------------------------------------
//iverilog -o pald21_sim PAL16L8_053326_D21.v PAL16L8_053326_D21_TEST.v
//vvp pald21_sim
//gtkwave PAL16L8_053326_D21_TEST.vcd

`timescale 1ns / 1ns
module PAL16L8_053326_D21_TEST;
  reg [9:0] x;
  reg AS, BK4, INIT, MAF, MAE, MAD, MAC, MAB, MAA, WOCO;
  wire D20_8, WORK, BANK, D20_13, D20_16, D18_5__D20_2, PROG, C19_1;

  //PAL16L8_053326_D21 pald21(in, out);
  PAL16L8_053326_D21 pald21(.in({AS,BK4,INIT,MAF,MAE,MAD,MAC,MAB,MAA,WOCO}), .out({D20_8, WORK, BANK, D20_13, D20_16, D18_5__D20_2, PROG, C19_1}));
  
  initial
    begin
	  $dumpfile ("PAL16L8_053326_D21_TEST.vcd");
	  $dumpvars (0, PAL16L8_053326_D21_TEST); //0 all variables included
      $monitor ($time,"\nInputs:\nAS\tBK4\tINIT\tMAF\tMAE\tMAD\tMAC\tMAB\tMAA\tWOCO\n--\t---\t----\t---\t---\t---\t---\t---\t---\t----\n%b\t%b\t%b\t%b\t%b\t%b\t%b\t%b\t%b\t%b\n\nOutputs:\nD20_8\tWORK\tBANK\tD20_13\tD20_16\tD18_5\tPROG\tC19_1\n-----\t----\t----\t-----\t------\t-----\t----\t-----\n%b\t%b\t%b\t%b\t%b\t%b\t%b\t%b\n\n----------------------------------------------------------------------------\n\n", AS, BK4, INIT, MAF, MAE, MAD, MAC, MAB, MAA, WOCO,D20_8, WORK, BANK, D20_13, D20_16, D18_5__D20_2, PROG, C19_1);
	  
	for (x=0; x < 1023; x= x+1)
		begin
			#10 ; {AS, BK4, INIT, MAF, MAE, MAD, MAC, MAB, MAA, WOCO} = x;
		end // end of for loop 
      #10 $finish;
    end
endmodule