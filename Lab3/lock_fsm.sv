module lock_fsm (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [3:0] btn,    // vetor de botoes: cada bit = 1 cor
    output logic [6:0] leds
);

// definição dos estados
typedef enum logic [6:0] {
    INITIAL  = 7'b0000001,   // aguarda primeiro botao
    STATE1   = 7'b0000010,   // azul ok
    STATE2   = 7'b0000100,   // azul + amarelo ok
    STATE3   = 7'b0001000,   // azul + amarelo + amarelo ok
    STATE4   = 7'b0010000,   // azul + amarelo + amarelo + vermelho ok (STATE4 = unlocked)
    RESET_ST = 7'b0100000,   // erro: volta para INITIAL
    UNLOCKED = 7'b1000000    // aberto
} state_t;

state_t state, next_state;


logic [3:0] btn_prev;     // valor de btn no ciclo anterior
logic       btn_rise;     // pulso de 1 ciclo: borda de subida detectada
logic [3:0] btn_sampled;  // qual botao gerou o evento

assign btn_rise    = (btn != 4'b0000) && (btn_prev == 4'b0000);
assign btn_sampled = btn_prev == 4'b0000 ? btn : 4'b0000;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) btn_prev <= 4'b0000;
    else        btn_prev <= btn;
end

// sequencial
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) state <= INITIAL;
    else        state <= next_state;
end

// combinacional
always_comb begin
    next_state = state;

    unique case (state)
        INITIAL:  if (btn_rise) begin
                      if (btn_sampled == 4'b0001) next_state = STATE1;   // Azul
                      else                        next_state = RESET_ST;
                  end

        STATE1:   if (btn_rise) begin
                      if (btn_sampled == 4'b0010) next_state = STATE2;   // Amarelo
                      else                        next_state = RESET_ST;
                  end

        STATE2:   if (btn_rise) begin
                      if (btn_sampled == 4'b0010) next_state = STATE3;   // Amarelo
                      else                        next_state = RESET_ST;
                  end

        STATE3:   if (btn_rise) begin
                      if (btn_sampled == 4'b1000) next_state = UNLOCKED; // Vermelho
                      else                        next_state = RESET_ST;
                  end

        RESET_ST:   next_state = INITIAL;   // volta automaticamente

        UNLOCKED:   next_state = UNLOCKED;  // preso ate rst_n

        default:    next_state = INITIAL;
    endcase
end

assign leds = state;

endmodule
