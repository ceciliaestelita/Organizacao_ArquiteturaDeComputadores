// =============================================================================
// lock_fsm_tb.sv
// Testbench para lock_fsm.sv
//
// Simula:
//   [1] Reset inicial
//   [2] Sequencia CORRETA: Azul -> Amarelo -> Amarelo -> Vermelho (abre cofre)
//   [3] Erro no 1o digito  -> RESET_ST -> INITIAL
//   [4] Erro no 2o digito  -> RESET_ST -> INITIAL
//   [5] Erro no 3o digito  -> RESET_ST -> INITIAL
//   [6] Erro no 4o digito  -> RESET_ST -> INITIAL
//   [7] Segurar botao nao deve avancar mais de 1 estado
//   [8] Reset fisico no meio da sequencia
// =============================================================================

`timescale 1ns/1ps

module lock_fsm_tb;

    // -------------------------------------------------------------------------
    // Sinais de estimulo e observacao
    // -------------------------------------------------------------------------
    logic       clk;
    logic       rst_n;
    logic [3:0] btn;
    logic [6:0] leds;

    // -------------------------------------------------------------------------
    // Instancia do DUT (Device Under Test)
    // -------------------------------------------------------------------------
    lock_fsm dut (
        .clk   (clk),
        .rst_n (rst_n),
        .btn   (btn),
        .leds  (leds)
    );

    // -------------------------------------------------------------------------
    // Geracao de clock: periodo de 20ns -> 50 MHz
    // -------------------------------------------------------------------------
    initial clk = 0;
    always #10 clk = ~clk;

    // -------------------------------------------------------------------------
    // Constantes dos estados (para os checks)
    // -------------------------------------------------------------------------
    localparam logic [6:0]
        INITIAL  = 7'b0000001,
        STATE1   = 7'b0000010,
        STATE2   = 7'b0000100,
        STATE3   = 7'b0001000,
        STATE4   = 7'b0010000,
        RESET_ST = 7'b0100000,
        UNLOCKED = 7'b1000000;

    // -------------------------------------------------------------------------
    // Codificacao dos botoes
    // -------------------------------------------------------------------------
    localparam logic [3:0]
        AZUL     = 4'b0001,
        AMARELO  = 4'b0010,
        VERDE    = 4'b0100,
        VERMELHO = 4'b1000;

    // -------------------------------------------------------------------------
    // Task: pressiona um botao por hold_cycles ciclos e solta
    //   - btn = 4'b0000 quando nenhum botao pressionado (estado de repouso)
    //   - btn = cor     quando pressionado
    //   - a borda de subida e detectada no 1o ciclo em que btn != 0
    // -------------------------------------------------------------------------
    task press_button(input logic [3:0] b, input int hold_cycles);
        @(negedge clk);
        btn = b;                           // Pressiona
        repeat (hold_cycles) @(posedge clk);
        @(negedge clk);
        btn = 4'b0000;                     // Solta
        repeat (3) @(posedge clk);         // Aguarda estabilizar
    endtask

    // -------------------------------------------------------------------------
    // Task: verifica o estado dos LEDs e imprime resultado
    // -------------------------------------------------------------------------
    task check_state(input logic [6:0] expected, input string msg);
        @(negedge clk);
        if (leds === expected)
            $display("[PASS] %s | leds = 7'b%07b", msg, leds);
        else
            $display("[FAIL] %s | esperado = 7'b%07b, obtido = 7'b%07b",
                     msg, expected, leds);
    endtask

    // -------------------------------------------------------------------------
    // Sequencia de testes
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("lock_fsm.vcd");
        $dumpvars(0, lock_fsm_tb);

        // Condicao inicial
        rst_n = 1'b1;
        btn   = 4'b0000;   // Nenhum botao pressionado

        // ------------------------------------------------------------------
        // Teste 1: Reset inicial
        // ------------------------------------------------------------------
        $display("\n=== Teste 1: Reset inicial ===");
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        check_state(INITIAL, "Apos reset -> INITIAL");

        // ------------------------------------------------------------------
        // Teste 2: Sequencia CORRETA
        //   Azul -> Amarelo -> Amarelo -> Vermelho
        // ------------------------------------------------------------------
        $display("\n=== Teste 2: Sequencia correta ===");

        press_button(AZUL,     2);
        check_state(STATE1,   "Azul            -> STATE1");

        press_button(AMARELO,  2);
        check_state(STATE2,   "Amarelo         -> STATE2");

        press_button(AMARELO,  2);
        check_state(STATE3,   "Amarelo         -> STATE3");

        press_button(VERMELHO, 2);
        check_state(UNLOCKED, "Vermelho        -> UNLOCKED");

        // Verifica que permanece em UNLOCKED
        repeat (5) @(posedge clk);
        check_state(UNLOCKED, "Permanece em      UNLOCKED");

        // Reset para proximo teste
        rst_n = 1'b0; repeat (2) @(posedge clk); rst_n = 1'b1; @(posedge clk);

        // ------------------------------------------------------------------
        // Teste 3: Erro no 1o digito (Verde no lugar de Azul)
        // ------------------------------------------------------------------
        $display("\n=== Teste 3: Erro no 1o digito ===");

        press_button(VERDE, 2);            // Errado
        check_state(RESET_ST, "Verde (errado)  -> RESET_ST");
        @(posedge clk);                    // RESET_ST dura 1 ciclo
        check_state(INITIAL,  "Apos RESET_ST   -> INITIAL");

        // ------------------------------------------------------------------
        // Teste 4: Erro no 2o digito (Verde no lugar de Amarelo)
        // ------------------------------------------------------------------
        $display("\n=== Teste 4: Erro no 2o digito ===");

        press_button(AZUL,  2);            // Certo
        check_state(STATE1, "Azul certo      -> STATE1");

        press_button(VERDE, 2);            // Errado
        check_state(RESET_ST, "Verde (errado)  -> RESET_ST");
        @(posedge clk);
        check_state(INITIAL,  "Apos RESET_ST   -> INITIAL");

        // ------------------------------------------------------------------
        // Teste 5: Erro no 3o digito (Vermelho no lugar de Amarelo)
        // ------------------------------------------------------------------
        $display("\n=== Teste 5: Erro no 3o digito ===");

        press_button(AZUL,     2);
        press_button(AMARELO,  2);
        check_state(STATE2,   "Chegou em         STATE2");

        press_button(VERMELHO, 2);         // Errado
        check_state(RESET_ST, "Vermelho (errado)-> RESET_ST");
        @(posedge clk);
        check_state(INITIAL,  "Apos RESET_ST   -> INITIAL");

        // ------------------------------------------------------------------
        // Teste 6: Erro no 4o digito (Azul no lugar de Vermelho)
        // ------------------------------------------------------------------
        $display("\n=== Teste 6: Erro no 4o digito ===");

        press_button(AZUL,    2);
        press_button(AMARELO, 2);
        press_button(AMARELO, 2);
        check_state(STATE3,  "Chegou em         STATE3");

        press_button(AZUL,   2);           // Errado
        check_state(RESET_ST, "Azul (errado)   -> RESET_ST");
        @(posedge clk);
        check_state(INITIAL,  "Apos RESET_ST   -> INITIAL");

        // ------------------------------------------------------------------
        // Teste 7: Segurar botao nao deve avancar mais de 1 estado
        // ------------------------------------------------------------------
        $display("\n=== Teste 7: Botao segurado nao avanca mais de 1x ===");

        press_button(AZUL, 20);            // Segura por 20 ciclos
        check_state(STATE1, "Azul segurado 20 ciclos -> apenas STATE1");

        // Reset para proximo teste
        rst_n = 1'b0; repeat (2) @(posedge clk); rst_n = 1'b1; @(posedge clk);

        // ------------------------------------------------------------------
        // Teste 8: Reset fisico no meio da sequencia
        // ------------------------------------------------------------------
        $display("\n=== Teste 8: Reset fisico no meio da sequencia ===");

        press_button(AZUL,    2);
        press_button(AMARELO, 2);
        check_state(STATE2, "Chegou em         STATE2");

        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        check_state(INITIAL, "Reset fisico    -> INITIAL");

        $display("\n=== Simulacao concluida ===\n");
        $finish;
    end

endmodule