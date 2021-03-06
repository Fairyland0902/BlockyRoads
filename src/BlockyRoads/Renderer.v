`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:06:46 12/12/2016 
// Design Name: 
// Module Name:    Renderer 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Renderer(
    input wire clk, clr,
	input wire [ 3: 0] status,
	input wire video_on,
	input wire [ 9: 0] pixel_x, pixel_y,
	input wire btn_pos, mycar_pos, explode_pos, game_over_pos, score_pos,
	input wire btn_visible, explode_visible,
	input wire obstacle_pos0, obstacle_pos1, obstacle_pos2, obstacle_pos3, obstacle_pos4,
	input wire digit_pos0, digit_pos1, digit_pos2, digit_pos3,
	input wire iscollide0, iscollide1, iscollide2, iscollide3, iscollide4,
	input wire signed [31:0] scroll,
	input wire [16: 0] back_addr, side_addr,
	input wire [15:0] explode_addr,
	input wire [14:0] game_over_addr,
	input wire [13: 0] btn_addr,score_addr,
	input wire [13:0] digit_addr0, digit_addr1, digit_addr2, digit_addr3,
	input wire [12: 0] mycar_addr,
	input wire [12: 0] obstacle_addr0, obstacle_addr1, obstacle_addr2, obstacle_addr3, obstacle_addr4,
	output reg [ 3: 0] red, green, blue
	);
	
	// Game status signal declaration
	localparam [3:0]
		prepare   = 4'b1000,
		activate  = 4'b0100,
		pause     = 4'b0010,
		terminate = 4'b0001;
	
	//============================================================================
	// Instantiation
	//============================================================================
	// Instantiate bmp's pixel data
	wire [11:0] back_data, btn_data, side_data, mycar_data, explode_data, game_over_data, score_data;
	wire [11:0] obstacle_data [0:4];
	wire [11:0] digit_data [0:3];
	
	background P1              (.clka(clk), .addra(back_addr), .douta(back_data));
	startBtn   P2              (.clka(clk), .addra(btn_addr), .douta(btn_data));
	side       P3              (.clka(clk), .addra(side_addr), .douta(side_data));
	car     mycar              (.clka(clk), .addra(mycar_addr), .douta(mycar_data));
	police obstacle0           (.clka(clk), .addra(obstacle_addr0), .douta(obstacle_data[0]));
	police obstacle1           (.clka(clk), .addra(obstacle_addr1), .douta(obstacle_data[1]));
	car    obstacle2           (.clka(clk), .addra(obstacle_addr2), .douta(obstacle_data[2]));
	car    obstacle3           (.clka(clk), .addra(obstacle_addr3), .douta(obstacle_data[3]));
	car    obstacle4           (.clka(clk), .addra(obstacle_addr4), .douta(obstacle_data[4]));
	explosion explode          (.clka(clk), .addra(explode_addr), .douta(explode_data));
	game_over game_over_prompt (.clka(clk), .addra(game_over_addr), .douta(game_over_data));
	score score_prompt         (.clka(clk), .addra(score_addr), .douta(score_data));
	digit digit0			   (.clka(clk), .addra(digit_addr0), .douta(digit_data[0]));
	digit digit1			   (.clka(clk), .addra(digit_addr1), .douta(digit_data[1]));
	digit digit2			   (.clka(clk), .addra(digit_addr2), .douta(digit_data[2]));
	digit digit3			   (.clka(clk), .addra(digit_addr3), .douta(digit_data[3]));
	
	//=======================================================================================================================
	// Render
	// Layer 0: Game-over prompt, Score and digits (in TERMINATE status)
	// Layer 1: Explosion animation (in ACTIVATE/PAUSE/TERMINATE status)
	// Layer 2: My car and other obstacles (in ACTIVATE/PAUSE/TERMINATE status)
	// Layer 3: Road, sildes and side (in ACTIVATE/PAUSE/TERMINATE status) OR background and start button (in PREPARE status)
	//=======================================================================================================================
	// Road's properities
	parameter slide_x  = 10;
	parameter slide_y  = 40;
	parameter interval = 20;
	parameter lane_x   = 96;
	integer i;
	wire [9:0] dot_y;
	wire slide_pos, road_pos;
	
	assign dot_y     = (pixel_y + scroll) % 480;
	assign slide_pos = (pixel_x >= 74 && pixel_x < 85) || (pixel_x >= 554 && pixel_x < 565);
	assign road_pos  = pixel_x >= 85 && pixel_x < 554;
	
	// Layer definition
	wire layer0, layer2;	// Other layers do NOT need being specially definited
	assign layer0 = game_over_pos || score_pos || digit_pos0 || digit_pos1 || digit_pos2 || digit_pos3;
	assign layer2 = mycar_pos || obstacle_pos0 || obstacle_pos1 || obstacle_pos2 || obstacle_pos3 || obstacle_pos4;
	
	always @*
	begin
	 	if (video_on)
	 	begin
			//=================================================================================
			// Use FSM to render differnet status
			//=================================================================================
			case (status)
				prepare:									// Render the prepare status
				begin
					if (btn_pos && btn_visible) 			// Render the button
					begin
						if (btn_data == 12'hfff)			// Filter the background color
						begin
							red   <= back_data[ 3: 0];
							green <= back_data[ 7: 4];
							blue  <= back_data[11: 8];
						end
						else
						begin
							red   <= btn_data[ 3: 0];
							green <= btn_data[ 7: 4];
							blue  <= btn_data[11: 8];
						end
					end
					else
					begin
						red   <= back_data[ 3: 0];
						green <= back_data[ 7: 4];
						blue  <= back_data[11: 8];
					end
				end
				activate:									// Render the activate status
				begin
					if (explode_pos && explode_visible)		//================================================ Layer 1
					begin
						if (explode_data == 12'h0f0 || explode_data == 12'h1f1 || explode_data == 12'h2f2 || explode_data == 12'h0e0)
						begin
							if (mycar_pos)
							begin
								if (mycar_data == 12'h0f0 || mycar_data == 12'h1f1 || mycar_data == 12'h2f2 || mycar_data == 12'h0e0)
								begin
									if (slide_pos)
									begin
										red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 15;
										green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 15;
										blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 15;
									end
									else if (road_pos)
									begin
										red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 15;
										green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 15;
										blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 15;
									end
									else
									begin
										red   <= side_data[ 3: 0];
										green <= side_data[ 7: 4];
										blue  <= side_data[11: 8];
									end
								end
								else
								begin
									red   <= mycar_data[ 3: 0];
									green <= mycar_data[ 7: 4];
									blue  <= mycar_data[11: 8];
								end
							end
							else if (obstacle_pos0)
							begin
								if (obstacle_data[0] == 12'h0f0 || obstacle_data[0] == 12'h1f1 || obstacle_data[0] == 12'h2f2 || obstacle_data[0] == 12'h0e0)
								begin
									if (slide_pos)
									begin
										red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 15;
										green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 15;
										blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 15;
									end
									else if (road_pos)
									begin
										red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 15;
										green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 15;
										blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 15;
									end
									else
									begin
										red   <= side_data[ 3: 0];
										green <= side_data[ 7: 4];
										blue  <= side_data[11: 8];
									end
								end
								else
								begin
									red   <= obstacle_data[0][ 3: 0];
									green <= obstacle_data[0][ 7: 4];
									blue  <= obstacle_data[0][11: 8];
								end
							end
							else if (obstacle_pos1)
							begin
								if (obstacle_data[1] == 12'h0f0 || obstacle_data[1] == 12'h1f1 || obstacle_data[1] == 12'h2f2 || obstacle_data[1] == 12'h0e0)
								begin
									if (slide_pos)
									begin
										red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 15;
										green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 15;
										blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 15;
									end
									else if (road_pos)
									begin
										red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 15;
										green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 15;
										blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 15;
									end
									else
									begin
										red   <= side_data[ 3: 0];
										green <= side_data[ 7: 4];
										blue  <= side_data[11: 8];
									end
								end
								else
								begin
									red   <= obstacle_data[1][ 3: 0];
									green <= obstacle_data[1][ 7: 4];
									blue  <= obstacle_data[1][11: 8];
								end
							end
							else if (obstacle_pos2)
							begin
								if (obstacle_data[2] == 12'h0f0 || obstacle_data[2] == 12'h1f1 || obstacle_data[2] == 12'h2f2 || obstacle_data[2] == 12'h0e0)
								begin
									if (slide_pos)
									begin
										red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 15;
										green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 15;
										blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 15;
									end
									else if (road_pos)
									begin
										red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 15;
										green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 15;
										blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 15;
									end
									else
									begin
										red   <= side_data[ 3: 0];
										green <= side_data[ 7: 4];
										blue  <= side_data[11: 8];
									end
								end
								else
								begin
									red   <= obstacle_data[2][ 3: 0];
									green <= obstacle_data[2][ 7: 4];
									blue  <= obstacle_data[2][11: 8];
								end
							end
							else if (obstacle_pos3)
							begin
								if (obstacle_data[3] == 12'h0f0 || obstacle_data[3] == 12'h1f1 || obstacle_data[3] == 12'h2f2 || obstacle_data[3] == 12'h0e0)
								begin
									if (slide_pos)
									begin
										red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 15;
										green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 15;
										blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 15;
									end
									else if (road_pos)
									begin
										red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 15;
										green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 15;
										blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 15;
									end
									else
									begin
										red   <= side_data[ 3: 0];
										green <= side_data[ 7: 4];
										blue  <= side_data[11: 8];
									end
								end
								else
								begin
									red   <= obstacle_data[3][ 3: 0];
									green <= obstacle_data[3][ 7: 4];
									blue  <= obstacle_data[3][11: 8];
								end
							end
							else if (obstacle_pos4)
							begin
								if (obstacle_data[4] == 12'h0f0 || obstacle_data[4] == 12'h1f1 || obstacle_data[4] == 12'h2f2 || obstacle_data[4] == 12'h0e0)
								begin
									if (slide_pos)
									begin
										red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 15;
										green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 15;
										blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 15;
									end
									else if (road_pos)
									begin
										red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 15;
										green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 15;
										blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 15;
									end
									else
									begin
										red   <= side_data[ 3: 0];
										green <= side_data[ 7: 4];
										blue  <= side_data[11: 8];
									end
								end
								else
								begin
									red   <= obstacle_data[4][ 3: 0];
									green <= obstacle_data[4][ 7: 4];
									blue  <= obstacle_data[4][11: 8];
								end
							end
							else if (slide_pos)
							begin
								red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 15;
								green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 15;
								blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 15;
							end
							else if (road_pos)
							begin
								red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 15;
								green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 15;
								blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 15;
							end
							else
							begin
								red   <= side_data[ 3: 0];
								green <= side_data[ 7: 4];
								blue  <= side_data[11: 8];
							end		
						end
						else
						begin
							red   <= explode_data[ 3: 0];
							green <= explode_data[ 7: 4];
							blue  <= explode_data[11: 8];
						end
					end
					else if (layer2)						//=================================================== Layer 2
					begin
						if (mycar_pos)
						begin
							if (mycar_data == 12'h0f0 || mycar_data == 12'h1f1 || mycar_data == 12'h2f2 || mycar_data == 12'h0e0)
							begin
								if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 15;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 15;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 15;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 15;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 15;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 15;
								end
								else
								begin
									red   <= side_data[ 3: 0];
									green <= side_data[ 7: 4];
									blue  <= side_data[11: 8];
								end
							end
							else
							begin
								red   <= mycar_data[ 3: 0];
								green <= mycar_data[ 7: 4];
								blue  <= mycar_data[11: 8];
							end
						end
						else if (obstacle_pos0)
						begin
							if (obstacle_data[0] == 12'h0f0 || obstacle_data[0] == 12'h1f1 || obstacle_data[0] == 12'h2f2 || obstacle_data[0] == 12'h0e0)
							begin
								if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 15;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 15;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 15;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 15;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 15;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 15;
								end
								else
								begin
									red   <= side_data[ 3: 0];
									green <= side_data[ 7: 4];
									blue  <= side_data[11: 8];
								end
							end
							else
							begin
								red   <= obstacle_data[0][ 3: 0];
								green <= obstacle_data[0][ 7: 4];
								blue  <= obstacle_data[0][11: 8];
							end
						end
						else if (obstacle_pos1)
						begin
							if (obstacle_data[1] == 12'h0f0 || obstacle_data[1] == 12'h1f1 || obstacle_data[1] == 12'h2f2 || obstacle_data[1] == 12'h0e0)
							begin
								if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 15;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 15;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 15;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 15;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 15;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 15;
								end
								else
								begin
									red   <= side_data[ 3: 0];
									green <= side_data[ 7: 4];
									blue  <= side_data[11: 8];
								end
							end
							else
							begin
								red   <= obstacle_data[1][ 3: 0];
								green <= obstacle_data[1][ 7: 4];
								blue  <= obstacle_data[1][11: 8];
							end
						end
						else if (obstacle_pos2)
						begin
							if (obstacle_data[2] == 12'h0f0 || obstacle_data[2] == 12'h1f1 || obstacle_data[2] == 12'h2f2 || obstacle_data[2] == 12'h0e0)
							begin
								if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 15;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 15;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 15;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 15;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 15;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 15;
								end
								else
								begin
									red   <= side_data[ 3: 0];
									green <= side_data[ 7: 4];
									blue  <= side_data[11: 8];
								end
							end
							else
							begin
								red   <= obstacle_data[2][ 3: 0];
								green <= obstacle_data[2][ 7: 4];
								blue  <= obstacle_data[2][11: 8];
							end
						end
						else if (obstacle_pos3)
						begin
							if (obstacle_data[3] == 12'h0f0 || obstacle_data[3] == 12'h1f1 || obstacle_data[3] == 12'h2f2 || obstacle_data[3] == 12'h0e0)
							begin
								if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 15;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 15;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 15;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 15;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 15;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 15;
								end
								else
								begin
									red   <= side_data[ 3: 0];
									green <= side_data[ 7: 4];
									blue  <= side_data[11: 8];
								end
							end
							else
							begin
								red   <= obstacle_data[3][ 3: 0];
								green <= obstacle_data[3][ 7: 4];
								blue  <= obstacle_data[3][11: 8];
							end
						end
						else if (obstacle_pos4)
						begin
							if (obstacle_data[4] == 12'h0f0 || obstacle_data[4] == 12'h1f1 || obstacle_data[4] == 12'h2f2 || obstacle_data[4] == 12'h0e0)
							begin
								if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 15;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 15;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 15;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 15;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 15;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 15;
								end
								else
								begin
									red   <= side_data[ 3: 0];
									green <= side_data[ 7: 4];
									blue  <= side_data[11: 8];
								end
							end
							else
							begin
								red   <= obstacle_data[4][ 3: 0];
								green <= obstacle_data[4][ 7: 4];
								blue  <= obstacle_data[4][11: 8];
							end
						end
					end
					else								//===================================================== Layer 3
					begin
					//=======================================================================
					// Render the rolling road line:
					//	||		||		||		||		||		||
					//	||		||		||		||		||		||
					//	||										||
					//	||		||		||		||		||		||
					//	||		||		||		||		||		||
					//	||										||
					//	||		||		||		||		||		||
					//	||		||		||		||		||		||
					//=======================================================================
						if ((pixel_x >= 74 && pixel_x < 85) || (pixel_x >= 554 && pixel_x < 565))
						begin
							red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 15;
							green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 15;
							blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 15;
						end
						else
						begin
							if (((pixel_x >= 74 + lane_x) && (pixel_x < 85 + lane_x)) || ((pixel_x >= 74 + 2 * lane_x) && (pixel_x < 85 + 2 * lane_x)) || ((pixel_x >= 74 + 3 * lane_x) && (pixel_x < 85 + 3 * lane_x)) || ((pixel_x >= 74 + 4 * lane_x) && (pixel_x < 85 + 4 * lane_x)))
							begin
								for (i = 0; i < 480; i = i + 60)
								begin
									if (dot_y >= i && dot_y < i + slide_y)
									begin
										red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 15;
										green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 15;
										blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 15;
									end
									else if (dot_y >= i + slide_y && dot_y < i + slide_y + interval)
									begin
										red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 15;
										green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 15;
										blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 15;
									end
								end
							end
							else
							begin
								if (pixel_x >= 74 && pixel_x < 565)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 15;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 15;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 15;	
								end
								else
								begin
									red   <= side_data[ 3: 0];
									green <= side_data[ 7: 4];
									blue  <= side_data[11: 8];
								end
							end
						end
					end
				end
				pause:
				begin
					if (explode_pos && explode_visible)		//================================================ Layer 1
					begin
						if (explode_data == 12'h0f0 || explode_data == 12'h1f1 || explode_data == 12'h2f2 || explode_data == 12'h0e0)
						begin
							if (mycar_pos)
							begin
								if (mycar_data == 12'h0f0 || mycar_data == 12'h1f1 || mycar_data == 12'h2f2 || mycar_data == 12'h0e0)
								begin
									if (slide_pos)
									begin
										red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
									end
									else if (road_pos)
									begin
										red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
									end
									else
									begin
										red   <= side_data[ 3: 0] / 5;
										green <= side_data[ 7: 4] / 5;
										blue  <= side_data[11: 8] / 5;
									end
								end
								else
								begin
									red   <= mycar_data[ 3: 0] / 5;
									green <= mycar_data[ 7: 4] / 5;
									blue  <= mycar_data[11: 8] / 5;
								end
							end
							else if (obstacle_pos0)
							begin
								if (obstacle_data[0] == 12'h0f0 || obstacle_data[0] == 12'h1f1 || obstacle_data[0] == 12'h2f2 || obstacle_data[0] == 12'h0e0)
								begin
									if (slide_pos)
									begin
										red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
									end
									else if (road_pos)
									begin
										red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
									end
									else
									begin
										red   <= side_data[ 3: 0] / 5;
										green <= side_data[ 7: 4] / 5;
										blue  <= side_data[11: 8] / 5;
									end
								end
								else
								begin
									red   <= obstacle_data[0][ 3: 0] / 5;
									green <= obstacle_data[0][ 7: 4] / 5;
									blue  <= obstacle_data[0][11: 8] / 5;
								end
							end
							else if (obstacle_pos1)
							begin
								if (obstacle_data[1] == 12'h0f0 || obstacle_data[1] == 12'h1f1 || obstacle_data[1] == 12'h2f2 || obstacle_data[1] == 12'h0e0)
								begin
									if (slide_pos)
									begin
										red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
									end
									else if (road_pos)
									begin
										red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
									end
									else
									begin
										red   <= side_data[ 3: 0] / 5;
										green <= side_data[ 7: 4] / 5;
										blue  <= side_data[11: 8] / 5;
									end
								end
								else
								begin
									red   <= obstacle_data[1][ 3: 0] / 5;
									green <= obstacle_data[1][ 7: 4] / 5;
									blue  <= obstacle_data[1][11: 8] / 5;
								end
							end
							else if (obstacle_pos2)
							begin
								if (obstacle_data[2] == 12'h0f0 || obstacle_data[2] == 12'h1f1 || obstacle_data[2] == 12'h2f2 || obstacle_data[2] == 12'h0e0)
								begin
									if (slide_pos)
									begin
										red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
									end
									else if (road_pos)
									begin
										red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
									end
									else
									begin
										red   <= side_data[ 3: 0] / 5;
										green <= side_data[ 7: 4] / 5;
										blue  <= side_data[11: 8] / 5;
									end
								end
								else
								begin
									red   <= obstacle_data[2][ 3: 0] / 5;
									green <= obstacle_data[2][ 7: 4] / 5;
									blue  <= obstacle_data[2][11: 8] / 5;
								end
							end
							else if (obstacle_pos3)
							begin
								if (obstacle_data[3] == 12'h0f0 || obstacle_data[3] == 12'h1f1 || obstacle_data[3] == 12'h2f2 || obstacle_data[3] == 12'h0e0)
								begin
									if (slide_pos)
									begin
										red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
									end
									else if (road_pos)
									begin
										red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
									end
									else
									begin
										red   <= side_data[ 3: 0] / 5;
										green <= side_data[ 7: 4] / 5;
										blue  <= side_data[11: 8] / 5;
									end
								end
								else
								begin
									red   <= obstacle_data[3][ 3: 0] / 5;
									green <= obstacle_data[3][ 7: 4] / 5;
									blue  <= obstacle_data[3][11: 8] / 5;
								end
							end
							else if (obstacle_pos4)
							begin
								if (obstacle_data[4] == 12'h0f0 || obstacle_data[4] == 12'h1f1 || obstacle_data[4] == 12'h2f2 || obstacle_data[4] == 12'h0e0)
								begin
									if (slide_pos)
									begin
										red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
									end
									else if (road_pos)
									begin
										red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
									end
									else
									begin
										red   <= side_data[ 3: 0] / 5;
										green <= side_data[ 7: 4] / 5;
										blue  <= side_data[11: 8] / 5;
									end
								end
								else
								begin
									red   <= obstacle_data[4][ 3: 0] / 5;
									green <= obstacle_data[4][ 7: 4] / 5;
									blue  <= obstacle_data[4][11: 8] / 5;
								end
							end
							else if (slide_pos)
							begin
								red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
								green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
								blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
							end
							else if (road_pos)
							begin
								red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
								green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
								blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
							end
							else
							begin
								red   <= side_data[ 3: 0] / 5;
								green <= side_data[ 7: 4] / 5;
								blue  <= side_data[11: 8] / 5;
							end		
						end
						else
						begin
							red   <= explode_data[ 3: 0] / 5;
							green <= explode_data[ 7: 4] / 5;
							blue  <= explode_data[11: 8] / 5;
						end
					end
					else if (layer2)						//=================================================== Layer 2
					begin
						if (mycar_pos)
						begin
							if (mycar_data == 12'h0f0 || mycar_data == 12'h1f1 || mycar_data == 12'h2f2 || mycar_data == 12'h0e0)
							begin
								if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
								end
								else
								begin
									red   <= side_data[ 3: 0] / 5;
									green <= side_data[ 7: 4] / 5;
									blue  <= side_data[11: 8] / 5;
								end
							end
							else
							begin
								red   <= mycar_data[ 3: 0] / 5;
								green <= mycar_data[ 7: 4] / 5;
								blue  <= mycar_data[11: 8] / 5;
							end
						end
						else if (obstacle_pos0)
						begin
							if (obstacle_data[0] == 12'h0f0 || obstacle_data[0] == 12'h1f1 || obstacle_data[0] == 12'h2f2 || obstacle_data[0] == 12'h0e0)
							begin
								if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
								end
								else
								begin
									red   <= side_data[ 3: 0] / 5;
									green <= side_data[ 7: 4] / 5;
									blue  <= side_data[11: 8] / 5;
								end
							end
							else
							begin
								red   <= obstacle_data[0][ 3: 0] / 5;
								green <= obstacle_data[0][ 7: 4] / 5;
								blue  <= obstacle_data[0][11: 8] / 5;
							end
						end
						else if (obstacle_pos1)
						begin
							if (obstacle_data[1] == 12'h0f0 || obstacle_data[1] == 12'h1f1 || obstacle_data[1] == 12'h2f2 || obstacle_data[1] == 12'h0e0)
							begin
								if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
								end
								else
								begin
									red   <= side_data[ 3: 0] / 5;
									green <= side_data[ 7: 4] / 5;
									blue  <= side_data[11: 8] / 5;
								end
							end
							else
							begin
								red   <= obstacle_data[1][ 3: 0] / 5;
								green <= obstacle_data[1][ 7: 4] / 5;
								blue  <= obstacle_data[1][11: 8] / 5;
							end
						end
						else if (obstacle_pos2)
						begin
							if (obstacle_data[2] == 12'h0f0 || obstacle_data[2] == 12'h1f1 || obstacle_data[2] == 12'h2f2 || obstacle_data[2] == 12'h0e0)
							begin
								if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
								end
								else
								begin
									red   <= side_data[ 3: 0] / 5;
									green <= side_data[ 7: 4] / 5;
									blue  <= side_data[11: 8] / 5;
								end
							end
							else
							begin
								red   <= obstacle_data[2][ 3: 0] / 5;
								green <= obstacle_data[2][ 7: 4] / 5;
								blue  <= obstacle_data[2][11: 8] / 5;
							end
						end
						else if (obstacle_pos3)
						begin
							if (obstacle_data[3] == 12'h0f0 || obstacle_data[3] == 12'h1f1 || obstacle_data[3] == 12'h2f2 || obstacle_data[3] == 12'h0e0)
							begin
								if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
								end
								else
								begin
									red   <= side_data[ 3: 0] / 5;
									green <= side_data[ 7: 4] / 5;
									blue  <= side_data[11: 8] / 5;
								end
							end
							else
							begin
								red   <= obstacle_data[3][ 3: 0] / 5;
								green <= obstacle_data[3][ 7: 4] / 5;
								blue  <= obstacle_data[3][11: 8] / 5;
							end
						end
						else if (obstacle_pos4)
						begin
							if (obstacle_data[4] == 12'h0f0 || obstacle_data[4] == 12'h1f1 || obstacle_data[4] == 12'h2f2 || obstacle_data[4] == 12'h0e0)
							begin
								if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
								end
								else
								begin
									red   <= side_data[ 3: 0] / 5;
									green <= side_data[ 7: 4] / 5;
									blue  <= side_data[11: 8] / 5;
								end
							end
							else
							begin
								red   <= obstacle_data[4][ 3: 0] / 5;
								green <= obstacle_data[4][ 7: 4] / 5;
								blue  <= obstacle_data[4][11: 8] / 5;
							end
						end
					end
					else								//===================================================== Layer 3
					begin
					//=======================================================================
					// Render the rolling road line:
					//	||		||		||		||		||		||
					//	||		||		||		||		||		||
					//	||										||
					//	||		||		||		||		||		||
					//	||		||		||		||		||		||
					//	||										||
					//	||		||		||		||		||		||
					//	||		||		||		||		||		||
					//=======================================================================
						if ((pixel_x >= 74 && pixel_x < 85) || (pixel_x >= 554 && pixel_x < 565))
						begin
							red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
							green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
							blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
						end
						else
						begin
							if (((pixel_x >= 74 + lane_x) && (pixel_x < 85 + lane_x)) || ((pixel_x >= 74 + 2 * lane_x) && (pixel_x < 85 + 2 * lane_x)) || ((pixel_x >= 74 + 3 * lane_x) && (pixel_x < 85 + 3 * lane_x)) || ((pixel_x >= 74 + 4 * lane_x) && (pixel_x < 85 + 4 * lane_x)))
							begin
								for (i = 0; i < 480; i = i + 60)
								begin
									if (dot_y >= i && dot_y < i + slide_y)
									begin
										red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
									end
									else if (dot_y >= i + slide_y && dot_y < i + slide_y + interval)
									begin
										red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
									end
								end
							end
							else
							begin
								if (pixel_x >= 74 && pixel_x < 565)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;	
								end
								else
								begin
									red   <= side_data[ 3: 0] / 5;
									green <= side_data[ 7: 4] / 5;
									blue  <= side_data[11: 8] / 5;
								end
							end
						end
					end
				end
				terminate:
				begin
					if (layer0)										//================================================ Layer 0
					begin
						if (game_over_pos)
						begin
							if (game_over_data == 12'h000)
							begin
								if (explode_pos && explode_visible)
								begin
									if (explode_data == 12'h0f0 || explode_data == 12'h1f1 || explode_data == 12'h2f2 || explode_data == 12'h0e0)
									begin
										if (mycar_pos)
										begin
											if (mycar_data == 12'h0f0 || mycar_data == 12'h1f1 || mycar_data == 12'h2f2 || mycar_data == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= mycar_data[ 3: 0] / 5;
												green <= mycar_data[ 7: 4] / 5;
												blue  <= mycar_data[11: 8] / 5;
											end
										end
										else if (obstacle_pos0)
										begin
											if (obstacle_data[0] == 12'h0f0 || obstacle_data[0] == 12'h1f1 || obstacle_data[0] == 12'h2f2 || obstacle_data[0] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[0][ 3: 0] / 5;
												green <= obstacle_data[0][ 7: 4] / 5;
												blue  <= obstacle_data[0][11: 8] / 5;
											end
										end
										else if (obstacle_pos1)
										begin
											if (obstacle_data[1] == 12'h0f0 || obstacle_data[1] == 12'h1f1 || obstacle_data[1] == 12'h2f2 || obstacle_data[1] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[1][ 3: 0] / 5;
												green <= obstacle_data[1][ 7: 4] / 5;
												blue  <= obstacle_data[1][11: 8] / 5;
											end
										end
										else if (obstacle_pos2)
										begin
											if (obstacle_data[2] == 12'h0f0 || obstacle_data[2] == 12'h1f1 || obstacle_data[2] == 12'h2f2 || obstacle_data[2] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[2][ 3: 0] / 5;
												green <= obstacle_data[2][ 7: 4] / 5;
												blue  <= obstacle_data[2][11: 8] / 5;
											end
										end
										else if (obstacle_pos3)
										begin
											if (obstacle_data[3] == 12'h0f0 || obstacle_data[3] == 12'h1f1 || obstacle_data[3] == 12'h2f2 || obstacle_data[3] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[3][ 3: 0] / 5;
												green <= obstacle_data[3][ 7: 4] / 5;
												blue  <= obstacle_data[3][11: 8] / 5;
											end
										end
										else if (obstacle_pos4)
										begin
											if (obstacle_data[4] == 12'h0f0 || obstacle_data[4] == 12'h1f1 || obstacle_data[4] == 12'h2f2 || obstacle_data[4] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[4][ 3: 0] / 5;
												green <= obstacle_data[4][ 7: 4] / 5;
												blue  <= obstacle_data[4][11: 8] / 5;
											end
										end
										else if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end		
									end
									else
									begin
										red   <= explode_data[ 3: 0] / 5;
										green <= explode_data[ 7: 4] / 5;
										blue  <= explode_data[11: 8] / 5;
									end
								end
								else if (mycar_pos)
								begin
									if (mycar_data == 12'h0f0 || mycar_data == 12'h1f1 || mycar_data == 12'h2f2 || mycar_data == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= mycar_data[ 3: 0] / 5;
										green <= mycar_data[ 7: 4] / 5;
										blue  <= mycar_data[11: 8] / 5;
									end
								end
								else if (obstacle_pos0)
								begin
									if (obstacle_data[0] == 12'h0f0 || obstacle_data[0] == 12'h1f1 || obstacle_data[0] == 12'h2f2 || obstacle_data[0] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[0][ 3: 0] / 5;
										green <= obstacle_data[0][ 7: 4] / 5;
										blue  <= obstacle_data[0][11: 8] / 5;
									end
								end
								else if (obstacle_pos1)
								begin
									if (obstacle_data[1] == 12'h0f0 || obstacle_data[1] == 12'h1f1 || obstacle_data[1] == 12'h2f2 || obstacle_data[1] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[1][ 3: 0] / 5;
										green <= obstacle_data[1][ 7: 4] / 5;
										blue  <= obstacle_data[1][11: 8] / 5;
									end
								end
								else if (obstacle_pos2)
								begin
									if (obstacle_data[2] == 12'h0f0 || obstacle_data[2] == 12'h1f1 || obstacle_data[2] == 12'h2f2 || obstacle_data[2] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[2][ 3: 0] / 5;
										green <= obstacle_data[2][ 7: 4] / 5;
										blue  <= obstacle_data[2][11: 8] / 5;
									end
								end
								else if (obstacle_pos3)
								begin
									if (obstacle_data[3] == 12'h0f0 || obstacle_data[3] == 12'h1f1 || obstacle_data[3] == 12'h2f2 || obstacle_data[3] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[3][ 3: 0] / 5;
										green <= obstacle_data[3][ 7: 4] / 5;
										blue  <= obstacle_data[3][11: 8] / 5;
									end
								end
								else if (obstacle_pos4)
								begin
									if (obstacle_data[4] == 12'h0f0 || obstacle_data[4] == 12'h1f1 || obstacle_data[4] == 12'h2f2 || obstacle_data[4] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[4][ 3: 0] / 5;
										green <= obstacle_data[4][ 7: 4] / 5;
										blue  <= obstacle_data[4][11: 8] / 5;
									end
								end
								else if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
								end
							end
							else
							begin
								red   <= game_over_data[ 3: 0];
								green <= game_over_data[ 7: 4];
								blue  <= game_over_data[11: 8];
							end
						end
						
						if (score_pos)
						begin
							if (score_data == 12'h000)
							begin
								if (explode_pos && explode_visible)
								begin
									if (explode_data == 12'h0f0 || explode_data == 12'h1f1 || explode_data == 12'h2f2 || explode_data == 12'h0e0)
									begin
										if (mycar_pos)
										begin
											if (mycar_data == 12'h0f0 || mycar_data == 12'h1f1 || mycar_data == 12'h2f2 || mycar_data == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= mycar_data[ 3: 0] / 5;
												green <= mycar_data[ 7: 4] / 5;
												blue  <= mycar_data[11: 8] / 5;
											end
										end
										else if (obstacle_pos0)
										begin
											if (obstacle_data[0] == 12'h0f0 || obstacle_data[0] == 12'h1f1 || obstacle_data[0] == 12'h2f2 || obstacle_data[0] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[0][ 3: 0] / 5;
												green <= obstacle_data[0][ 7: 4] / 5;
												blue  <= obstacle_data[0][11: 8] / 5;
											end
										end
										else if (obstacle_pos1)
										begin
											if (obstacle_data[1] == 12'h0f0 || obstacle_data[1] == 12'h1f1 || obstacle_data[1] == 12'h2f2 || obstacle_data[1] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[1][ 3: 0] / 5;
												green <= obstacle_data[1][ 7: 4] / 5;
												blue  <= obstacle_data[1][11: 8] / 5;
											end
										end
										else if (obstacle_pos2)
										begin
											if (obstacle_data[2] == 12'h0f0 || obstacle_data[2] == 12'h1f1 || obstacle_data[2] == 12'h2f2 || obstacle_data[2] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[2][ 3: 0] / 5;
												green <= obstacle_data[2][ 7: 4] / 5;
												blue  <= obstacle_data[2][11: 8] / 5;
											end
										end
										else if (obstacle_pos3)
										begin
											if (obstacle_data[3] == 12'h0f0 || obstacle_data[3] == 12'h1f1 || obstacle_data[3] == 12'h2f2 || obstacle_data[3] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[3][ 3: 0] / 5;
												green <= obstacle_data[3][ 7: 4] / 5;
												blue  <= obstacle_data[3][11: 8] / 5;
											end
										end
										else if (obstacle_pos4)
										begin
											if (obstacle_data[4] == 12'h0f0 || obstacle_data[4] == 12'h1f1 || obstacle_data[4] == 12'h2f2 || obstacle_data[4] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[4][ 3: 0] / 5;
												green <= obstacle_data[4][ 7: 4] / 5;
												blue  <= obstacle_data[4][11: 8] / 5;
											end
										end
										else if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end		
									end
									else
									begin
										red   <= explode_data[ 3: 0] / 5;
										green <= explode_data[ 7: 4] / 5;
										blue  <= explode_data[11: 8] / 5;
									end
								end
								else if (mycar_pos)
								begin
									if (mycar_data == 12'h0f0 || mycar_data == 12'h1f1 || mycar_data == 12'h2f2 || mycar_data == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= mycar_data[ 3: 0] / 5;
										green <= mycar_data[ 7: 4] / 5;
										blue  <= mycar_data[11: 8] / 5;
									end
								end
								else if (obstacle_pos0)
								begin
									if (obstacle_data[0] == 12'h0f0 || obstacle_data[0] == 12'h1f1 || obstacle_data[0] == 12'h2f2 || obstacle_data[0] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[0][ 3: 0] / 5;
										green <= obstacle_data[0][ 7: 4] / 5;
										blue  <= obstacle_data[0][11: 8] / 5;
									end
								end
								else if (obstacle_pos1)
								begin
									if (obstacle_data[1] == 12'h0f0 || obstacle_data[1] == 12'h1f1 || obstacle_data[1] == 12'h2f2 || obstacle_data[1] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[1][ 3: 0] / 5;
										green <= obstacle_data[1][ 7: 4] / 5;
										blue  <= obstacle_data[1][11: 8] / 5;
									end
								end
								else if (obstacle_pos2)
								begin
									if (obstacle_data[2] == 12'h0f0 || obstacle_data[2] == 12'h1f1 || obstacle_data[2] == 12'h2f2 || obstacle_data[2] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[2][ 3: 0] / 5;
										green <= obstacle_data[2][ 7: 4] / 5;
										blue  <= obstacle_data[2][11: 8] / 5;
									end
								end
								else if (obstacle_pos3)
								begin
									if (obstacle_data[3] == 12'h0f0 || obstacle_data[3] == 12'h1f1 || obstacle_data[3] == 12'h2f2 || obstacle_data[3] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[3][ 3: 0] / 5;
										green <= obstacle_data[3][ 7: 4] / 5;
										blue  <= obstacle_data[3][11: 8] / 5;
									end
								end
								else if (obstacle_pos4)
								begin
									if (obstacle_data[4] == 12'h0f0 || obstacle_data[4] == 12'h1f1 || obstacle_data[4] == 12'h2f2 || obstacle_data[4] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[4][ 3: 0] / 5;
										green <= obstacle_data[4][ 7: 4] / 5;
										blue  <= obstacle_data[4][11: 8] / 5;
									end
								end
								else if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
								end
							end
							else
							begin
								red   <= score_data[ 3: 0];
								green <= score_data[ 7: 4];
								blue  <= score_data[11: 8];
							end
						end
						
						if (digit_pos0)
						begin
							if (digit_data[0] == 12'h000)
							begin
								if (explode_pos && explode_visible)
								begin
									if (explode_data == 12'h0f0 || explode_data == 12'h1f1 || explode_data == 12'h2f2 || explode_data == 12'h0e0)
									begin
										if (mycar_pos)
										begin
											if (mycar_data == 12'h0f0 || mycar_data == 12'h1f1 || mycar_data == 12'h2f2 || mycar_data == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= mycar_data[ 3: 0] / 5;
												green <= mycar_data[ 7: 4] / 5;
												blue  <= mycar_data[11: 8] / 5;
											end
										end
										else if (obstacle_pos0)
										begin
											if (obstacle_data[0] == 12'h0f0 || obstacle_data[0] == 12'h1f1 || obstacle_data[0] == 12'h2f2 || obstacle_data[0] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[0][ 3: 0] / 5;
												green <= obstacle_data[0][ 7: 4] / 5;
												blue  <= obstacle_data[0][11: 8] / 5;
											end
										end
										else if (obstacle_pos1)
										begin
											if (obstacle_data[1] == 12'h0f0 || obstacle_data[1] == 12'h1f1 || obstacle_data[1] == 12'h2f2 || obstacle_data[1] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[1][ 3: 0] / 5;
												green <= obstacle_data[1][ 7: 4] / 5;
												blue  <= obstacle_data[1][11: 8] / 5;
											end
										end
										else if (obstacle_pos2)
										begin
											if (obstacle_data[2] == 12'h0f0 || obstacle_data[2] == 12'h1f1 || obstacle_data[2] == 12'h2f2 || obstacle_data[2] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[2][ 3: 0] / 5;
												green <= obstacle_data[2][ 7: 4] / 5;
												blue  <= obstacle_data[2][11: 8] / 5;
											end
										end
										else if (obstacle_pos3)
										begin
											if (obstacle_data[3] == 12'h0f0 || obstacle_data[3] == 12'h1f1 || obstacle_data[3] == 12'h2f2 || obstacle_data[3] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[3][ 3: 0] / 5;
												green <= obstacle_data[3][ 7: 4] / 5;
												blue  <= obstacle_data[3][11: 8] / 5;
											end
										end
										else if (obstacle_pos4)
										begin
											if (obstacle_data[4] == 12'h0f0 || obstacle_data[4] == 12'h1f1 || obstacle_data[4] == 12'h2f2 || obstacle_data[4] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[4][ 3: 0] / 5;
												green <= obstacle_data[4][ 7: 4] / 5;
												blue  <= obstacle_data[4][11: 8] / 5;
											end
										end
										else if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end		
									end
									else
									begin
										red   <= explode_data[ 3: 0] / 5;
										green <= explode_data[ 7: 4] / 5;
										blue  <= explode_data[11: 8] / 5;
									end
								end
								else if (mycar_pos)
								begin
									if (mycar_data == 12'h0f0 || mycar_data == 12'h1f1 || mycar_data == 12'h2f2 || mycar_data == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= mycar_data[ 3: 0] / 5;
										green <= mycar_data[ 7: 4] / 5;
										blue  <= mycar_data[11: 8] / 5;
									end
								end
								else if (obstacle_pos0)
								begin
									if (obstacle_data[0] == 12'h0f0 || obstacle_data[0] == 12'h1f1 || obstacle_data[0] == 12'h2f2 || obstacle_data[0] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[0][ 3: 0] / 5;
										green <= obstacle_data[0][ 7: 4] / 5;
										blue  <= obstacle_data[0][11: 8] / 5;
									end
								end
								else if (obstacle_pos1)
								begin
									if (obstacle_data[1] == 12'h0f0 || obstacle_data[1] == 12'h1f1 || obstacle_data[1] == 12'h2f2 || obstacle_data[1] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[1][ 3: 0] / 5;
										green <= obstacle_data[1][ 7: 4] / 5;
										blue  <= obstacle_data[1][11: 8] / 5;
									end
								end
								else if (obstacle_pos2)
								begin
									if (obstacle_data[2] == 12'h0f0 || obstacle_data[2] == 12'h1f1 || obstacle_data[2] == 12'h2f2 || obstacle_data[2] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[2][ 3: 0] / 5;
										green <= obstacle_data[2][ 7: 4] / 5;
										blue  <= obstacle_data[2][11: 8] / 5;
									end
								end
								else if (obstacle_pos3)
								begin
									if (obstacle_data[3] == 12'h0f0 || obstacle_data[3] == 12'h1f1 || obstacle_data[3] == 12'h2f2 || obstacle_data[3] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[3][ 3: 0] / 5;
										green <= obstacle_data[3][ 7: 4] / 5;
										blue  <= obstacle_data[3][11: 8] / 5;
									end
								end
								else if (obstacle_pos4)
								begin
									if (obstacle_data[4] == 12'h0f0 || obstacle_data[4] == 12'h1f1 || obstacle_data[4] == 12'h2f2 || obstacle_data[4] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[4][ 3: 0] / 5;
										green <= obstacle_data[4][ 7: 4] / 5;
										blue  <= obstacle_data[4][11: 8] / 5;
									end
								end
								else if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
								end
							end
							else
							begin
								red   <= digit_data[0][ 3: 0];
								green <= digit_data[0][ 7: 4];
								blue  <= digit_data[0][11: 8];
							end
						end
						
						if (digit_pos1)
						begin
							if (digit_data[1] == 12'h000)
							begin
								if (explode_pos && explode_visible)
								begin
									if (explode_data == 12'h0f0 || explode_data == 12'h1f1 || explode_data == 12'h2f2 || explode_data == 12'h0e0)
									begin
										if (mycar_pos)
										begin
											if (mycar_data == 12'h0f0 || mycar_data == 12'h1f1 || mycar_data == 12'h2f2 || mycar_data == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= mycar_data[ 3: 0] / 5;
												green <= mycar_data[ 7: 4] / 5;
												blue  <= mycar_data[11: 8] / 5;
											end
										end
										else if (obstacle_pos0)
										begin
											if (obstacle_data[0] == 12'h0f0 || obstacle_data[0] == 12'h1f1 || obstacle_data[0] == 12'h2f2 || obstacle_data[0] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[0][ 3: 0] / 5;
												green <= obstacle_data[0][ 7: 4] / 5;
												blue  <= obstacle_data[0][11: 8] / 5;
											end
										end
										else if (obstacle_pos1)
										begin
											if (obstacle_data[1] == 12'h0f0 || obstacle_data[1] == 12'h1f1 || obstacle_data[1] == 12'h2f2 || obstacle_data[1] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[1][ 3: 0] / 5;
												green <= obstacle_data[1][ 7: 4] / 5;
												blue  <= obstacle_data[1][11: 8] / 5;
											end
										end
										else if (obstacle_pos2)
										begin
											if (obstacle_data[2] == 12'h0f0 || obstacle_data[2] == 12'h1f1 || obstacle_data[2] == 12'h2f2 || obstacle_data[2] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[2][ 3: 0] / 5;
												green <= obstacle_data[2][ 7: 4] / 5;
												blue  <= obstacle_data[2][11: 8] / 5;
											end
										end
										else if (obstacle_pos3)
										begin
											if (obstacle_data[3] == 12'h0f0 || obstacle_data[3] == 12'h1f1 || obstacle_data[3] == 12'h2f2 || obstacle_data[3] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[3][ 3: 0] / 5;
												green <= obstacle_data[3][ 7: 4] / 5;
												blue  <= obstacle_data[3][11: 8] / 5;
											end
										end
										else if (obstacle_pos4)
										begin
											if (obstacle_data[4] == 12'h0f0 || obstacle_data[4] == 12'h1f1 || obstacle_data[4] == 12'h2f2 || obstacle_data[4] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[4][ 3: 0] / 5;
												green <= obstacle_data[4][ 7: 4] / 5;
												blue  <= obstacle_data[4][11: 8] / 5;
											end
										end
										else if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end		
									end
									else
									begin
										red   <= explode_data[ 3: 0] / 5;
										green <= explode_data[ 7: 4] / 5;
										blue  <= explode_data[11: 8] / 5;
									end
								end
								else if (mycar_pos)
								begin
									if (mycar_data == 12'h0f0 || mycar_data == 12'h1f1 || mycar_data == 12'h2f2 || mycar_data == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= mycar_data[ 3: 0] / 5;
										green <= mycar_data[ 7: 4] / 5;
										blue  <= mycar_data[11: 8] / 5;
									end
								end
								else if (obstacle_pos0)
								begin
									if (obstacle_data[0] == 12'h0f0 || obstacle_data[0] == 12'h1f1 || obstacle_data[0] == 12'h2f2 || obstacle_data[0] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[0][ 3: 0] / 5;
										green <= obstacle_data[0][ 7: 4] / 5;
										blue  <= obstacle_data[0][11: 8] / 5;
									end
								end
								else if (obstacle_pos1)
								begin
									if (obstacle_data[1] == 12'h0f0 || obstacle_data[1] == 12'h1f1 || obstacle_data[1] == 12'h2f2 || obstacle_data[1] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[1][ 3: 0] / 5;
										green <= obstacle_data[1][ 7: 4] / 5;
										blue  <= obstacle_data[1][11: 8] / 5;
									end
								end
								else if (obstacle_pos2)
								begin
									if (obstacle_data[2] == 12'h0f0 || obstacle_data[2] == 12'h1f1 || obstacle_data[2] == 12'h2f2 || obstacle_data[2] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[2][ 3: 0] / 5;
										green <= obstacle_data[2][ 7: 4] / 5;
										blue  <= obstacle_data[2][11: 8] / 5;
									end
								end
								else if (obstacle_pos3)
								begin
									if (obstacle_data[3] == 12'h0f0 || obstacle_data[3] == 12'h1f1 || obstacle_data[3] == 12'h2f2 || obstacle_data[3] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[3][ 3: 0] / 5;
										green <= obstacle_data[3][ 7: 4] / 5;
										blue  <= obstacle_data[3][11: 8] / 5;
									end
								end
								else if (obstacle_pos4)
								begin
									if (obstacle_data[4] == 12'h0f0 || obstacle_data[4] == 12'h1f1 || obstacle_data[4] == 12'h2f2 || obstacle_data[4] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[4][ 3: 0] / 5;
										green <= obstacle_data[4][ 7: 4] / 5;
										blue  <= obstacle_data[4][11: 8] / 5;
									end
								end
								else if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
								end
							end
							else
							begin
								red   <= digit_data[1][ 3: 0];
								green <= digit_data[1][ 7: 4];
								blue  <= digit_data[1][11: 8];
							end
						end
						
						if (digit_pos2)
						begin
							if (digit_data[2] == 12'h000)
							begin
								if (explode_pos && explode_visible)
								begin
									if (explode_data == 12'h0f0 || explode_data == 12'h1f1 || explode_data == 12'h2f2 || explode_data == 12'h0e0)
									begin
										if (mycar_pos)
										begin
											if (mycar_data == 12'h0f0 || mycar_data == 12'h1f1 || mycar_data == 12'h2f2 || mycar_data == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= mycar_data[ 3: 0] / 5;
												green <= mycar_data[ 7: 4] / 5;
												blue  <= mycar_data[11: 8] / 5;
											end
										end
										else if (obstacle_pos0)
										begin
											if (obstacle_data[0] == 12'h0f0 || obstacle_data[0] == 12'h1f1 || obstacle_data[0] == 12'h2f2 || obstacle_data[0] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[0][ 3: 0] / 5;
												green <= obstacle_data[0][ 7: 4] / 5;
												blue  <= obstacle_data[0][11: 8] / 5;
											end
										end
										else if (obstacle_pos1)
										begin
											if (obstacle_data[1] == 12'h0f0 || obstacle_data[1] == 12'h1f1 || obstacle_data[1] == 12'h2f2 || obstacle_data[1] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[1][ 3: 0] / 5;
												green <= obstacle_data[1][ 7: 4] / 5;
												blue  <= obstacle_data[1][11: 8] / 5;
											end
										end
										else if (obstacle_pos2)
										begin
											if (obstacle_data[2] == 12'h0f0 || obstacle_data[2] == 12'h1f1 || obstacle_data[2] == 12'h2f2 || obstacle_data[2] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[2][ 3: 0] / 5;
												green <= obstacle_data[2][ 7: 4] / 5;
												blue  <= obstacle_data[2][11: 8] / 5;
											end
										end
										else if (obstacle_pos3)
										begin
											if (obstacle_data[3] == 12'h0f0 || obstacle_data[3] == 12'h1f1 || obstacle_data[3] == 12'h2f2 || obstacle_data[3] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[3][ 3: 0] / 5;
												green <= obstacle_data[3][ 7: 4] / 5;
												blue  <= obstacle_data[3][11: 8] / 5;
											end
										end
										else if (obstacle_pos4)
										begin
											if (obstacle_data[4] == 12'h0f0 || obstacle_data[4] == 12'h1f1 || obstacle_data[4] == 12'h2f2 || obstacle_data[4] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[4][ 3: 0] / 5;
												green <= obstacle_data[4][ 7: 4] / 5;
												blue  <= obstacle_data[4][11: 8] / 5;
											end
										end
										else if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end		
									end
									else
									begin
										red   <= explode_data[ 3: 0] / 5;
										green <= explode_data[ 7: 4] / 5;
										blue  <= explode_data[11: 8] / 5;
									end
								end
								else if (mycar_pos)
								begin
									if (mycar_data == 12'h0f0 || mycar_data == 12'h1f1 || mycar_data == 12'h2f2 || mycar_data == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= mycar_data[ 3: 0] / 5;
										green <= mycar_data[ 7: 4] / 5;
										blue  <= mycar_data[11: 8] / 5;
									end
								end
								else if (obstacle_pos0)
								begin
									if (obstacle_data[0] == 12'h0f0 || obstacle_data[0] == 12'h1f1 || obstacle_data[0] == 12'h2f2 || obstacle_data[0] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[0][ 3: 0] / 5;
										green <= obstacle_data[0][ 7: 4] / 5;
										blue  <= obstacle_data[0][11: 8] / 5;
									end
								end
								else if (obstacle_pos1)
								begin
									if (obstacle_data[1] == 12'h0f0 || obstacle_data[1] == 12'h1f1 || obstacle_data[1] == 12'h2f2 || obstacle_data[1] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[1][ 3: 0] / 5;
										green <= obstacle_data[1][ 7: 4] / 5;
										blue  <= obstacle_data[1][11: 8] / 5;
									end
								end
								else if (obstacle_pos2)
								begin
									if (obstacle_data[2] == 12'h0f0 || obstacle_data[2] == 12'h1f1 || obstacle_data[2] == 12'h2f2 || obstacle_data[2] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[2][ 3: 0] / 5;
										green <= obstacle_data[2][ 7: 4] / 5;
										blue  <= obstacle_data[2][11: 8] / 5;
									end
								end
								else if (obstacle_pos3)
								begin
									if (obstacle_data[3] == 12'h0f0 || obstacle_data[3] == 12'h1f1 || obstacle_data[3] == 12'h2f2 || obstacle_data[3] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[3][ 3: 0] / 5;
										green <= obstacle_data[3][ 7: 4] / 5;
										blue  <= obstacle_data[3][11: 8] / 5;
									end
								end
								else if (obstacle_pos4)
								begin
									if (obstacle_data[4] == 12'h0f0 || obstacle_data[4] == 12'h1f1 || obstacle_data[4] == 12'h2f2 || obstacle_data[4] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[4][ 3: 0] / 5;
										green <= obstacle_data[4][ 7: 4] / 5;
										blue  <= obstacle_data[4][11: 8] / 5;
									end
								end
								else if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
								end
							end
							else
							begin
								red   <= digit_data[2][ 3: 0];
								green <= digit_data[2][ 7: 4];
								blue  <= digit_data[2][11: 8];
							end
						end
						
						if (digit_pos3)
						begin
							if (digit_data[3] == 12'h000)
							begin
								if (explode_pos && explode_visible)
								begin
									if (explode_data == 12'h0f0 || explode_data == 12'h1f1 || explode_data == 12'h2f2 || explode_data == 12'h0e0)
									begin
										if (mycar_pos)
										begin
											if (mycar_data == 12'h0f0 || mycar_data == 12'h1f1 || mycar_data == 12'h2f2 || mycar_data == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= mycar_data[ 3: 0] / 5;
												green <= mycar_data[ 7: 4] / 5;
												blue  <= mycar_data[11: 8] / 5;
											end
										end
										else if (obstacle_pos0)
										begin
											if (obstacle_data[0] == 12'h0f0 || obstacle_data[0] == 12'h1f1 || obstacle_data[0] == 12'h2f2 || obstacle_data[0] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[0][ 3: 0] / 5;
												green <= obstacle_data[0][ 7: 4] / 5;
												blue  <= obstacle_data[0][11: 8] / 5;
											end
										end
										else if (obstacle_pos1)
										begin
											if (obstacle_data[1] == 12'h0f0 || obstacle_data[1] == 12'h1f1 || obstacle_data[1] == 12'h2f2 || obstacle_data[1] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[1][ 3: 0] / 5;
												green <= obstacle_data[1][ 7: 4] / 5;
												blue  <= obstacle_data[1][11: 8] / 5;
											end
										end
										else if (obstacle_pos2)
										begin
											if (obstacle_data[2] == 12'h0f0 || obstacle_data[2] == 12'h1f1 || obstacle_data[2] == 12'h2f2 || obstacle_data[2] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[2][ 3: 0] / 5;
												green <= obstacle_data[2][ 7: 4] / 5;
												blue  <= obstacle_data[2][11: 8] / 5;
											end
										end
										else if (obstacle_pos3)
										begin
											if (obstacle_data[3] == 12'h0f0 || obstacle_data[3] == 12'h1f1 || obstacle_data[3] == 12'h2f2 || obstacle_data[3] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[3][ 3: 0] / 5;
												green <= obstacle_data[3][ 7: 4] / 5;
												blue  <= obstacle_data[3][11: 8] / 5;
											end
										end
										else if (obstacle_pos4)
										begin
											if (obstacle_data[4] == 12'h0f0 || obstacle_data[4] == 12'h1f1 || obstacle_data[4] == 12'h2f2 || obstacle_data[4] == 12'h0e0)
											begin
												if (slide_pos)
												begin
													red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
												end
												else if (road_pos)
												begin
													red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
													green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
													blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
												end
												else
												begin
													red   <= side_data[ 3: 0] / 5;
													green <= side_data[ 7: 4] / 5;
													blue  <= side_data[11: 8] / 5;
												end
											end
											else
											begin
												red   <= obstacle_data[4][ 3: 0] / 5;
												green <= obstacle_data[4][ 7: 4] / 5;
												blue  <= obstacle_data[4][11: 8] / 5;
											end
										end
										else if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end		
									end
									else
									begin
										red   <= explode_data[ 3: 0] / 5;
										green <= explode_data[ 7: 4] / 5;
										blue  <= explode_data[11: 8] / 5;
									end
								end
								else if (mycar_pos)
								begin
									if (mycar_data == 12'h0f0 || mycar_data == 12'h1f1 || mycar_data == 12'h2f2 || mycar_data == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= mycar_data[ 3: 0] / 5;
										green <= mycar_data[ 7: 4] / 5;
										blue  <= mycar_data[11: 8] / 5;
									end
								end
								else if (obstacle_pos0)
								begin
									if (obstacle_data[0] == 12'h0f0 || obstacle_data[0] == 12'h1f1 || obstacle_data[0] == 12'h2f2 || obstacle_data[0] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[0][ 3: 0] / 5;
										green <= obstacle_data[0][ 7: 4] / 5;
										blue  <= obstacle_data[0][11: 8] / 5;
									end
								end
								else if (obstacle_pos1)
								begin
									if (obstacle_data[1] == 12'h0f0 || obstacle_data[1] == 12'h1f1 || obstacle_data[1] == 12'h2f2 || obstacle_data[1] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[1][ 3: 0] / 5;
										green <= obstacle_data[1][ 7: 4] / 5;
										blue  <= obstacle_data[1][11: 8] / 5;
									end
								end
								else if (obstacle_pos2)
								begin
									if (obstacle_data[2] == 12'h0f0 || obstacle_data[2] == 12'h1f1 || obstacle_data[2] == 12'h2f2 || obstacle_data[2] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[2][ 3: 0] / 5;
										green <= obstacle_data[2][ 7: 4] / 5;
										blue  <= obstacle_data[2][11: 8] / 5;
									end
								end
								else if (obstacle_pos3)
								begin
									if (obstacle_data[3] == 12'h0f0 || obstacle_data[3] == 12'h1f1 || obstacle_data[3] == 12'h2f2 || obstacle_data[3] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[3][ 3: 0] / 5;
										green <= obstacle_data[3][ 7: 4] / 5;
										blue  <= obstacle_data[3][11: 8] / 5;
									end
								end
								else if (obstacle_pos4)
								begin
									if (obstacle_data[4] == 12'h0f0 || obstacle_data[4] == 12'h1f1 || obstacle_data[4] == 12'h2f2 || obstacle_data[4] == 12'h0e0)
									begin
										if (slide_pos)
										begin
											red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
										end
										else if (road_pos)
										begin
											red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
											green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
											blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
										end
										else
										begin
											red   <= side_data[ 3: 0] / 5;
											green <= side_data[ 7: 4] / 5;
											blue  <= side_data[11: 8] / 5;
										end
									end
									else
									begin
										red   <= obstacle_data[4][ 3: 0] / 5;
										green <= obstacle_data[4][ 7: 4] / 5;
										blue  <= obstacle_data[4][11: 8] / 5;
									end
								end
								else if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
								end
							end
							else
							begin
								red   <= digit_data[3][ 3: 0];
								green <= digit_data[3][ 7: 4];
								blue  <= digit_data[3][11: 8];
							end
						end
					end
					else if (explode_pos && explode_visible)		//================================================ Layer 1
					begin
						if (explode_data == 12'h0f0 || explode_data == 12'h1f1 || explode_data == 12'h2f2 || explode_data == 12'h0e0)
						begin
							if (mycar_pos)
							begin
								if (mycar_data == 12'h0f0 || mycar_data == 12'h1f1 || mycar_data == 12'h2f2 || mycar_data == 12'h0e0)
								begin
									if (slide_pos)
									begin
										red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
									end
									else if (road_pos)
									begin
										red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
									end
									else
									begin
										red   <= side_data[ 3: 0] / 5;
										green <= side_data[ 7: 4] / 5;
										blue  <= side_data[11: 8] / 5;
									end
								end
								else
								begin
									red   <= mycar_data[ 3: 0] / 5;
									green <= mycar_data[ 7: 4] / 5;
									blue  <= mycar_data[11: 8] / 5;
								end
							end
							else if (obstacle_pos0)
							begin
								if (obstacle_data[0] == 12'h0f0 || obstacle_data[0] == 12'h1f1 || obstacle_data[0] == 12'h2f2 || obstacle_data[0] == 12'h0e0)
								begin
									if (slide_pos)
									begin
										red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
									end
									else if (road_pos)
									begin
										red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
									end
									else
									begin
										red   <= side_data[ 3: 0] / 5;
										green <= side_data[ 7: 4] / 5;
										blue  <= side_data[11: 8] / 5;
									end
								end
								else
								begin
									red   <= obstacle_data[0][ 3: 0] / 5;
									green <= obstacle_data[0][ 7: 4] / 5;
									blue  <= obstacle_data[0][11: 8] / 5;
								end
							end
							else if (obstacle_pos1)
							begin
								if (obstacle_data[1] == 12'h0f0 || obstacle_data[1] == 12'h1f1 || obstacle_data[1] == 12'h2f2 || obstacle_data[1] == 12'h0e0)
								begin
									if (slide_pos)
									begin
										red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
									end
									else if (road_pos)
									begin
										red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
									end
									else
									begin
										red   <= side_data[ 3: 0] / 5;
										green <= side_data[ 7: 4] / 5;
										blue  <= side_data[11: 8] / 5;
									end
								end
								else
								begin
									red   <= obstacle_data[1][ 3: 0] / 5;
									green <= obstacle_data[1][ 7: 4] / 5;
									blue  <= obstacle_data[1][11: 8] / 5;
								end
							end
							else if (obstacle_pos2)
							begin
								if (obstacle_data[2] == 12'h0f0 || obstacle_data[2] == 12'h1f1 || obstacle_data[2] == 12'h2f2 || obstacle_data[2] == 12'h0e0)
								begin
									if (slide_pos)
									begin
										red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
									end
									else if (road_pos)
									begin
										red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
									end
									else
									begin
										red   <= side_data[ 3: 0] / 5;
										green <= side_data[ 7: 4] / 5;
										blue  <= side_data[11: 8] / 5;
									end
								end
								else
								begin
									red   <= obstacle_data[2][ 3: 0] / 5;
									green <= obstacle_data[2][ 7: 4] / 5;
									blue  <= obstacle_data[2][11: 8] / 5;
								end
							end
							else if (obstacle_pos3)
							begin
								if (obstacle_data[3] == 12'h0f0 || obstacle_data[3] == 12'h1f1 || obstacle_data[3] == 12'h2f2 || obstacle_data[3] == 12'h0e0)
								begin
									if (slide_pos)
									begin
										red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
									end
									else if (road_pos)
									begin
										red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
									end
									else
									begin
										red   <= side_data[ 3: 0] / 5;
										green <= side_data[ 7: 4] / 5;
										blue  <= side_data[11: 8] / 5;
									end
								end
								else
								begin
									red   <= obstacle_data[3][ 3: 0] / 5;
									green <= obstacle_data[3][ 7: 4] / 5;
									blue  <= obstacle_data[3][11: 8] / 5;
								end
							end
							else if (obstacle_pos4)
							begin
								if (obstacle_data[4] == 12'h0f0 || obstacle_data[4] == 12'h1f1 || obstacle_data[4] == 12'h2f2 || obstacle_data[4] == 12'h0e0)
								begin
									if (slide_pos)
									begin
										red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
									end
									else if (road_pos)
									begin
										red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
									end
									else
									begin
										red   <= side_data[ 3: 0] / 5;
										green <= side_data[ 7: 4] / 5;
										blue  <= side_data[11: 8] / 5;
									end
								end
								else
								begin
									red   <= obstacle_data[4][ 3: 0] / 5;
									green <= obstacle_data[4][ 7: 4] / 5;
									blue  <= obstacle_data[4][11: 8] / 5;
								end
							end
							else if (slide_pos)
							begin
								red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
								green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
								blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
							end
							else if (road_pos)
							begin
								red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
								green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
								blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
							end
							else
							begin
								red   <= side_data[ 3: 0] / 5;
								green <= side_data[ 7: 4] / 5;
								blue  <= side_data[11: 8] / 5;
							end		
						end
						else
						begin
							red   <= explode_data[ 3: 0] / 5;
							green <= explode_data[ 7: 4] / 5;
							blue  <= explode_data[11: 8] / 5;
						end
					end
					else if (layer2)						//=================================================== Layer 2
					begin
						if (mycar_pos)
						begin
							if (mycar_data == 12'h0f0 || mycar_data == 12'h1f1 || mycar_data == 12'h2f2 || mycar_data == 12'h0e0)
							begin
								if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
								end
								else
								begin
									red   <= side_data[ 3: 0] / 5;
									green <= side_data[ 7: 4] / 5;
									blue  <= side_data[11: 8] / 5;
								end
							end
							else
							begin
								red   <= mycar_data[ 3: 0] / 5;
								green <= mycar_data[ 7: 4] / 5;
								blue  <= mycar_data[11: 8] / 5;
							end
						end
						else if (obstacle_pos0)
						begin
							if (obstacle_data[0] == 12'h0f0 || obstacle_data[0] == 12'h1f1 || obstacle_data[0] == 12'h2f2 || obstacle_data[0] == 12'h0e0)
							begin
								if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
								end
								else
								begin
									red   <= side_data[ 3: 0] / 5;
									green <= side_data[ 7: 4] / 5;
									blue  <= side_data[11: 8] / 5;
								end
							end
							else
							begin
								red   <= obstacle_data[0][ 3: 0] / 5;
								green <= obstacle_data[0][ 7: 4] / 5;
								blue  <= obstacle_data[0][11: 8] / 5;
							end
						end
						else if (obstacle_pos1)
						begin
							if (obstacle_data[1] == 12'h0f0 || obstacle_data[1] == 12'h1f1 || obstacle_data[1] == 12'h2f2 || obstacle_data[1] == 12'h0e0)
							begin
								if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
								end
								else
								begin
									red   <= side_data[ 3: 0] / 5;
									green <= side_data[ 7: 4] / 5;
									blue  <= side_data[11: 8] / 5;
								end
							end
							else
							begin
								red   <= obstacle_data[1][ 3: 0] / 5;
								green <= obstacle_data[1][ 7: 4] / 5;
								blue  <= obstacle_data[1][11: 8] / 5;
							end
						end
						else if (obstacle_pos2)
						begin
							if (obstacle_data[2] == 12'h0f0 || obstacle_data[2] == 12'h1f1 || obstacle_data[2] == 12'h2f2 || obstacle_data[2] == 12'h0e0)
							begin
								if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
								end
								else
								begin
									red   <= side_data[ 3: 0] / 5;
									green <= side_data[ 7: 4] / 5;
									blue  <= side_data[11: 8] / 5;
								end
							end
							else
							begin
								red   <= obstacle_data[2][ 3: 0] / 5;
								green <= obstacle_data[2][ 7: 4] / 5;
								blue  <= obstacle_data[2][11: 8] / 5;
							end
						end
						else if (obstacle_pos3)
						begin
							if (obstacle_data[3] == 12'h0f0 || obstacle_data[3] == 12'h1f1 || obstacle_data[3] == 12'h2f2 || obstacle_data[3] == 12'h0e0)
							begin
								if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
								end
								else
								begin
									red   <= side_data[ 3: 0] / 5;
									green <= side_data[ 7: 4] / 5;
									blue  <= side_data[11: 8] / 5;
								end
							end
							else
							begin
								red   <= obstacle_data[3][ 3: 0] / 5;
								green <= obstacle_data[3][ 7: 4] / 5;
								blue  <= obstacle_data[3][11: 8] / 5;
							end
						end
						else if (obstacle_pos4)
						begin
							if (obstacle_data[4] == 12'h0f0 || obstacle_data[4] == 12'h1f1 || obstacle_data[4] == 12'h2f2 || obstacle_data[4] == 12'h0e0)
							begin
								if (slide_pos)
								begin
									red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
								end
								else if (road_pos)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
								end
								else
								begin
									red   <= side_data[ 3: 0] / 5;
									green <= side_data[ 7: 4] / 5;
									blue  <= side_data[11: 8] / 5;
								end
							end
							else
							begin
								red   <= obstacle_data[4][ 3: 0] / 5;
								green <= obstacle_data[4][ 7: 4] / 5;
								blue  <= obstacle_data[4][11: 8] / 5;
							end
						end
					end
					else								//===================================================== Layer 3
					begin
					//=======================================================================
					// Render the rolling road line:
					//	||		||		||		||		||		||
					//	||		||		||		||		||		||
					//	||										||
					//	||		||		||		||		||		||
					//	||		||		||		||		||		||
					//	||										||
					//	||		||		||		||		||		||
					//	||		||		||		||		||		||
					//=======================================================================
						if ((pixel_x >= 74 && pixel_x < 85) || (pixel_x >= 554 && pixel_x < 565))
						begin
							red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
							green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
							blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
						end
						else
						begin
							if (((pixel_x >= 74 + lane_x) && (pixel_x < 85 + lane_x)) || ((pixel_x >= 74 + 2 * lane_x) && (pixel_x < 85 + 2 * lane_x)) || ((pixel_x >= 74 + 3 * lane_x) && (pixel_x < 85 + 3 * lane_x)) || ((pixel_x >= 74 + 4 * lane_x) && (pixel_x < 85 + 4 * lane_x)))
							begin
								for (i = 0; i < 480; i = i + 60)
								begin
									if (dot_y >= i && dot_y < i + slide_y)
									begin
										red   <= (4'b1111 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b1111 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b1111 * 12 + side_data[11: 8] * 3) / 75;
									end
									else if (dot_y >= i + slide_y && dot_y < i + slide_y + interval)
									begin
										red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
										green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
										blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;
									end
								end
							end
							else
							begin
								if (pixel_x >= 74 && pixel_x < 565)
								begin
									red   <= (4'b0101 * 12 + side_data[ 3: 0] * 3) / 75;
									green <= (4'b0101 * 12 + side_data[ 7: 4] * 3) / 75;
									blue  <= (4'b0100 * 12 + side_data[11: 8] * 3) / 75;	
								end
								else
								begin
									red   <= side_data[ 3: 0] / 5;
									green <= side_data[ 7: 4] / 5;
									blue  <= side_data[11: 8] / 5;
								end
							end
						end
					end
				end
			endcase
		end
		else
	 	begin
	 		red   <= 4'b0;
	 		green <= 4'b0;
	 		blue  <= 4'b0;
	 	end
	 end

endmodule
