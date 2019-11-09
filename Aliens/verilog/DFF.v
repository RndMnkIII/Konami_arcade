// D flip-flop with set and clear; positive-edge-triggered
// DFF.v
`timescale 1ns / 1ns
module DFF #(parameter DELAY_RISE = 14, DELAY_FALL = 10)
(
        Clk,
        reset,
        D,
        set,
        Q
        );
        
//list the inputs 
    input Clk;
     input reset;
     input D;
     input set;
//list the outputs 
    output Q;
//Internal variables
     reg Q_current;
     
    //flip flop state is affected only on postive edge of clock 
    always @(posedge(Clk) or negedge (reset) or negedge(set))
    begin
        if (reset == 1) //check for active high reset
            Q_current = 1'b0;  
        else if(set == 1)   //check for set
            Q_current = 1'b1; 
        else if (Clk == 1) //check if clock is enabled
            Q_current = D;       
  
    end 

    assign #(DELAY_RISE, DELAY_FALL) Q = Q_current;
endmodule