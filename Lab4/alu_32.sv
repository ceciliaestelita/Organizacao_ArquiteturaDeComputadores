// alu_32.sv
// ALU de 32 bits para a unidade de multiplicacao refinada
// Baseado na Figura 3.5 - Patterson & Hennessy
//
// No multiplicador refinado a ALU opera apenas sobre os 32 bits superiores
// do registrador de produto. O carry-out vai para o bit 64 (bit extra).

module alu_32 (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] sum,
    output logic        carry_out
);
    logic [32:0] result;
    assign result    = {1'b0, a} + {1'b0, b};
    assign sum       = result[31:0];
    assign carry_out = result[32];
endmodule
