module maquina_central (
    input clk,
    input reset,
    input sel_d,
    // Entradas para o estado CALCULA_VERTICE
    input ovf_v1_in,
    input ovf_v2_in,
    input ovf_f1_in,
    input ovf_f2_in,
    // Entrada para o ciclo CALCULA_PONTOS <-> REG_BUSY
    input reg_full,
    input fim_x,             
    
    // Saídas de erro
    output reg err_v1,
    output reg err_v2,
    output reg err_f1,
    output reg err_f2,
    
    // Saídas de controle do sistema/desenho e status
    output reg ativar_desenho,   
    output reg desenho_pronto,   
    output reg led_busy,         
    output reg led_done,          
    
    // Saída para expor o estado atual ao controlador do contador
    output [2:0] estado_atual_out
);

    // Codificação dos Estados da FSM
    localparam [2:0] 
        INICIO           = 3'b000,
        CALCULA_VERTICE  = 3'b001,
        DES_EIXOS        = 3'b010,
        CALCULA_PONTOS   = 3'b011,
        REG_BUSY         = 3'b100,
        CONCLUIDO        = 3'b101;

    reg [2:0] estado_atual, proximo_estado;

    // Atribuição contínua do estado atual para a saída
    assign estado_atual_out = estado_atual;

    // 1. Registrador de Estado (Síncrono)
    always @(posedge clk or posedge reset) begin
        if (reset)
            estado_atual <= INICIO;
        else
            estado_atual <= proximo_estado;
    end

    // 2. Lógica de Próximo Estado (Combinacional)
    always @(*) begin
        proximo_estado = estado_atual; // Valor padrão para evitar latches

        case (estado_atual)
            INICIO: begin
                if (sel_d == 1'b1)
                    proximo_estado = CALCULA_VERTICE;
                else
                    proximo_estado = INICIO;
            end

            CALCULA_VERTICE: begin
                proximo_estado = DES_EIXOS;
            end

            DES_EIXOS: begin
                proximo_estado = CALCULA_PONTOS;
            end

            CALCULA_PONTOS: begin
                if (reg_full == 1'b1)
                    proximo_estado = REG_BUSY;
                else if (fim_x == 1'b1)
                    proximo_estado = CONCLUIDO; 
                else
                    proximo_estado = CALCULA_PONTOS;
            end

            REG_BUSY: begin
                if (reg_full == 1'b0) begin
                    if (fim_x == 1'b1)
                        proximo_estado = CONCLUIDO;
                    else
                        proximo_estado = CALCULA_PONTOS;
                end else begin
                    proximo_estado = REG_BUSY;
                end
            end

            CONCLUIDO: begin
                if (sel_d == 1'b0)
                    proximo_estado = CONCLUIDO;
                else
                    proximo_estado = INICIO;
            end

            default: begin
                proximo_estado = INICIO;
            end
        endcase
    end

    // 3. Lógica de Saídas e Atribuições (Sequencial)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            err_v1         <= 1'b0;
            err_v2         <= 1'b0;
            err_f1         <= 1'b0;
            err_f2         <= 1'b0;
            ativar_desenho <= 1'b0;
            desenho_pronto <= 1'b0;
            led_busy       <= 1'b0;
            led_done       <= 1'b0;
        end else begin
            case (estado_atual)
                INICIO: begin
                    err_v1         <= 1'b0;
                    err_v2         <= 1'b0;
                    err_f1         <= 1'b0;
                    err_f2         <= 1'b0;
                    ativar_desenho <= 1'b0;
                    desenho_pronto <= 1'b0;
                    led_busy       <= 1'b0;
                    led_done       <= 1'b0;
                end

                CALCULA_VERTICE: begin
                    led_busy       <= 1'b1;
                end

                DES_EIXOS: begin
                    ativar_desenho <= 1'b1; 
                    desenho_pronto <= 1'b1; 
                    led_busy       <= 1'b1;
                end

                CALCULA_PONTOS: begin
                    ativar_desenho <= 1'b0; 
                    led_busy       <= 1'b1;
                end

                REG_BUSY: begin
                    led_busy       <= 1'b1; 
                end

                CONCLUIDO: begin
                    led_busy       <= 1'b0; 
                    led_done       <= 1'b1;
                end
            endcase
        end
    end

endmodule
