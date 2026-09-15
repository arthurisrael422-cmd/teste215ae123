`timescale 1ns / 1ps

// ============================================================================
// Top Module: Interface Câmera OV7670 -> SDRAM -> VGA (Terasic DE2-115)
// FPGA: Altera Cyclone IV E (EP4CE115F29C7)
// ============================================================================

module top_module(
    input  wire        CLOCK_50,    // Entrada de Clock principal de 50 MHz (PIN_Y2)
    input  wire        rst_n,       // Reset do sistema (PIN_M23, Ativo-Baixo)
    input  wire [3:0]  KEY,         // Botões de controle (PIN_R24, PIN_N21, PIN_M21, PIN_M23)
    
    // ------------------------------------------------------------------------
    // Interface da Câmera OV7670 (Conector GPIO JP5)
    // ------------------------------------------------------------------------
    input  wire        cmos_pclk,   // Pixel Clock da câmera
    input  wire        cmos_href,   // Horizontal Reference
    input  wire        cmos_vsync,  // Vertical Sync
    input  wire [7:0]  cmos_db,     // Barramento de Dados da câmera (D7..D0)
    inout  wire        cmos_sda,    // Dados I2C/SCCB
    inout  wire        cmos_scl,    // Clock I2C/SCCB
    output wire        cmos_rst_n,  // Reset da câmera
    output wire        cmos_pwdn,   // Power Down da câmera (Aterrado/0V)
    output wire        cmos_xclk,   // Clock de 24 MHz fornecido à câmera
    
    // LEDs de Sinalização/Debug
    output wire [3:0]  led,
    
    // ------------------------------------------------------------------------
    // Interface da Memória SDRAM (Placa DE2-115)
    // ------------------------------------------------------------------------
    output wire        DRAM_CLK,    // Clock da SDRAM (165 MHz)
    output wire        DRAM_CKE,    // Clock Enable
    output wire        DRAM_CS_N,   // Chip Select
    output wire        DRAM_RAS_N,  // Row Address Strobe
    output wire        DRAM_CAS_N,  // Column Address Strobe
    output wire        DRAM_WE_N,   // Write Enable
    output wire [12:0] DRAM_ADDR,   // Barramento de Endereço (A12..A0)
    output wire [1:0]  DRAM_BA,     // Bank Address (BA1, BA0)
    output wire [1:0]  DRAM_DQM,    // Data Mask (DQM1, DQM0)
    inout  wire [15:0] DRAM_DQ,     // Barramento de Dados da Memória (DQ15..DQ0)
    
    // ------------------------------------------------------------------------
    // Interface da Saída VGA (DAC ADV7123 da DE2-115)
    // ------------------------------------------------------------------------
    output wire [7:0]  VGA_R,       // Barramento de Vermelho (8 bits)
    output wire [7:0]  VGA_G,       // Barramento de Verde (8 bits)
    output wire [7:0]  VGA_B,       // Barramento de Azul (8 bits)
    output wire        VGA_VS,      // Sincronismo Vertical
    output wire        VGA_HS,      // Sincronismo Horizontal
    output wire        VGA_CLK,     // Clock de Pixel de 25 MHz para o DAC
    output wire        VGA_BLANK_N, // Habilitação do DAC (Mantido em 1'b1)
    output wire        VGA_SYNC_N   // Sync-on-Green (Mantido em 1'b0)
);

    // ========================================================================
    // Sinais Internos e Barramentos Intermediários
    // ========================================================================
    wire clk_sdram;         // Clock de 165 MHz para a lógica da SDRAM
    wire clk_vga;           // Clock de 25 MHz para sincronismo VGA (640x480 @ 60Hz)
    wire f2s_data_valid;    // Sinal de validação dos dados da câmera para a SDRAM
    wire [9:0]  data_count_r;
    wire [15:0] dout;       // Dados lidos do FIFO da câmera
    wire [15:0] din;        // Dados a serem enviados para o FIFO do VGA
    wire empty_fifo;        // Indicador de FIFO de saída vazio
    wire rd_en;             // Sinal de leitura do FIFO do VGA
    
    // Sinais temporários de cor RGB 5:6:5 do núcleo VGA
    wire [4:0] vga_out_r;
    wire [5:0] vga_out_g;
    wire [4:0] vga_out_b;
    wire       vga_out_vs;
    wire       vga_out_hs;

    // ========================================================================
    // Instanciação dos Geradores de Clock (ALTPLL - Altera IP)
    // ========================================================================
    // PLL 1: Gera 24 MHz para a Câmera (c0) e 25 MHz para o sinal VGA (c1)
    meu_pll m3 (
        .inclk0 ( CLOCK_50 ),
        .areset ( ~rst_n ),
        .c0     ( cmos_xclk ),
        .c1     ( clk_vga )
    );

    // PLL 2: Gera 165 MHz para a Memória SDRAM (com fase ajustada)
    pll_sdram m4 (
        .inclk0 ( CLOCK_50 ),
        .areset ( ~rst_n ),
        .c0     ( clk_sdram ),
        .locked ()
    );

    // ========================================================================
    // Instanciação dos Módulos Principais do Sistema
    // ========================================================================
    
    // 1. Controle da Câmera OV7670 (Captura de Pixels e I2C/SCCB)
    camera_interface m0 (
        .clk          ( CLOCK_50 ),
        .clk_100      ( clk_sdram ),
        .rst_n        ( rst_n ),
        .key          ( KEY ),
        .rd_en        ( f2s_data_valid ),
        .data_count_r ( data_count_r ),
        .dout         ( dout ),
        .cmos_pclk    ( cmos_pclk ),
        .cmos_href    ( cmos_href ),
        .cmos_vsync   ( cmos_vsync ),
        .cmos_db      ( cmos_db ),
        .cmos_sda     ( cmos_sda ),
        .cmos_scl     ( cmos_scl ),
        .cmos_rst_n   ( cmos_rst_n ),
        .cmos_pwdn    ( cmos_pwdn ),
        .led          ( led )
    );

    // 2. Controlador de Leitura e Escrita na Memória SDRAM
    sdram_interface m1 (
        .clk            ( clk_sdram ),
        .rst_n          ( rst_n ),
        .clk_vga        ( clk_vga ),
        .rd_en          ( rd_en ),
        .data_count_r   ( data_count_r ),
        .f2s_data       ( dout ),
        .f2s_data_valid ( f2s_data_valid ),
        .empty_fifo     ( empty_fifo ),
        .dout           ( din ),
        .sdram_cke      ( DRAM_CKE ),
        .sdram_cs_n     ( DRAM_CS_N ),
        .sdram_ras_n    ( DRAM_RAS_N ),
        .sdram_cas_n    ( DRAM_CAS_N ),
        .sdram_we_n     ( DRAM_WE_N ),
        .sdram_addr     ( DRAM_ADDR ),
        .sdram_ba       ( DRAM_BA ),
        .sdram_dqm      ( DRAM_DQM ),
        .sdram_dq       ( DRAM_DQ )
    );

    // 3. Controlador de Exibição de Vídeo VGA
    vga_interface m2 (
        .clk        ( CLOCK_50 ),
        .rst_n      ( rst_n ),
        .empty_fifo ( empty_fifo ),
        .din        ( din ),
        .clk_vga    ( clk_vga ),
        .rd_en      ( rd_en ),
        .vga_out_r  ( vga_out_r ),
        .vga_out_g  ( vga_out_g ),
        .vga_out_b  ( vga_out_b ),
        .vga_out_vs ( vga_out_vs ),
        .vga_out_hs ( vga_out_hs )
    );

    // ========================================================================
    // Conexões de Saída e Mapeamento para o Hardware da DE2-115
    // ========================================================================
    
    // Clock da Memória SDRAM
    assign DRAM_CLK = clk_sdram;

    // Sinais de Sincronismo VGA
    assign VGA_VS  = vga_out_vs;
    assign VGA_HS  = vga_out_hs;

    // Habilitação e Sincronismo do DAC ADV7123 da DE2-115
    assign VGA_CLK     = clk_vga;
    assign VGA_BLANK_N = 1'b1; // Habilita a saída de vídeo do DAC (Evita Tela Preta)
    assign VGA_SYNC_N  = 1'b0; // Desativa Sync-on-Green

    // Expansão do Barramento de Cores: RGB 5:6:5 (16 bits) -> RGB 8:8:8 (24 bits no DAC)
    assign VGA_R = {vga_out_r, 3'b000};
    assign VGA_G = {vga_out_g, 2'b00};
    assign VGA_B = {vga_out_b, 3'b000};

endmodule
