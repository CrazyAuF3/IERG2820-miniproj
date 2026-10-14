module seven(
	input [3:0] TA,
	output [7:0] OUT
);
	reg [7:0] RESULT;
	assign OUT = RESULT;
	
	always @(*) begin
		case (TA)
			0: RESULT = 8'b0011_1111;
			1: RESULT = 8'b0000_0110;
			2: RESULT = 8'b0101_1011;
			3: RESULT = 8'b0100_1111;
			4: RESULT = 8'b0110_0110;
			5: RESULT = 8'b0110_1101;
			6: RESULT = 8'b0111_1101;
			7: RESULT = 8'b0000_0111;
			8: RESULT = 8'b0111_1111;
			9: RESULT = 8'b0110_1111;
			10: RESULT = 8'b0111_0111;  // A
			11: RESULT = 8'b0111_1100;  // B
			12: RESULT = 8'b0101_1000;  // C
			13: RESULT = 8'b0101_1110;  // D
			14: RESULT = 8'b0111_1001;  // E
			15: RESULT = 8'b0111_0001;  // F
			default: RESULT = 8'b0000_0000;
		endcase
	end
endmodule