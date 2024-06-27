//top module
`include "memory_array.sv"
`include "read_pointer.sv"
`include "status_signal.sv"
`include "write_pointer.sv"
 
module fifo_mem(data_out,fifo_full, fifo_empty, fifo_threshold, fifo_overflow, fifo_underflow,clk, rst_n, wr, rd, data_in);  
  parameter data_width=64,
  			pointer_width=11,
  			fifo_depth=1024; 			
  input wr, rd, clk, rst_n;  
  input[data_width-1:0] data_in;   // FPGA projects using Verilog/ VHDL
  output[data_width-1:0] data_out;  
  output fifo_full, fifo_empty, fifo_threshold, fifo_overflow, fifo_underflow;  
  wire[pointer_width-1:0] wptr,rptr;  
  wire fifo_we,fifo_rd;   
  write_pointer top1(wptr,fifo_we,wr,fifo_full,clk,rst_n);  
  read_pointer top2(rptr,fifo_rd,rd,fifo_empty,clk,rst_n);  
  memory_array top3(data_out, data_in, clk,fifo_we, wptr,rptr);  
  status_signal top4(fifo_full, fifo_empty, fifo_threshold, fifo_overflow, fifo_underflow, wr, rd, fifo_we, fifo_rd, wptr,rptr,clk,rst_n);  
endmodule

//memory_array
module memory_array(data_out, data_in, clk,fifo_we, wptr,rptr);  
  parameter data_width=64,
  			pointer_width=11,
  			fifo_depth=1024;
  input[data_width-1:0] data_in;  
  input clk,fifo_we;  
  input[pointer_width-1:0] wptr,rptr;  
  output[data_width-1:0] data_out;  
  reg[data_width-1:0] data_out2[fifo_depth-1:0];  
  wire[data_width-1:0] data_out;  
  always @(posedge clk)  
  begin  
   if(fifo_we)   
     data_out2[wptr[pointer_width-2:0]] <=data_in ;  
  end  
  assign data_out = data_out2[rptr[pointer_width-2:0]];  
endmodule

//write_pointer
module write_pointer(wptr,fifo_we,wr,fifo_full,clk,rst_n);  
  parameter data_width=64,
  			pointer_width=11,
  			fifo_depth=1024;
  input wr,fifo_full,clk,rst_n;  
  output[pointer_width-1:0] wptr;  
  output fifo_we;  
  reg[pointer_width-1:0] wptr;  
  assign fifo_we = (~fifo_full)&wr;  
  always @(posedge clk or negedge rst_n)  
  begin  
    if(~rst_n) wptr <= 11'b000000;  
   else if(fifo_we)  
    wptr <= wptr + 11'b000001;  
   else  
    wptr <= wptr;  
  end  
endmodule

//read_pinter
module read_pointer(rptr,fifo_rd,rd,fifo_empty,clk,rst_n); 
  parameter data_width=64,
  			pointer_width=11,
  			fifo_depth=1024;
  input rd,fifo_empty,clk,rst_n;  
  output[pointer_width-1:0] rptr;  
  output fifo_rd;  
  reg[pointer_width-1:0] rptr;  
  assign fifo_rd = (~fifo_empty)& rd;  
  always @(posedge clk or negedge rst_n)  
  begin  
    if(~rst_n) rptr <= 11'b000000;  
   else if(fifo_rd)  
    rptr <= rptr + 11'b000001;  
   else  
    rptr <= rptr;  
  end  
endmodule

//status_signal
module status_signal(fifo_full, fifo_empty, fifo_threshold, fifo_overflow, fifo_underflow, wr, rd, fifo_we, fifo_rd, wptr,rptr,clk,rst_n);  
  parameter data_width=64,
  			pointer_width=11,
  			fifo_depth=1024;
  input wr, rd, fifo_we, fifo_rd,clk,rst_n;  
  input[pointer_width-1:0] wptr, rptr;  
  output fifo_full, fifo_empty, fifo_threshold, fifo_overflow, fifo_underflow;  
  wire fbit_comp, overflow_set, underflow_set;  
  wire pointer_equal;  
  wire[10:0] pointer_result;  
  reg fifo_full, fifo_empty, fifo_threshold, fifo_overflow, fifo_underflow;  
  assign fbit_comp = wptr[pointer_width-1] ^ rptr[pointer_width-1];  
  assign pointer_equal = (wptr[pointer_width-2:0] - rptr[pointer_width-2:0]) ? 0:1;  
  assign pointer_result = wptr[pointer_width-1:0] - rptr[pointer_width-1:0];  
  assign overflow_set = fifo_full & wr;  
  assign underflow_set = fifo_empty&rd;  
  always @(*)  
  begin  
   fifo_full =fbit_comp & pointer_equal;  
   fifo_empty = (~fbit_comp) & pointer_equal;  
    fifo_threshold = (pointer_result[pointer_width-1]||pointer_result[pointer_width-2]) ? 1:0;  
  end  
  always @(posedge clk or negedge rst_n)  
  begin  
  if(~rst_n) fifo_overflow <=0;  
  else if((overflow_set==1)&&(fifo_rd==0))  
   fifo_overflow <=1;  
   else if(fifo_rd)  
    fifo_overflow <=0;  
    else  
     fifo_overflow <= fifo_overflow;  
  end  
  always @(posedge clk or negedge rst_n)  
  begin  
  if(~rst_n) fifo_underflow <=0;  
  else if((underflow_set==1)&&(fifo_we==0))  
   fifo_underflow <=1;  
   else if(fifo_we)  
    fifo_underflow <=0;  
    else  
     fifo_underflow <= fifo_underflow;  
  end  
endmodule
