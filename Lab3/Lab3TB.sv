`timescale 1ns/1ps

module button_fsm_tb;

    // 1. Sinais de interface
    logic       clk;
    logic       rst_n;
    logic [3:0] btn;
    logic       led;

    // 2. Instância do seu módulo (DUT)
    button_fsm dut (
        .clk   (clk),
        .rst_n (rst_n),
        .btn   (btn),
        .led   (led)
    );

    // 3. Geração do Clock (50 MHz -> Período de 20ns)
    initial clk = 0;
    always #10 clk = ~clk;

    // 4. Task para simular o pressionamento de um botão
    // bit_index: 0=Azul, 1=Amarelo, 2=Verde, 3=Vermelho
    task press_button(input int bit_index);
        @(negedge clk);
        btn[bit_index] = 1'b0;        // Aperta (Ativo baixo)
        repeat (5) @(posedge clk);    // Segura por 5 ciclos
        @(negedge clk);
        btn[bit_index] = 1'b1;        // Solta
        repeat (5) @(posedge clk);    // Espera estabilizar
    endtask

    // 5. Sequência de Testes
    initial begin
        // Configuração inicial para GTKWave
        $dumpfile("safecrack.vcd");
        $dumpvars(0, button_fsm_tb);

        // --- Início do Sistema ---
        rst_n = 1'b1;
        btn   = 4'b1111; // Todos soltos
        #20;
        
        $display("--- Iniciando Teste SafeCrack ---");
        
        // Teste 1: Reset Inicial
        rst_n = 1'b0;
        #40;
        rst_n = 1'b1;
        $display("[INFO] Sistema resetado.");

        // Teste 2: Sequência Correta [Azul -> Amarelo -> Amarelo -> Vermelho]
        $display("\n[TESTE 2] Tentando sequencia correta...");
        press_button(0); // Azul
        press_button(1); // Amarelo
        press_button(1); // Amarelo 2
        press_button(3); // Vermelho
        
        #20;
        if (led) $display("[PASS] Cofre abriu com sucesso!");
        else     $display("[FAIL] Cofre continua trancado!");

        // Teste 3: Reset para fechar o cofre
        $display("\n[TESTE 3] Resetando para fechar...");
        rst_n = 1'b0; #20; rst_n = 1'b1;
        if (!led) $display("[PASS] Cofre trancado apos reset.");

        // Teste 4: Erro na sequência (Botão errado)
        $display("\n[TESTE 4] Testando erro (Azul -> Verde)...");
        press_button(0); // Azul
        press_button(2); // Verde (ERRO!)
        // Se errou, o próximo deveria ser o Azul de novo, nao o Amarelo.
        press_button(1); // Amarelo
        if (!led) $display("[PASS] Cofre ignorou a tentativa errada.");

        // Teste 5: Multi-pressionamento (Trapaça)
        $display("\n[TESTE 5] Testando apertar dois botoes juntos...");
        @(negedge clk);
        btn = 4'b1100; // Aperta botão 0 e 1 ao mesmo tempo
        repeat (5) @(posedge clk);
        btn = 4'b1111;
        #20;
        // Deve estar no estado Init agora
        press_button(0); // Se apertar o Azul e ele nao for pro proximo estado, algo falhou
        $display("[INFO] O estado voltou para Init.");

        $display("\n--- Simulacao Concluida ---");
        $finish;
    end

endmodule