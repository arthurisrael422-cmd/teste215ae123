`timescale 1ns / 1ps

module vga_interface(
	input wire clk,rst_n,
	//asyn_fifo IO
	input wire empty_fifo,
	input wire[15:0] din,
	input wire clk_vga,        // MUDOU PARA INPUT: Recebe os 25MHz vindos do meu_pll externo
	output reg rd_en,
	//VGA output
	output reg[4:0] vga_out_r,
	output reg[5:0] vga_out_g,
	output reg[4:0] vga_out_b,
	output wire vga_out_vs,vga_out_hs
    );
	 
	 // Fio interno para manter a compatibilidade com o resto do código
	 wire clk_out;
	 assign clk_out = clk_vga; // O clock interno agora é o clock que vem do seu PLL
	 
	 //FSM state declarations
	 localparam delay=0,
					idle=1,
					display=2;
					
	 reg[1:0] state_q,state_d;
	 wire[11:0] pixel_x,pixel_y;
	 
	 //register operations
	 always @(posedge clk_out,negedge rst_n) begin
		if(!rst_n) begin
			state_q<=delay;
		end
		else begin
			state_q<=state_d;
		end
	 end
	 
	 //FSM next-state logic
	 always @* begin
	 state_d=state_q;
	 rd_en=0;
	 vga_out_r=0;
	 vga_out_g=0;
	 vga_out_b=0;
		case(state_q)
		  delay: if(pixel_x==1 && pixel_y==1) state_d=idle; //delay of one frame(33ms) needed to start up the camera
			idle:  if(pixel_x==1 && pixel_y==0 && !empty_fifo) begin //wait for pixel-data coming from asyn_fifo 
							vga_out_r=din[15:11]; 
							vga_out_g=din[10:5];
							vga_out_b=din[4:0];
							rd_en=1;	
							state_d=display;
					end
		display: if(pixel_x>=1 && pixel_x<=640 && pixel_y<480) begin //we will continue to read the asyn_fifo as long as current pixel coordinate is inside the visible screen(640x480) 
						vga_out_r=din[15:11]; 
						vga_out_g=din[10:5];
						vga_out_b=din[4:0];
						rd_en=1;	
					end
			idle: state_d=delay;
		endcase
	 end
	
	//module instantiations
	vga_core m0
	(
		.clk(clk_out), //clock must be 25MHz for 640x480
		.rst_n(rst_n),  
		.hsync(vga_out_hs),
		.vsync(vga_out_vs),
		.video_on(),
		.pixel_x(pixel_x),
		.pixel_y(pixel_y)
	);	

	// O BLOCO OXI_25MHZ FOI REMOVIDO DAQUI PORQUE O SEU MEU_PLL JÁ FAZ ESSE PAPEL EXTERNAMENTE!

endmodule
