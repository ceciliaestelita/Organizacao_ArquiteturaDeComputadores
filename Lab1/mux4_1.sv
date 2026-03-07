module mux4_1 (
  output logic f,
  input  logic a, b, c, d,
  input  logic [1:0] sel
);

  logic f1, f2, f3, f4;
  logic n_sel0, n_sel1;

  not g_ns0(n_sel0, sel[0]),
      g_ns1(n_sel1, sel[1]);

  and g1(f1, a, n_sel1, n_sel0),
      g2(f2, b, n_sel1,  sel[0]),
      g3(f3, c,  sel[1], n_sel0),
      g4(f4, d,  sel[1],  sel[0]);

  or  g5(f, f1, f2, f3, f4);

endmodule
