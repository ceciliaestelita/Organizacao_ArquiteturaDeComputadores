// multiplier_top_refined.sv
// Modulo top-level da unidade de multiplicacao refinada (32 bits → 64 bits)
// Baseado na Figura 3.5 - Patterson & Hennessy, Computer Organization and Design
//
// Conecta o datapath refinado (multiplier_datapath_refined) e
// a FSM de controle refinada (multiplier_control_refined).
//
// Principais diferencas em relacao ao top original:
//   - ALU interna e de 32 bits (nao 64)
//   - Registrador de produto tem 65 bits (bit extra para carry-out)
//   - Nao ha registrador separado para o multiplicador
//   - O multiplicador e carregado em product_reg[31:0] na fase LOAD
//   - O shift_en desloca os 65 bits de product_reg para a direita
//
// Temporizacao:
//   1 ciclo  — LOAD
//   32 x 2   — ADD_OR_SKIP + SHIFT por bit
//   Total:  ~66 ciclos ate DONE
//
// Uso:
//   1. Apresentar operandos em 'multiplicand_in' e 'multiplier_in'
//   2. Setar 'start' por pelo menos 1 ciclo
//   3. Aguardar 'done'
//   4. Ler 'product' (64 bits)
//   5. Resetar 'start' para nova operacao

module multiplier_top_refined (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        start,
    input  logic [31:0] multiplicand_in,
    input  logic [31:0] multiplier_in,

    output logic [63:0] product,
    output logic        done
);

    // -----------------------------------------------------------------------
    // Sinais internos entre controle e datapath
    // -----------------------------------------------------------------------
    logic load;
    logic product_wr;
    logic shift_en;
    logic product_lsb;

    // -----------------------------------------------------------------------
    // Instancia do datapath refinado
    // -----------------------------------------------------------------------
    multiplier_datapath_refined datapath (
        .clk             (clk),
        .rst_n           (rst_n),
        .multiplicand_in (multiplicand_in),
        .multiplier_in   (multiplier_in),
        .load            (load),
        .product_wr      (product_wr),
        .shift_en        (shift_en),
        .product_lsb     (product_lsb),
        .product         (product)
    );

    // -----------------------------------------------------------------------
    // Instancia da FSM de controle refinada
    // -----------------------------------------------------------------------
    multiplier_control_refined control (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (start),
        .done        (done),
        .product_lsb (product_lsb),
        .load        (load),
        .product_wr  (product_wr),
        .shift_en    (shift_en)
    );

endmodule
