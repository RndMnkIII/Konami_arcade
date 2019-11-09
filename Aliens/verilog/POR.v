`timescale 1ns / 1ps
module POR(
      input reset_a,
      input clk,    
      output reset_s
);
 reg q0,q1,q2;
 
//Always beschreibt die 3 FlipFlop Speicherelemente
always@(posedge clk, reset_a)
begin
 if (reset_a == 1'b0)    //reset_a ist asynchron zu clk
 begin
     q0 &lt;= 1'b0;
     q1 &lt;= 1'b0;
     q2 &lt;= 1'b0;
 end    
 else if (clk == 1'b1)
 begin
     q0 &lt;= reset_a;
     q1 &lt;= q0;
     q2 &lt;= q1;
 end    
end
//nebenläufige kombinatorische Logik
assign reset_s = !(q0 &amp; q1 &amp; q2);
endmodule