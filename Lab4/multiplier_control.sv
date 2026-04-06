// multiplier_control.sv
// FSM de controle da versao refinada do multiplicador
//
// Fluxograma da versao refinada (uma iteracao por ciclo):
//
//   1. Testar Product[0] (LSB do registrador product, equivale ao Multiplier0)
//   2. Se Product[0] == 1 → Product[63:32] = Product[63:32] + Multiplicand
//      (passos 1 e 2 combinados com o shift no mesmo ciclo)
//   3. Shift Product a direita 1 bit (carry do passo 2 vai para Product[63])
//   4. 32a. repeticao? → Sim: Fim | Nao: voltar ao passo 1
//
// Mapeamento dos estados para o fluxograma:
//
//   IDLE    — aguarda sinal 'start'
//   LOAD    — carrega operandos no datapath (1 ciclo)
//   COMPUTE — executa uma iteracao add+shift; repete 32 vezes (count 0..31)
//   DONE    — sinaliza conclusao; retorna a IDLE quando 'start' e resetado

module multiplier_control (
    input  logic clk,
    input  logic rst_n,

    // Interface com o usuario
    input  logic start,
    output logic done,

    // Interface com o datapath
    output logic load,        // Carrega operandos iniciais
    output logic compute_en   // Executa uma iteracao (add condicional + shift)
);

    // -----------------------------------------------------------------------
    // Definicao dos estados — codificacao one-hot
    // Cada estado tem exatamente um bit em '1'; os demais sao '0'.
    // Com 4 estados usamos 4 bits (um flip-flop por estado).
    // -----------------------------------------------------------------------
    typedef enum logic [3:0] {
        IDLE    = 4'b0001,
        LOAD    = 4'b0010,
        COMPUTE = 4'b0100,
        DONE    = 4'b1000
    } state_t;

    state_t state, next_state;

    // -----------------------------------------------------------------------
    // Contador de iteracoes (0 a 31 → 32 ciclos COMPUTE)
    // -----------------------------------------------------------------------
    logic [4:0] count;
    logic       count_en;
    logic       count_rst;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)         count <= '0;
        else if (count_rst) count <= '0;
        else if (count_en)  count <= count + 5'd1;
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
            IDLE:    if (start)            next_state = LOAD;
            LOAD:                          next_state = COMPUTE;
            COMPUTE: if (count == 5'd31)   next_state = DONE;
                     else                  next_state = COMPUTE;
            DONE:    if (!start)           next_state = IDLE;
            default:                       next_state = IDLE;
        endcase
    end

    // -----------------------------------------------------------------------
    // Logica de saida (Moore — depende apenas do estado atual)
    // -----------------------------------------------------------------------
    always_comb begin
        // Valores padrao
        load       = 1'b0;
        compute_en = 1'b0;
        done       = 1'b0;
        count_en   = 1'b0;
        count_rst  = 1'b0;

        case (state)
            IDLE: begin
                count_rst = 1'b1; // Mantem o contador em 0 enquanto ocioso
            end

            LOAD: begin
                load      = 1'b1; // Carrega operandos no datapath
                count_rst = 1'b1; // Reseta o contador
            end

            COMPUTE: begin
                compute_en = 1'b1; // Add condicional + shift em um unico ciclo
                count_en   = 1'b1; // Incrementa o contador de iteracoes
            end

            DONE: begin
                done = 1'b1;
            end

            default: ;
        endcase
    end

endmodule