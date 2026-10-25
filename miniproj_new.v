// refactored display logic part to combinatorial
// using non-blocking in sequential logic part

module miniproj_new(
	input  [3:0]  TA,
	input  [3:0]  TB,
	input  [3:0]  TC,
	input  [3:0]  KA,
	input         SW1,
	input         SW2,
	input         CLK,
	output [10:0] LED,
	output [7:0]  DIG1,
	output [7:0]  DIG2,
	output [16:0] DIG3
);

localparam [18:0] SAMPLE_LIMIT = 19'd500000;

reg [7:0] result = 8'd0;
reg       overflow_borrow = 1'b0;
reg       error = 1'b0;
reg       zero_flag = 1'b0;
reg       display_mode = 1'b0;
reg       mode = 1'b0;
reg       initialized = 1'b0;

reg [7:0] registerA = 8'd0;
reg [7:0] registerB = 8'd0;
reg [7:0] registerC = 8'd0;

reg [18:0] sampling_counter = 19'd0;
reg        sw1_sample = 1'b0;
reg        sw1_previous = 1'b0;
reg        sw2_sample = 1'b0;
reg        sw2_previous = 1'b0;
reg [3:0]  ta_sample = 4'd0;
reg [3:0]  ta_previous = 4'd0;

wire sample_tick = (sampling_counter == SAMPLE_LIMIT);
wire sw1_pressed = sw1_sample & ~sw1_previous;
wire sw2_pressed = sw2_sample & ~sw2_previous;
wire sw2_released = ~sw2_sample & sw2_previous;
wire ta_changed = (ta_sample != ta_previous);

wire [1:0] calculator_operation = TC[3:2];
wire       calculator_hex = TC[1];

always @(posedge CLK) begin
	if (sample_tick) begin
		sampling_counter <= 19'd0;

		sw1_previous <= sw1_sample;
		sw1_sample <= SW1;
		sw2_previous <= sw2_sample;
		sw2_sample <= SW2;
		ta_previous <= ta_sample;
		ta_sample <= TA;

		if (!initialized) begin
			initialized <= 1'b1;
			mode <= SW2;
			if (SW2) begin
				result <= 8'd0;
			end else begin
				result <= TA;
			end
		end else begin
			case (mode)
			1'b0: begin
			if (ta_changed) begin
				overflow_borrow <= 1'b0;
				result <= TA;
				display_mode <= 1'b0;
			end

			if (sw1_pressed) begin
				error <= 1'b0;
				case (calculator_operation)
				2'b00: {overflow_borrow, result} <= result + TB;
				2'b01: {overflow_borrow, result} <= result - TB;
				2'b10: result <= result[3:0] * TB;
				2'b11: begin
				if (TB == 4'd0) begin
					error <= 1'b1;
					result <= 8'd0;
				end else begin
					result <= result / TB;
				end
				end
				endcase
				display_mode <= 1'b1;
			end

			if (sw2_pressed) begin
				error <= 1'b0;
				overflow_borrow <= 1'b0;
				registerA <= 8'd0;
				registerB <= 8'd0;
				registerC <= 8'd0;
				zero_flag <= 1'b0;
				result <= 8'd0;
				mode <= 1'b1;
			end
			end

			1'b1: begin
			if (sw2_released) begin
				error <= 1'b0;
				overflow_borrow <= 1'b0;
				display_mode <= 1'b0;
				mode <= 1'b0;
			end

			if (sw1_pressed) begin
				error <= 1'b0;
				overflow_borrow <= 1'b0;
				zero_flag <= ~(|registerA);
				case (TC)
				4'b0000: registerA <= {TA, TB};
				4'b0001: registerB <= {TA, TB};
				4'b0010: registerC <= {TA, TB};
				4'b0011: registerA <= ~registerA;
				4'b0100: {overflow_borrow, registerA} <= registerA + registerB;
				4'b0101: {overflow_borrow, registerA} <= registerA + registerC;
				4'b0110: {overflow_borrow, registerA} <= registerA - registerB;
				4'b0111: {overflow_borrow, registerA} <= registerA - registerC;
				4'b1000: {registerA, registerB} <= registerA * registerB;
				4'b1001: begin
				if (registerB == 8'd0) begin
					registerA <= 8'd0;
					error <= 1'b1;
				end else begin
					registerA <= registerA / registerB;
				end
				end
				4'b1010: registerA <= registerA << 1;
				4'b1011: registerA <= registerA >> 1;
				4'b1100: result <= registerA;
				4'b1101: result <= registerB;
				4'b1110: result <= registerC;
				4'b1111: begin
				end
				endcase
			end
			end
			endcase
		end
	end else begin
		sampling_counter <= sampling_counter + 19'd1;
	end
end

reg [3:0]  dig1_value;
reg [3:0]  dig2_value;
reg [4:0]  dig3_value;
wire [7:0]  dig1_segments;
wire [7:0]  dig2_segments;
wire [16:0] dig3_segments;

always @(*) begin
	dig1_value = 4'd0;
	dig2_value = 4'd0;
	dig3_value = 5'd0;

	if (!mode) begin
		if (!display_mode) begin
			dig1_value = TA;
			dig2_value = TB;
			case (calculator_operation)
			2'b00: dig3_value = 5'd16;
			2'b01: dig3_value = 5'd17;
			2'b10: dig3_value = 5'd18;
			2'b11: dig3_value = 5'd19;
			endcase
		end else if (calculator_hex) begin
			dig1_value = result / 9'd256;
			dig3_value = (result / 8'd16) % 8'd16;
			dig2_value = result % 8'd16;
		end else begin
			dig1_value = result / 8'd100;
			dig3_value = (result / 8'd10) % 8'd10;
			dig2_value = result % 8'd10;
		end
	end else if (KA[0]) begin
		dig1_value = result / 8'd100;
		dig3_value = (result / 8'd10) % 8'd10;
		dig2_value = result % 8'd10;
	end else begin
		dig1_value = result / 9'd256;
		dig3_value = (result / 8'd16) % 8'd16;
		dig2_value = result % 8'd16;
	end
end

seven left_displayer(
	.TA(dig1_value),
	.OUT(dig1_segments)
);
seven right_displayer(
	.TA(dig2_value),
	.OUT(dig2_segments)
);
sixteen middle_displayer(
	.TA(dig3_value),
	.OUT(dig3_segments)
);

assign LED[7:0] = result;
assign LED[8] = overflow_borrow;
assign LED[9] = error;
assign LED[10] = zero_flag;
assign DIG1 = dig1_segments;
assign DIG2 = dig2_segments;
assign DIG3 = dig3_segments;

endmodule
