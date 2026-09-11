`timescale 1ns / 1ps

module top_module(
	input wire CLOCK_50, rst_n, // CLOCK_50 usa o PIN_Y2 original
	input wire[3:0] KEY,        // KEY usa os pinos M23, M21, N21, R24 originais
	//camera pinouts
	input wire cmos_pclk, cmos_href, cmos_vsync,
	input wire[7:0] cmos_db,
	inout cmos_sda, cmos_scl, 
	output wire cmos_rst_n, cmos_pwdn, cmos_xclk,
	//Debugging
	output[3:0] led, 
	//controller to sdram (Nomes idênticos ao seu arquivo .qsf)
	output wire DRAM_CLK,
	output wire DRAM_CKE, 
	output wire DRAM_CS_N, DRAM_RAS_N, DRAM_CAS_N, DRAM_WE_N, 
	output wire[12:0] DRAM_ADDR,
	output wire[1:0] DRAM_BA, 
	output wire[1:0] DRAM_DQM, 
	inout[15:0] DRAM_DQ,
	//VGA output (Nomes idênticos ao seu arquivo .qsf)
	output wire[7:0] VGA_R,
	output wire[7:0] VGA_G,
	output wire[7:0] VGA_B,
	output wire VGA_VS, VGA_HS,
	output wire VGA_CLK, VGA_BLANK_N, VGA_SYNC_N
);

	 
	 wire f2s_data_valid;
	 wire[9:0] data_count_r;
	 wire[15:0] dout,din;
	 wire clk_sdram;
	 wire empty_fifo;
	 wire clk_vga;
	 wire state;
	 wire rd_en;


	camera_interface m0 //control logic for retrieving data from camera, storing data to asyn_fifo, and  sending data to sdram
	(
		.clk(clk),
		.clk_100(clk_sdram),
		.rst_n(rst_n),
		.key(key),
		//asyn_fifo IO
		.rd_en(f2s_data_valid),
		.data_count_r(data_count_r),
		.dout(dout),
		//camera pinouts
		.cmos_pclk(cmos_pclk),
		.cmos_href(cmos_href),
		.cmos_vsync(cmos_vsync),
		.cmos_db(cmos_db),
		.cmos_sda(cmos_sda),
		.cmos_scl(cmos_scl), 
		.cmos_rst_n(cmos_rst_n),
		.cmos_pwdn(cmos_pwdn),
		//.cmos_xclk(cmos_xclk),
		//Debugging
		.led(led)
    );
	 
	 sdram_interface m1 //control logic for writing the pixel-data from camera to sdram and reading pixel-data from sdram to vga
	 (
		.clk(clk_sdram),
		.rst_n(rst_n),
		//asyn_fifo IO
		.clk_vga(clk_vga),
		.rd_en(rd_en),
		.data_count_r(data_count_r),
		.f2s_data(dout),
		.f2s_data_valid(f2s_data_valid),
		.empty_fifo(empty_fifo),
		.dout(din),
		//controller to sdram
		.sdram_cke(sdram_cke), 
		.sdram_cs_n(sdram_cs_n),
		.sdram_ras_n(sdram_ras_n),
		.sdram_cas_n(sdram_cas_n),
		.sdram_we_n(sdram_we_n), 
		.sdram_addr(sdram_addr),
		.sdram_ba(sdram_ba), 
		.sdram_dqm(sdram_dqm),
		.sdram_dq(sdram_dq)
    );
	 
	 vga_interface m2 //control logic for retrieving data from sdram, storing data to asyn_fifo, and sending data to vga
	 (
		.clk(clk),
		.rst_n(rst_n),
		//asyn_fifo IO
		.empty_fifo(empty_fifo),
		.din(din),
		.clk_vga(clk_vga),
		.rd_en(rd_en),
		//VGA output
		.vga_out_r(vga_out_r),
		.vga_out_g(vga_out_g),
		.vga_out_b(vga_out_b),
		.vga_out_vs(vga_out_vs),
		.vga_out_hs(vga_out_hs)
    );
	 
	 assign sdram_clk = clk_sdram;
	
	// ---- SEUS NOVOS BLOCOS DE CLOCK INSTANCIADOS AQUI ----

	// Primeiro PLL: Cria o relógio da Câmera (c0 = 24MHz) e do VGA (c1 = 25MHz)
	meu_pll m3 (
		.inclk0 (CLOCK_50),          // Entrada de 50 MHz da placa
		.areset (~rst_n),       // Reinicia se o botão de reset for pressionado
		.c0     (cmos_xclk),    // Saída c0 (24 MHz) ligada direto no pino da câmera
		.c1     (clk_vga),      // Saída c1 (25 MHz) alimentando seu circuito VGA
		.locked ()              // Deixamos vazio se não for usar o pino locked
	);

	// Segundo PLL: Cria o relógio de alta velocidade para a memória SDRAM (c0 = 166MHz)
	pll_sdram m4 (
		.inclk0 (CLOCK_50),          // Entrada de 50 MHz da placa (o mesmo pino)
		.areset (~rst_n),       // Reinicia junto com o resto do circuito
		.c0     (clk_sdram),    // Saída c0 (166 MHz) alimentando a interface da SDRAM
		.locked ()              // Deixamos vazio
	);

		// Linhas necessárias para ativar o chip de vídeo VGA da placa DE2-115:
	assign VGA_CLK     = clk_vga;      // Envia o clock de 25MHz para o chip de vídeo
	assign VGA_BLANK_N = 1'b1;         // Mantém o sinal ativo (fora do modo econômico)
	assign VGA_SYNC_N  = 1'b0;         // Padrão para sincronismo separado


endmodule
