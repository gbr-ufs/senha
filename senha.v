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
    input salvar,
    input reset,
    input [6:0] valor,
    output reg [6:0] segd0,
    output reg [6:0] segd1,
    output reg [6:0] segd2,
    output reg [6:0] segd3
);
  reg [1:0] segd = 2'd0;
  always @(posedge clk) begin
    if (reset) begin
      segd  <= 2'd0;
      segd0 <= 7'b0;
      segd1 <= 7'b0;
      segd2 <= 7'b0;
      segd3 <= 7'b0;
    end else if (salvar) begin
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
    input salvar,
    input reset,
    input [3:0] entrada,
    output [6:0] segd0,
    output [6:0] segd1,
    output [6:0] segd2,
    output [6:0] segd3
);
  wire [6:0] saida;
  decodificador d (
      entrada,
      saida
  );
  controlador c (
      clk,
      salvar,
      reset,
      saida,
      segd0,
      segd1,
      segd2,
      segd3
  );
endmodule : ponte

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
    output reg trava_teclado
);

  localparam ESPERA = 2'b00;
  localparam VERIFICANDO = 2'b01;
  localparam ABERTO = 2'b10;
  localparam BLOQUEADO = 2'b11;

  reg [1:0] estado_atual, estado_futuro;
  reg [1:0] tentativas;
  reg btn_anterior;

  // Senha: 1234
  wire [6:0] senha3 = 7'b0000110;  // '1'
  wire [6:0] senha2 = 7'b1011011;  // '2'
  wire [6:0] senha1 = 7'b1001111;  // '3'
  wire [6:0] senha0 = 7'b1100110;  // '4'

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
        tentativas <= tentativas - 2'd1;
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
endmodule
