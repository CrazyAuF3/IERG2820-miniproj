module sixteen(
	input [4:0] TA,
	output [16:0] OUT
);
	reg [16:0] seg;
	assign OUT = seg;
	
	always @(*) begin
		case (TA)
			// ---- 0-9 (standard 7-seg shapes) ----
			5'd0 : seg = 17'b11111111000000000; // a b c d e f
			5'd1 : seg = 17'b00110000000000000; // b c
			5'd2 : seg = 17'b11101110110000000; // a b g e d
			5'd3 : seg = 17'b11111100110000000; // a b g c d
			5'd4 : seg = 17'b00110001110000000; // f g b c
			5'd5 : seg = 17'b11011101110000000; // a f g c d
			5'd6 : seg = 17'b11011111110000000; // a f g e c d
			5'd7 : seg = 17'b11110000000000000; // a b c
			5'd8 : seg = 17'b11111111110000000; // all seven
			5'd9 : seg = 17'b11111101110000000; // a b c d f g

			// ---- A-F (standard 7-seg letter shapes) ----
			5'd10: seg = 17'b11110011110000000; // A  = a b c e f g
			5'd11: seg = 17'b00011111110000000; // b  = c d e f g
			5'd12: seg = 17'b11001111000000000; // C  = a d e f
			5'd13: seg = 17'b00111110110000000; // d  = b c d e g
			5'd14: seg = 17'b11001111110000000; // E  = a d e f g
			5'd15: seg = 17'b11000011110000000; // F  = a e f g

			// ---- Symbols ----
			5'd16: seg = 17'b00000000110100100; // +  = G1 G2 J M
			5'd17: seg = 17'b00000000110000000; // -  = G1 G2
			5'd18: seg = 17'b00000000001011010; // ×  = H K L N
			5'd19: seg = 17'b00000000000010010; // /  = K N

			default: seg = 17'b0;
		endcase
	end
endmodule