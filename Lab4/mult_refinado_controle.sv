// mult_refinado_controle.sv
// FSM de controle da unidade de multiplicacao refinada
// Baseado na Figura 3.5 - Patterson & Hennessy
//
// Diferencas em relacao ao controle original:
//   - O sinal de teste e product_lsb (product_reg[0]) em vez de multiplier_lsb
//   - Nao ha mais deslocamento do multiplicando (shift_en so age no product_reg)
//   - Semantica do shift_en: desloca os 65 bits de product_reg para a direita
//
// Estados (codificacao one-hot, 5 bits):
//
//   IDLE        — aguarda 'start'
//   LOAD        — carrega operandos (1 ciclo); product[31:0] ← multiplier
//   ADD_OR_SKIP — testa product[0]; se 1, habilita escrita da soma da ALU
//   SHIFT       — shift right de 65 bits; incrementa contador
//   DONE        — sinaliza conclusao; aguarda !start para voltar ao IDLE

module mult_refinado_controle (
    input  logic clk,
    input  logic rst_n,

    // Interface com o usuario
    input  logic start,
    output logic done,

    // Interface com o datapath
    input  logic product_lsb, // product_reg[0] — equivale ao Multiplier0

    output logic load,        // Carrega operandos
    output logic product_wr,  // Habilita escrita da ALU em product_reg[64:32]
    output logic shift_en     // Habilita shift right de 65 bits em product_reg
);

    // -----------------------------------------------------------------------
    // Codificacao one-hot
    // -----------------------------------------------------------------------
    typedef enum logic [4:0] {
        IDLE        = 5'b00001,
        LOAD        = 5'b00010,
        ADD_OR_SKIP = 5'b00100,
        SHIFT       = 5'b01000,
        DONE        = 5'b10000
    } state_t;

    state_t state, next_state;

    // -----------------------------------------------------------------------
    // Contador de iteracoes
    // -----------------------------------------------------------------------
    logic [5:0] count;
    logic       count_en;
    logic       count_rst;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)         count <= '0;
        else if (count_rst) count <= '0;
        else if (count_en)  count <= count + 6'd1;
    end

    // -----------------------------------------------------------------------
    // Registrador de estado
    // -----------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= next_state;
    end

    // -----------------------------------------------------------------------
    // Logica de proximo estado
    // -----------------------------------------------------------------------
    always_comb begin
        next_state = state;
        case (state)
            IDLE:        if (start)           next_state = LOAD;
            LOAD:                             next_state = ADD_OR_SKIP;
            ADD_OR_SKIP:                      next_state = SHIFT;
            SHIFT:       if (count == 6'd31)  next_state = DONE;
                         else                 next_state = ADD_OR_SKIP;
            DONE:        if (!start)          next_state = IDLE;
            default:                          next_state = IDLE;
        endcase
    end

    // -----------------------------------------------------------------------
    // Logica de saida (Moore + Mealy para product_wr)
    // -----------------------------------------------------------------------
    always_comb begin
        load       = 1'b0;
        product_wr = 1'b0;
        shift_en   = 1'b0;
        done       = 1'b0;
        count_en   = 1'b0;
        count_rst  = 1'b0;

        case (state)
            IDLE: begin
                count_rst = 1'b1;
            end

            LOAD: begin
                load      = 1'b1;
                count_rst = 1'b1;
            end

            ADD_OR_SKIP: begin
                // Testa product_reg[0] (era Multiplier0):
                // se 1 → soma multiplicand na parte alta do produto
                product_wr = product_lsb;
            end

            SHIFT: begin
                // Shift right logico de 1 bit nos 65 bits de product_reg
                shift_en = 1'b1;
                count_en = 1'b1;
            end

            DONE: begin
                done = 1'b1;
            end

            default: ;
        endcase
    end

endmodule
