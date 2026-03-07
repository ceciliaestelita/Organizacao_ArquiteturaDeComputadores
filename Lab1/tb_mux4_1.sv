`timescale 1ns/1ps

module tb_mux4_1;

  logic [31:0] a, b, c, d;
  logic [1:0]  sel;
  logic [31:0] muxOut;

  mux4_1 dut(
    .f  (muxOut),
    .a  (a),
    .b  (b),
    .c  (c),
    .d  (d),
    .sel(sel)
  );

  initial begin
    $monitor($time, " sel=%b | a=%h | b=%h | c=%h | d=%h | out=%h",
             sel, a, b, c, d, muxOut);

    // valores distintos de 32 bits em cada entrada
    a = 32'hAAAA_AAAA;
    b = 32'h5555_5555;
    c = 32'hFFFF_0000;
    d = 32'h0000_FFFF;

    // testa os 4 casos de seleção
    sel = 2'b00; #10;  // espera a
    sel = 2'b01; #10;  // espera b
    sel = 2'b10; #10;  // espera c
    sel = 2'b11; #10;  // espera d

    #10 $finish;
  end

endmodule: tb_mux4_1
