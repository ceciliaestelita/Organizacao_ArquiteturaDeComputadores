// multiplier_datapath_refined.sv
// Datapath da unidade de multiplicacao refinada (32 bits → produto de 64 bits)
// Baseado na Figura 3.5 - Patterson & Hennessy, Computer Organization and Design
//
// Diferenca fundamental em relacao ao datapath original (Figura 3.3):
//
//   ORIGINAL                          REFINADO
//   ─────────────────────────────     ──────────────────────────────────────
//   multiplicand_reg [63:0]           multiplicand_reg [31:0]  (fixo, sem shift)
//   multiplier_reg   [31:0]           (eliminado — multiplicador fica em product_reg[31:0])
//   product_reg      [64:0]           product_reg [64:0]  (65 bits)
//   ALU              64 bits          ALU 32 bits (opera em product_reg[63:32])
//   shift: multiplicand << 1          shift: product_reg >> 1 (65 bits inteiros)
//          multiplier   >> 1
//
// Algoritmo por iteracao (Figura 3.5):
//   1. Testa product_reg[0] (era Multiplier0 — agora e o LSB do produto)
//   2. Se 1: product_reg[64:32] += multiplicand_reg   (carry → product_reg[64])
//   3. Shift right logico de 1 bit em product_reg[64:0]
//
// Inicializacao:
//   product_reg[31:0]  ← multiplier_in   (multiplicador na parte baixa)
//   product_reg[63:32] ← 0               (acumulador zerado)
//   product_reg[64]    ← 0               (carry zerado)
//   multiplicand_reg   ← multiplicand_in (32 bits — NAO desloca mais)
//
// Resultado apos 32 iteracoes:
//   product_reg[63:0]  contém o produto de 64 bits

module multiplier_datapath_refined (
    input  logic        clk,
    input  logic        rst_n,

    // Entradas de dados
    input  logic [31:0] multiplicand_in,
    input  logic [31:0] multiplier_in,

    // Sinais de controle vindos da FSM
    input  logic        load,       // Carrega operandos iniciais
    input  logic        product_wr, // Escreve resultado da ALU em product_reg[64:32]
    input  logic        shift_en,   // Shift right logico de 1 bit em product_reg[64:0]

    // Saida de status para a FSM
    output logic        product_lsb, // product_reg[0] — equivale ao Multiplier0 original

    // Saida do resultado
    output logic [63:0] product
);

    // -----------------------------------------------------------------------
    // Registradores internos
    // -----------------------------------------------------------------------
    logic [31:0] multiplicand_reg; // Multiplicando (fixo — sem deslocamento)
    logic [64:0] product_reg;      // Produto de 65 bits (bit 64 = carry extra)

    // -----------------------------------------------------------------------
    // ALU de 32 bits (Figura 3.5)
    // Soma product_reg[63:32] + multiplicand_reg
    // -----------------------------------------------------------------------
    logic [31:0] alu_sum;
    logic        alu_carry;

    alu_32 alu (
        .a         (product_reg[63:32]),
        .b         (multiplicand_reg),
        .sum       (alu_sum),
        .carry_out (alu_carry)
    );

    // -----------------------------------------------------------------------
    // Saidas combinacionais
    // -----------------------------------------------------------------------
    assign product_lsb = product_reg[0];
    assign product     = product_reg[63:0];

    // -----------------------------------------------------------------------
    // Atualizacao dos registradores
    // -----------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            multiplicand_reg <= '0;
            product_reg      <= '0;

        end else if (load) begin
            // Inicializacao: multiplicador nos bits baixos, acumulador zerado
            multiplicand_reg <= multiplicand_in;
            product_reg      <= {1'b0, 32'b0, multiplier_in}; // [64]=0, [63:32]=0, [31:0]=multiplier

        end else begin
            // Passo 1+2: soma condicional (se product_reg[0] == 1)
            if (product_wr)
                product_reg[64:32] <= {alu_carry, alu_sum};

            // Passo 3: shift right logico de 1 bit em todo o registrador de 65 bits
            if (shift_en)
                product_reg <= {1'b0, product_reg[64:1]};
        end
    end

endmodule
