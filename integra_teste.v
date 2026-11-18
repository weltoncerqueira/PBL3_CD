
module integra_teste (
    input [7:0] sw,
    input  chave,
    input botao,
    input clk,
    input reset,
    output [6:0] sel_abc,
    output led_busy,
    output led_done,
    // Saídas de vídeo físicas da placa
    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,
    output VGA_HS,
    output VGA_VS
);

    wire [7:0] reg_a1, reg_b1, reg_c1;
    wire [7:0] reg_a2, reg_b2, reg_c2;
    wire [2:0] count;
    
    wire botao_pulse; 
    wire rst_interno;
    
    not (rst_interno, reset);
     
    // Captura um pulso único do botão
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
	   
    // Registradores Função 1
    registrador_8b reg8_a11 (.D(sw), .enable(sel_abc[0]), .rst(rst_interno), .clk(clk), .S(reg_a1));
    registrador_8b reg8_b12 (.D(sw), .enable(sel_abc[1]), .rst(rst_interno), .clk(clk), .S(reg_b1));
    registrador_8b reg8_c13 (.D(sw), .enable(sel_abc[2]), .rst(rst_interno), .clk(clk), .S(reg_c1));
	 
    // Registradores Função 2
    registrador_8b reg8_a21 (.D(sw), .enable(sel_abc[3]), .rst(rst_interno), .clk(clk), .S(reg_a2));
    registrador_8b reg8_b22 (.D(sw), .enable(sel_abc[4]), .rst(rst_interno), .clk(clk), .S(reg_b2));
    registrador_8b reg8_c23 (.D(sw), .enable(sel_abc[5]), .rst(rst_interno), .clk(clk), .S(reg_c2));
	 
    //------------------------------------------------------------------
    // Fios e Controles para a Geração Sequencial (Contador X)
    //------------------------------------------------------------------
    wire [9:0] x_contador;
    wire fim_x_w;
    wire limpar_contador_w, habilitar_contagem_w;
    wire [9:0] vga_x, vga_y;
    wire video_on, p_tick;
    wire [9:0] x_cart;

    // 1. Instancia o controlador do contador X com base no estado da FSM
    controlador_contador_x u_ctrl_cont_x (
        .estado_atual(estado_atual_out),
        .reg_full(1'b0),
        .limpar_contador(limpar_contador_w),
        .habilitar_contagem(habilitar_contagem_w)
    );

    // 2. Instancia o contador X sequencial (0 a 639) controlado pela FSM
    contador_x u_cont_x (
        .clk(clk),
        .reset(rst_interno),
        .clear(limpar_contador_w),
        .en(habilitar_contagem_w),
        .x(x_contador),
        .fim_x(fim_x_w)
    );

	// Próxima coluna da varredura (H_MAX = 799)
	wire [9:0] x_prox = (vga_x == 10'd799) ? 10'd0 : (vga_x + 10'd1);

	transformador_coordenadas trans_coord_vga (
		 .x(x_prox),
		 .x_cart(x_cart)       // x_prox - 320
	);

	wire [10:0] x_cart_ext = {x_cart[9], x_cart};

    // 4. Instancia o controlador VGA (periférico de exibição)[cite: 3]
    vga_sync u_vga (
        .clk(clk),
        .reset(~reset),
        .hsync(VGA_HS),
        .vsync(VGA_VS),
        .video_on(video_on),
        .p_tick(p_tick),
        .x(vga_x),
        .y(vga_y)
    );

    // Fios de controle da FSM
    wire [2:0] estado_atual_out; 
    wire err_v1_w, err_v2_w, err_f1_w, err_f2_w;
    wire ativar_desenho_w, desenho_pronto_w;

    // 5. Instancia a Máquina de Estados Central (Apenas uma vez)
    maquina_central u_fsm_central (
        .clk(clk),
        .reset(rst_interno),
        .sel_d(chave),          
        .ovf_v1_in(ovf_v1),          
        .ovf_v2_in(ovf_v2),          
        .ovf_f1_in(ovf_f1),          
        .ovf_f2_in(ovf_f2),          
        .reg_full(1'b0),             
        .fim_x(fim_x_w),             // Conectado ao fim_x real do contador sequencial
        .err_v1(err_v1_w),
        .err_v2(err_v2_w),
        .err_f1(err_f1_w),
        .err_f2(err_f2_w),
        .ativar_desenho(ativar_desenho_w),
        .desenho_pronto(desenho_pronto_w),
        .led_busy(led_busy),
        .led_done(led_done),
        .estado_atual_out(estado_atual_out) 
    );
    
    wire [8:0]  Vx1, Vx2;
    wire [17:0] Vy1, Vy2;
    wire ovf_v1, ovf_f1;
    wire ovf_v2, ovf_f2;
	 

    // Cálculo de Vértices Função 1
    calcula_vertices u_calc_vert1 (
        .a(reg_a1),
        .b(reg_b1),
        .delta(), 
        .Vx(Vx1),
        .Vy(Vy1),
        .err_a0(ovf_f1),
        .err_v(ovf_v1)
    );

    // Cálculo de Vértices Função 2
    calcula_vertices u_calc_vert2 (
        .a(reg_a2),
        .b(reg_b2),
        .delta(), 
        .Vx(Vx2),
        .Vy(Vy2),
        .err_a0(ovf_f2),
        .err_v(ovf_v2)
    );
	 
	wire [29:0] y_func1_c, y_func2_c;
	wire [19:0] y_deriv1_c, y_deriv2_c;

	calcula_y calcula_y1 (.x(x_cart_ext), .a(reg_a1), .b(reg_b1), .c(reg_c1),
								 .overflow(), .cout(), .y(y_func1_c));
	calcula_y calcula_y2 (.x(x_cart_ext), .a(reg_a2), .b(reg_b2), .c(reg_c2),
								 .overflow(), .cout(), .y(y_func2_c));

	calcula_y_linha derivada_1 (.x(x_cart_ext), .a(reg_a1), .b(reg_b1), .y_linha(y_deriv1_c));
	calcula_y_linha derivada_2 (.x(x_cart_ext), .a(reg_a2), .b(reg_b2), .y_linha(y_deriv2_c));
	
	
	wire [29:0] y_func1, y_func2;
	wire [19:0] y_deriv1, y_deriv2;

	captura_y_fsm u_captura_y (
		 .clk(clk),
		 .rst(rst_interno),
		 .p_tick(p_tick),
		 .y_func1_c(y_func1_c),   .y_deriv1_c(y_deriv1_c),
		 .y_func2_c(y_func2_c),   .y_deriv2_c(y_deriv2_c),
		 .y_func1(y_func1),       .y_deriv1(y_deriv1),
		 .y_func2(y_func2),       .y_deriv2(y_deriv2),
		 .carrega()
	);
	
    // Fios para as cores do renderizador
    wire [3:0] r_out, g_out, b_out;
    
    assign VGA_R = r_out;
    assign VGA_G = g_out;
    assign VGA_B = b_out;

    // 6. Instancia o módulo de renderização gráfica (Restaurado)
	 renderizador_grafico u_render (
		 .clk(clk),
		 .rst(rst_interno),
		 .video_on(video_on),
		 .vga_x(vga_x),
		 .vga_y(vga_y),
		 .y_func1(y_func1),   .y_deriv1(y_deriv1),
		 .y_func2(y_func2),   .y_deriv2(y_deriv2),
		 .err_f1(err_f1_w),
		 .err_f2(err_f2_w),
		 .sistema_pronto(led_done),
		 .vga_r(r_out), .vga_g(g_out), .vga_b(b_out)
	 );
	 
endmodule


module renderizador_grafico (
    input  wire        clk,
    input  wire        rst,          // ativo em alto (ligar em rst_interno)
    input  wire        video_on,
    input  wire [9:0]  vga_x,
    input  wire [9:0]  vga_y,
    input  wire [29:0] y_func1,
    input  wire [19:0] y_deriv1,
    input  wire [29:0] y_func2,
    input  wire [19:0] y_deriv2,
    input  wire        err_f1,
    input  wire        err_f2,
    input  wire        sistema_pronto,
    output reg  [3:0]  vga_r,
    output reg  [3:0]  vga_g,
    output reg  [3:0]  vga_b
);

    // ------------------------------------------------------------------
    // Datapath: eixos, conversão y -> linha da tela (240 - y) e traçado
    // ------------------------------------------------------------------
    wire hit_eixos = (vga_x == 10'd320) || (vga_y == 10'd240);

    wire signed [31:0] y_f1_ext = {{2{y_func1[29]}},   y_func1};
    wire signed [31:0] y_d1_ext = {{12{y_deriv1[19]}}, y_deriv1};
    wire signed [31:0] y_f2_ext = {{2{y_func2[29]}},   y_func2};
    wire signed [31:0] y_d2_ext = {{12{y_deriv2[19]}}, y_deriv2};

    wire signed [31:0] ys_f1 = 32'sd240 - y_f1_ext;
    wire signed [31:0] ys_d1 = 32'sd240 - y_d1_ext;
    wire signed [31:0] ys_f2 = 32'sd240 - y_f2_ext;
    wire signed [31:0] ys_d2 = 32'sd240 - y_d2_ext;

    wire hit_parabola1, hit_derivada1, hit_parabola2, hit_derivada2;

    traco_curva t_f1 (.clk(clk), .vga_x(vga_x), .vga_y(vga_y), .ys(ys_f1),
                      .en(sistema_pronto && !err_f1), .hit(hit_parabola1));
    traco_curva t_d1 (.clk(clk), .vga_x(vga_x), .vga_y(vga_y), .ys(ys_d1),
                      .en(sistema_pronto && !err_f1), .hit(hit_derivada1));
    traco_curva t_f2 (.clk(clk), .vga_x(vga_x), .vga_y(vga_y), .ys(ys_f2),
                      .en(sistema_pronto && !err_f2), .hit(hit_parabola2));
    traco_curva t_d2 (.clk(clk), .vga_x(vga_x), .vga_y(vga_y), .ys(ys_d2),
                      .en(sistema_pronto && !err_f2), .hit(hit_derivada2));

    // ------------------------------------------------------------------
    // FSM de cor (Moore): um estado por cor
    // ------------------------------------------------------------------
    localparam [2:0]
        ST_BLANK = 3'd0,   // fora da área visível -> preto
        ST_P1    = 3'd1,   // parábola 1  -> vermelho
        ST_D1    = 3'd2,   // derivada 1  -> laranja
        ST_P2    = 3'd3,   // parábola 2  -> verde
        ST_D2    = 3'd4,   // derivada 2  -> ciano
        ST_EIXO  = 3'd5,   // eixos       -> preto
        ST_FUNDO = 3'd6;   // fundo       -> branco

    reg [2:0] estado, proximo;

    // Registrador de estado
    always @(posedge clk or posedge rst) begin
        if (rst) estado <= ST_BLANK;
        else     estado <= proximo;
    end

    // Lógica de próximo estado (prioridade: P1 > D1 > P2 > D2 > eixos > fundo)
    always @(*) begin
        if      (!video_on)      proximo = ST_BLANK;
        else if (hit_parabola1)  proximo = ST_P1;
        else if (hit_derivada1)  proximo = ST_D1;
        else if (hit_parabola2)  proximo = ST_P2;
        else if (hit_derivada2)  proximo = ST_D2;
        else if (hit_eixos)      proximo = ST_EIXO;
        else                     proximo = ST_FUNDO;
    end

    // Saídas (Moore): dependem apenas do estado
    always @(*) begin
        case (estado)
            ST_BLANK: begin vga_r = 4'h0; vga_g = 4'h0; vga_b = 4'h0; end
            ST_P1:    begin vga_r = 4'hF; vga_g = 4'h0; vga_b = 4'h0; end // Vermelho (funçao 1)
            ST_D1:    begin vga_r = 4'hF; vga_g = 4'hF; vga_b = 4'h0; end // Amarelo (Derivada 1)
            ST_P2:    begin vga_r = 4'h0; vga_g = 4'hF; vga_b = 4'h0; end 
            ST_D2:    begin vga_r = 4'h0; vga_g = 4'hF; vga_b = 4'hF; end // ciano (derivada 2)
            ST_EIXO:  begin vga_r = 4'h0; vga_g = 4'h0; vga_b = 4'h0; end
            ST_FUNDO: begin vga_r = 4'hF; vga_g = 4'hF; vga_b = 4'hF; end // fundo branco
            default:  begin vga_r = 4'h0; vga_g = 4'h0; vga_b = 4'h0; end
        endcase
    end

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
	 somador_completo fa0  (.A(x[0]), .B(b_inv[0]), .cin(c[0]), .S(x_cart[0]), .cout(c[1]));
    somador_completo fa1  (.A(x[1]), .B(b_inv[1]), .cin(c[1]), .S(x_cart[1]), .cout(c[2]));
    somador_completo fa2  (.A(x[2]), .B(b_inv[2]), .cin(c[2]), .S(x_cart[2]), .cout(c[3]));
    somador_completo fa3  (.A(x[3]), .B(b_inv[3]), .cin(c[3]), .S(x_cart[3]), .cout(c[4]));
    somador_completo fa4  (.A(x[4]), .B(b_inv[4]), .cin(c[4]), .S(x_cart[4]), .cout(c[5]));
    somador_completo fa5  (.A(x[5]), .B(b_inv[5]), .cin(c[5]), .S(x_cart[5]), .cout(c[6]));
    somador_completo fa6  (.A(x[6]), .B(b_inv[6]), .cin(c[6]), .S(x_cart[6]), .cout(c[7]));
    somador_completo fa7  (.A(x[7]), .B(b_inv[7]), .cin(c[7]), .S(x_cart[7]), .cout(c[8]));
    somador_completo fa8  (.A(x[8]), .B(b_inv[8]), .cin(c[8]), .S(x_cart[8]), .cout(c[9]));
    somador_completo fa9  (.A(x[9]), .B(b_inv[9]), .cin(c[9]), .S(x_cart[9]), .cout(c[10]));

endmodule



module controlador_contador_x (
    input wire [2:0] estado_atual,
    input wire reg_full,
    output wire limpar_contador,
    output wire habilitar_contagem
);

    // Fios internos para os sinais invertidos (NOT) e termos intermediários
    wire not_s2, not_s1, not_s0, not_reg_full;
    wire or_s1_s0;
    wire term_en_1, term_en_2;

    // 1. Inversores (Portas NOT) para os bits de estado e reg_full
    not g_not_s2 (not_s2, estado_atual[2]);
    not g_not_s1 (not_s1, estado_atual[1]);
    not g_not_s0 (not_s0, estado_atual[0]);
    not g_not_rf (not_reg_full, reg_full);

    // 2. Lógica para limpar_contador (ativo em INICIO, CALCULA_VERTICE e DES_EIXOS)
    // Expressão simplificada: ~s2 & (~s1 | ~s0)
    or  g_or_negativos (or_s1_s0, not_s1, not_s0);
    and g_and_limpar   (limpar_contador, not_s2, or_s1_s0);

    // 3. Lógica para habilitar_contagem (ativo apenas em CALCULA_PONTOS e reg_full == 0)
    // Expressão: ~s2 & s1 & s0 & ~reg_full
    and g_and_en1 (term_en_1, not_s2, estado_atual[1]);
    and g_and_en2 (term_en_2, estado_atual[0], not_reg_full);
    and g_and_en3 (habilitar_contagem, term_en_1, term_en_2);

endmodule


module traco_curva (
    input  wire              clk,
    input  wire [9:0]        vga_x,
    input  wire [9:0]        vga_y,
    input  wire signed [31:0] ys,   // linha da tela da coluna atual (240 - y)
    input  wire              en,
    output wire              hit
);
    reg [9:0]         x_q;
    reg signed [31:0] ys_q, prev_hold;

    wire x_changed = (vga_x != x_q);

    always @(posedge clk) begin
        x_q   <= vga_x;
        ys_q  <= ys;
        if (x_changed) prev_hold <= ys_q;   // guarda o y da coluna anterior
    end

    // coluna 0: sem coluna anterior (evita traço do fim da linha anterior)
    wire signed [31:0] prev = (vga_x == 10'd0) ? ys :
                              (x_changed ? ys_q : prev_hold);

    // clipping: acima (<0) ou abaixo (>479) da tela
    wire cur_up  = (ys   < 32'sd0);
    wire cur_dn  = (ys   > 32'sd479);
    wire prv_up  = (prev < 32'sd0);
    wire prv_dn  = (prev > 32'sd479);

    wire [9:0] cur_c = cur_up ? 10'd0 : (cur_dn ? 10'd479 : ys[9:0]);
    wire [9:0] prv_c = prv_up ? 10'd0 : (prv_dn ? 10'd479 : prev[9:0]);

    wire [9:0] lo = (cur_c < prv_c) ? cur_c : prv_c;
    wire [9:0] hi = (cur_c < prv_c) ? prv_c : cur_c;

    // se as duas colunas estão fora do mesmo lado, não desenha nada
    wire fora = (cur_up && prv_up) || (cur_dn && prv_dn);

    assign hit = en && !fora && (vga_y >= lo) && (vga_y <= hi);
endmodule



// FSM que sincroniza a captura dos valores de y com o avanço do pixel da VGA.
// ESPERA  : ciclo em que p_tick = 0 (os cálculos combinacionais estabilizam)
// CAPTURA : ciclo em que p_tick = 1 (vga_x avança; os registradores carregam)
module captura_y_fsm (
    input  wire        clk,
    input  wire        rst,        // ativo em alto
    input  wire        p_tick,     // tick de pixel do vga_sync
    input  wire [29:0] y_func1_c,
    input  wire [19:0] y_deriv1_c,
    input  wire [29:0] y_func2_c,
    input  wire [19:0] y_deriv2_c,
    output reg  [29:0] y_func1,
    output reg  [19:0] y_deriv1,
    output reg  [29:0] y_func2,
    output reg  [19:0] y_deriv2,
    output wire        carrega     // útil para depuração/simulação
);

    localparam ESPERA  = 1'b0,
               CAPTURA = 1'b1;

    reg estado, proximo;

    // Registrador de estado
    always @(posedge clk or posedge rst) begin
        if (rst) estado <= ESPERA;
        else     estado <= proximo;
    end

    // Próximo estado: p_tick = 0 indica que o próximo ciclo terá p_tick = 1
    always @(*) begin
        case (estado)
            ESPERA:  proximo = (p_tick == 1'b0) ? CAPTURA : ESPERA;
            CAPTURA: proximo = ESPERA;
            default: proximo = ESPERA;
        endcase
    end

    // Saída de Moore
    assign carrega = (estado == CAPTURA);

    // Registradores de dados, carregados apenas em CAPTURA
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            y_func1  <= 30'd0;
            y_func2  <= 30'd0;
            y_deriv1 <= 20'd0;
            y_deriv2 <= 20'd0;
        end else if (carrega) begin
            y_func1  <= y_func1_c;
            y_func2  <= y_func2_c;
            y_deriv1 <= y_deriv1_c;
            y_deriv2 <= y_deriv2_c;
        end
    end

endmodule
