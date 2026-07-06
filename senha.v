module top (
    input        clk_3hz,
    input        btn2,
    input        btn1,
    input        btn0,
    input        sw9,
    sw8,
    sw7,
    sw6,
    sw5,
    sw4,
    sw3,
    sw2,
    sw1,
    sw0,
    output [6:0] segd3,
    output [6:0] segd2,
    output [6:0] segd1,
    output [6:0] segd0,
    output       led9,
    led8,
    led7,
    led6,
    led5,
    led4,
    led3,
    led2,
    led1,
    led0
);

  wire [3:0] sw_vec = {sw3, sw2, sw1, sw0};
  wire       clk = clk_3hz;
  wire [1:0] tentativas_restantes;

  // O reset do sistema vem diretamente do pino físico.
  wire       reset = btn2;

  reg btn0_atual = 1'b0, btn0_anterior = 1'b0;
  reg btn1_atual = 1'b0, btn1_anterior = 1'b0;

  always @(posedge clk) begin
    btn0_anterior <= btn0_atual;
    btn0_atual    <= btn0;

    btn1_anterior <= btn1_atual;
    btn1_atual    <= btn1;
  end

  // Pulso gerado apenas quando o botão está pressionado agora, mas não estava no ciclo anterior.
  wire btn0_pulso = btn0_atual & ~btn0_anterior;
  wire btn1_pulso = btn1_atual & ~btn1_anterior;

  wire [6:0] segd0_i, segd1_i, segd2_i, segd3_i;
  wire led_abre, led_tranca, trava_teclado;

  // Lógica da trava (impede inserção de senha se o cofre estiver bloqueado/aberto).
  wire set_digito = btn0_pulso & ~trava_teclado;

  // Decodifica sw[3:0] e distribui entre os 4 displays.
  ponte p (
      .clk    (clk),
      .set    (set_digito),
      .reset  (reset),
      .entrada(sw_vec),
      .segd0  (segd0_i),
      .segd1  (segd1_i),
      .segd2  (segd2_i),
      .segd3  (segd3_i)
  );

  // Maquina de estados do cofre.
  maquina_cofre m (
      .clk                 (clk),
      .reset               (reset),
      .btn_confirmar       (btn1_pulso),
      .segd0               (segd0_i),
      .segd1               (segd1_i),
      .segd2               (segd2_i),
      .segd3               (segd3_i),
      .led_abre            (led_abre),
      .led_tranca          (led_tranca),
      .trava_teclado       (trava_teclado),
      .tentativas_restantes(tentativas_restantes)
  );

  // Divisor de clock para o pisca-pisca (~1Hz a partir do clk_3hz).
  reg [1:0] div_cnt = 2'd0;
  reg       pisca = 1'b0;

  always @(posedge clk) begin
    if (reset) begin
      div_cnt <= 2'd0;
      pisca   <= 1'b0;
    end else if (led_tranca) begin
      if (div_cnt == 2'd1) begin
        div_cnt <= 2'd0;
        pisca   <= ~pisca;
      end else begin
        div_cnt <= div_cnt + 1'b1;
      end
    end else begin
      div_cnt <= 2'd0;
      pisca   <= 1'b0;
    end
  end

  wire apaga = led_tranca & pisca;

  assign segd0 = apaga ? 7'b0 : segd0_i;
  assign segd1 = apaga ? 7'b0 : segd1_i;
  assign segd2 = apaga ? 7'b0 : segd2_i;
  assign segd3 = apaga ? 7'b0 : segd3_i;

  // LEDs: led0 fixo quando abre, todos piscando juntos no bloqueio.
  wire blink = led_tranca & pisca;

  // O LED acende enquanto qualquer botão físico estiver sendo pressionado.
  wire todos_acesos = (btn0 | btn1 | btn2);

  assign led0 = todos_acesos ? 1'b1 : blink ? 1'b1 : led_abre ? 1'b1 : (tentativas_restantes >= 1);

  assign led1 = todos_acesos ? 1'b1 : blink ? 1'b1 : led_abre ? 1'b1 : (tentativas_restantes >= 2);

  assign led2 =
          todos_acesos ? 1'b1 :
          blink ? 1'b1 :
          led_abre ? 1'b1 :
          (tentativas_restantes == 2'd3);

  assign led3 = todos_acesos ? 1'b1 : (blink | led_abre);
  assign led4 = todos_acesos ? 1'b1 : (blink | led_abre);
  assign led5 = todos_acesos ? 1'b1 : (blink | led_abre);
  assign led6 = todos_acesos ? 1'b1 : (blink | led_abre);
  assign led7 = todos_acesos ? 1'b1 : (blink | led_abre);
  assign led8 = todos_acesos ? 1'b1 : (blink | led_abre);
  assign led9 = todos_acesos ? 1'b1 : (blink | led_abre);

endmodule

// Módulos Auxiliares (Decodificador, Controlador, Ponte).
module decodificador (
    input [3:0] hex,
    output reg [6:0] segd
);
  always @(*) begin
    case (hex)
      4'h0: segd = 7'b0111111;
      4'h1: segd = 7'b0000110;
      4'h2: segd = 7'b1011011;
      4'h3: segd = 7'b1001111;
      4'h4: segd = 7'b1100110;
      4'h5: segd = 7'b1101101;
      4'h6: segd = 7'b1111101;
      4'h7: segd = 7'b0000111;
      4'h8: segd = 7'b1111111;
      4'h9: segd = 7'b1101111;
      4'hA: segd = 7'b1110111;
      4'hB: segd = 7'b1111100;
      4'hC: segd = 7'b0111001;
      4'hD: segd = 7'b1011110;
      4'hE: segd = 7'b1111001;
      4'hF: segd = 7'b1110001;
      default: segd = 7'b0000000;
    endcase
  end
endmodule : decodificador

module controlador (
    input clk,
    input set,
    input reset,
    input [6:0] valor,
    output reg [6:0] segd0 = 7'b0,
    output reg [6:0] segd1 = 7'b0,
    output reg [6:0] segd2 = 7'b0,
    output reg [6:0] segd3 = 7'b0
);
  reg [1:0] segd = 2'd0;
  always @(posedge clk) begin
    if (reset) begin
      segd  <= 2'd0;
      segd0 <= 7'b0;
      segd1 <= 7'b0;
      segd2 <= 7'b0;
      segd3 <= 7'b0;
    end else if (set) begin
      segd <= segd + 1'b1;
    end
    begin
      case (segd)
        2'd1: segd1 <= valor;
        2'd2: segd2 <= valor;
        2'd3: segd3 <= valor;
        default: segd0 <= valor;
      endcase
    end
  end
endmodule : controlador

module ponte (
    input clk,
    input set,
    input reset,
    input [3:0] entrada,
    output [6:0] segd0,
    output [6:0] segd1,
    output [6:0] segd2,
    output [6:0] segd3
);
  wire [6:0] saida;
  decodificador d (
      .hex (entrada),
      .segd(saida)
  );
  controlador c (
      .clk  (clk),
      .set  (set),
      .reset(reset),
      .valor(saida),
      .segd0(segd0),
      .segd1(segd1),
      .segd2(segd2),
      .segd3(segd3)
  );
endmodule : ponte


// Máquina de Estados.
module maquina_cofre (
    input clk,
    input reset,
    input btn_confirmar,
    input [6:0] segd0,
    input [6:0] segd1,
    input [6:0] segd2,
    input [6:0] segd3,

    output reg led_abre,
    output reg led_tranca,
    output reg trava_teclado,
    output [1:0] tentativas_restantes
);

  localparam ESPERA = 2'b00;
  localparam VERIFICANDO = 2'b01;
  localparam ABERTO = 2'b10;
  localparam BLOQUEADO = 2'b11;

  reg [1:0] estado_atual = ESPERA;
  reg [1:0] estado_futuro;
  reg [1:0] tentativas = 2'd3;
  reg btn_anterior = 1'b0;

  // Senha: 1234.
  wire [6:0] senha3 = 7'b0000110;  // '1'.
  wire [6:0] senha2 = 7'b1011011;  // '2'.
  wire [6:0] senha1 = 7'b1001111;  // '3'.
  wire [6:0] senha0 = 7'b1100110;  // '4'.

  wire senha_correta = (segd3 == senha3) && (segd2 == senha2) && (segd1 == senha1) && (segd0 == senha0);

  always @(posedge clk) begin
    if (reset) begin
      estado_atual <= ESPERA;
      tentativas   <= 2'd3;
      btn_anterior <= 1'b0;
    end else begin
      estado_atual <= estado_futuro;
      btn_anterior <= btn_confirmar;
      if (estado_atual == VERIFICANDO && !senha_correta) begin
        if (tentativas != 0) tentativas <= tentativas - 1;
      end
    end
  end

  always @(*) begin
    estado_futuro = estado_atual;
    led_abre      = 1'b0;
    led_tranca    = 1'b0;
    trava_teclado = 1'b0;

    case (estado_atual)
      ESPERA: begin
        if (btn_confirmar == 1'b1 && btn_anterior == 1'b0) begin
          estado_futuro = VERIFICANDO;
        end
      end

      VERIFICANDO: begin
        if (senha_correta) begin
          estado_futuro = ABERTO;
        end else begin
          if (tentativas == 2'd1) begin
            estado_futuro = BLOQUEADO;
          end else begin
            estado_futuro = ESPERA;
          end
        end
      end

      ABERTO: begin
        led_abre      = 1'b1;
        trava_teclado = 1'b1;
      end

      BLOQUEADO: begin
        led_tranca    = 1'b1;
        trava_teclado = 1'b1;
      end

      default: estado_futuro = ESPERA;
    endcase
  end
  assign tentativas_restantes = tentativas;
endmodule
