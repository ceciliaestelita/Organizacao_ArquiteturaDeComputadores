module button_fsm(
    input  logic       clk,
    input  logic       rst_n,
    input  logic [3:0] btn,
    output logic       led
);

    // [1] ESTADOS - Corrigi para 3 bits (suficiente para 6 estados) e padronizei nomes
    typedef enum logic [2:0] {
        ST_INIT     = 3'b000, 
        ST_AZUL     = 3'b001, 
        ST_AMARELO  = 3'b010, 
        ST_AMARELO2 = 3'b011,
        ST_SUCESSO  = 3'b100
    } states;

    states state, state_prox;

    // [2] DETECTOR DE BORDAS
    logic [3:0] btn_active;
    logic [3:0] btn_prev;    
    logic [3:0] btn_rise;

    assign btn_active = ~btn; 
    assign btn_rise   = btn_active & ~btn_prev;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) btn_prev <= 4'b0;
        else        btn_prev <= btn_active;
    end

    // [3] REGISTRO DE ESTADO
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= ST_INIT;
        else        state <= state_prox;
    end

    // [4] LÓGICA DO COFRE
    always_comb begin
        state_prox = state; 

        if (|btn_rise) begin
            // REGRA: Se mais de um botão for pressionado ao mesmo tempo (Erro)
            if ((btn_rise & (btn_rise - 4'b0001)) != 4'b0000) begin
                state_prox = ST_INIT;
            end 
            else begin
                case (state)
                    ST_INIT: begin
                        if (btn_rise[0]) state_prox = ST_AZUL;
                        else             state_prox = ST_INIT;
                    end

                    ST_AZUL: begin
                        if (btn_rise[1]) state_prox = ST_AMARELO;
                        else             state_prox = ST_INIT;   
                    end

                    ST_AMARELO: begin
                        if (btn_rise[1]) state_prox = ST_AMARELO2;
                        else             state_prox = ST_INIT;   
                    end

                    ST_AMARELO2: begin
                        if (btn_rise[3]) state_prox = ST_SUCESSO; // Vermelho abre o cofre
                        else             state_prox = ST_INIT;   
                    end    

                    ST_SUCESSO: begin
                        state_prox = ST_SUCESSO; // Trava aqui até o reset (regra do slide)
                    end

                    default: state_prox = ST_INIT;
                endcase
            end
        end
    end

    // [5] SAÍDA - O nome da variável deve ser o mesmo que você usa na FSM (state)
    assign led = (state == ST_SUCESSO);

endmodule // Corrigido de 'end module' para 'endmodule'