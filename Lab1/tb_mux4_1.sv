`timescale 1ns/1ps

module tb_mux4_1;
  logic [5:0] count;
  logic muxOut;

  mux4_1 dut(
    .f   (muxOut),
    .a   (count[5]),
    .b   (count[4]),
    .c   (count[3]),
    .d   (count[2]),
    .sel (count[1:0])
  );

  initial begin
    $monitor($time, " a=%b | b=%b | c=%b | d=%b | sel=%b | out=%b",
             count[5], count[4], count[3], count[2], count[1:0], muxOut);

    for(count = 0; count <= 6'b111111; count++) #10;

    #10 $finish;
  end

endmodule: tb_mux4x1

