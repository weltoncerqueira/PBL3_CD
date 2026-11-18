
module integra_teste (
    input [7:0] sw,
    input botao,
    input clk,
    input reset,
	 output [6:0] sel_abc
);

    wire [7:0] reg_a1, reg_b1, reg_c1;
	 wire [7:0] reg_a2, reg_b2, reg_c2;
	 wire [23:0] y1, y2;
    wire [2:0] count;
	 
    wire botao_pulse; 
     
    wire rst_interno;
    not (rst_interno, reset);
     
    // captura um pulso único do botão
   detector_de_borda borda_1 (
       .clk(clk),
       .rst(rst_interno),
       .sinal(botao),
       .pulso(botao_pulse)
    );
	 
	 // Conta até 3, com base em cada pulso do botao
	 contador_3b cont_3b(
		 .clk(clk),
		 .rst(rst_interno),
		 .pulso(botao_pulse),
		 .Q(count)
	 );
	 
	 // Decodifica o contador para escolher qual registrador receberá o valor das chaves
	 decoder_abc decoder_abc(
		 .count(count),
		 .sel(sel_abc)
	);
	   
    // registradores 1
    registrador_8b reg8_a11 (.D(sw), .enable(sel_abc[0]), .rst(rst_interno), .clk(clk), .S(reg_a1));
    registrador_8b reg8_b12 (.D(sw), .enable(sel_abc[1]), .rst(rst_interno), .clk(clk), .S(reg_b1));
    registrador_8b reg8_c13 (.D(sw), .enable(sel_abc[2]), .rst(rst_interno), .clk(clk), .S(reg_c1));
	 
	 // registradores 2
    registrador_8b reg8_a21 (.D(sw), .enable(sel_abc[3]), .rst(rst_interno), .clk(clk), .S(reg_a2));
    registrador_8b reg8_b22 (.D(sw), .enable(sel_abc[4]), .rst(rst_interno), .clk(clk), .S(reg_b2));
    registrador_8b reg8_c23 (.D(sw), .enable(sel_abc[5]), .rst(rst_interno), .clk(clk), .S(reg_c2));
	 
	 
	 //------------------------------------------------------------------
    // Logica do Contador
    //------------------------------------------------------------------
	 // Fios locais para interconexão (caso já não existam no seu top/datapath)
    wire [9:0] pixel_x;
    wire s_fim_x;
    wire limpar_contador;
    wire habilitar_contagem;

    // Lógica combinacional para controlar o clear e o enable baseada no estado atual da FSM
    assign limpar_contador    = (estado_atual == INICIO) || (estado_atual == CALCULA_VERTICE) || (estado_atual == DES_EIXOS);
    assign habilitar_contagem = (estado_atual == CALCULA_PONTOS) && (reg_full == 1'b0);

    contador_x contX (
        .clk(clk),
        .reset(reset),
        .clear(limpar_contador),     // Zera o contador enquanto não estiver na etapa de pontos
        .en(habilitar_contagem),     // Só incrementa se estiver calculando pontos e o buffer não estiver cheio
        .x(pixel_x),                 // Valor da coluna atual (de 0 a 639) que vai para o transformador de coordenadas
        .fim_x(s_fim_x)              // Vai conectado à entrada 'fim_x' da FSM para encerrar em 639
    );

 
	 wire [8:0]  Vx;
    wire [17:0] Vy;
    wire ovf_a0, ovf_v;
	 wire [9:0] cont_x;

	 contador_fsm cont_320(
		 .clk(clk),
		 .rst(rst_interno),    // reset assíncrono, ativo em alto
		 .start(sel_abc[6]),  // inicia a contagem
		 .contagem(cont_x),
		 .fase(),     			// 0 = contando até -320, 1 = contando até +320
		 .done()      			// 1 quando as duas contagens terminaram
	 );
	 
	 calcula_vertices (
		 .a(a),
		 .b(b),
		 .delta(),
		 .Vx(Vx),
		 .Vy(Vy),
		 .err_a0(ovf_a0),
		 .err_v(ovf_v)
	 );
	 
	 calcula_y calcula_y1 (
      .x(cont_x),
      .a(reg_a1),
      .b(reg_b1),
      .c(reg_c1),
      .overflow(),
      .cout(),
      .y(y1)
    );
	 
	 calcula_y calcula_y2 (
      .x(sw),
      .a(reg_a2),
      .b(reg_b2),
      .c(reg_c2),
      .overflow(),
      .cout(),
      .y(y2)
    );
	 
	 
	 
	 wire [2:0] e2;
	 //------------------------------------------------------------------
    // Maquina de estados central
    //------------------------------------------------------------------
	 maquina_central mc(
		 .clk(clk),
		 .reset(rst_interno),
		 .sel_d(sel_d),
		 
		 // Entradas para o estado CALCULA_VERTICE
		 .ovf_v1_in(1'b0),
		 .ovf_v2_in(1'b0),
		 .ovf_f1_in(1'b0),
		 .ovf_f2_in(1'b0),
		 
		 // Entrada para o ciclo CALCULA_PONTOS <-> REG_BUSY
		 .reg_full(reg_full),
		 .fim_x(),
		 
		 // Saídas de erro
		 .err_v1(),
		 .err_v2(),
		 .err_f1(),
		 .err_f2(),
		 
		 // Saídas de controle do sistema/desenho e status (Requisito 15)[cite: 2]
		 .ativar_desenho(),   // Ativa o módulo de desenho dos eixos
		 .desenho_pronto(),   // Indica que o desenho já foi feito
		 .led_busy(),         // LED indicador de ocupado/processamento
		 .led_done()          // LED indicador de conclusão
		);
	 
	 
	 

	 
endmodule



module contador_x (
    input wire clk,
    input wire reset,
    input wire clear,     // Zera o contador ao iniciar o processo de cálculo
    input wire en,        // Habilita o incremento (quando o ponto atual foi processado)
    output reg [9:0] x,   // Valor da coluna atual (de 0 a 639)
    output wire fim_x     // Fica em nível alto quando x atingir o limite de 639
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            x <= 10'd0;
        end else if (clear) begin
            x <= 10'd0;
        end else if (en) begin
            if (x < 10'd639) begin
                x <= x + 10'd1;
            end else begin
                x <= 10'd639; // Mantém no limite máximo se habilitado além do fim
            end
        end
    end

    // Sinaliza para a FSM que todos os 640 pixels visíveis foram percorridos
    assign fim_x = (x == 10'd639);

endmodule

module transformador_coordenadas (
    input wire [9:0] x,
    output wire [9:0] x_cart
);
    // Declaração de alimentação de nível lógico fixo (Supply)
    supply1 vcc;
    supply0 gnd;

    wire [9:0] b_inv;
    wire [10:0] c; // Fios de transporte (carries)

    // Inversão fixa dos bits da constante 320 ('0101000000') -> '1010111111'
    // Utilizando apenas buffers (buf) conforme restrição
    buf g_b9 (b_inv[9], vcc);
    buf g_b8 (b_inv[8], gnd);
    buf g_b7 (b_inv[7], vcc);
    buf g_b6 (b_inv[6], gnd);
    buf g_b5 (b_inv[5], vcc);
    buf g_b4 (b_inv[4], vcc);
    buf g_b3 (b_inv[3], vcc);
    buf g_b2 (b_inv[2], vcc);
    buf g_b1 (b_inv[1], vcc);
    buf g_b0 (b_inv[0], vcc);

    // Carry-in inicial fixo em 1 para fechar o complemento de dois (-320)
    buf g_cin (c[0], vcc);

    // Instanciação em cadeia de 10 Full Adders (Ripple-Carry Subtractor)
    somador_completo fa0  (.a(x[0]), .b(b_inv[0]), .cin(c[0]), .sum(x_cart[0]), .cout(c[1]));
    somador_completo fa1  (.a(x[1]), .b(b_inv[1]), .cin(c[1]), .sum(x_cart[1]), .cout(c[2]));
    somador_completo fa2  (.a(x[2]), .b(b_inv[2]), .cin(c[2]), .sum(x_cart[2]), .cout(c[3]));
    somador_completo fa3  (.a(x[3]), .b(b_inv[3]), .cin(c[3]), .sum(x_cart[3]), .cout(c[4]));
    somador_completo fa4  (.a(x[4]), .b(b_inv[4]), .cin(c[4]), .sum(x_cart[4]), .cout(c[5]));
    somador_completo fa5  (.a(x[5]), .b(b_inv[5]), .cin(c[5]), .sum(x_cart[5]), .cout(c[6]));
    somador_completo fa6  (.a(x[6]), .b(b_inv[6]), .cin(c[6]), .sum(x_cart[6]), .cout(c[7]));
    somador_completo fa7  (.a(x[7]), .b(b_inv[7]), .cin(c[7]), .sum(x_cart[7]), .cout(c[8]));
    somador_completo fa8  (.a(x[8]), .b(b_inv[8]), .cin(c[8]), .sum(x_cart[8]), .cout(c[9]));
    somador_completo fa9  (.a(x[9]), .b(b_inv[9]), .cin(c[9]), .sum(x_cart[9]), .cout(c[10]));

endmodule






