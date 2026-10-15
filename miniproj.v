module miniproj(
	input [3:0] TA,
	input [3:0] TB,
	input [3:0] TC,
	input [3:0] KA,
	input SW1,
	input SW2,
	input CLK,
	output [10:0] LED,
	output [7:0] DIG1,
	output [7:0] DIG2,
	output [16:0] DIG3
);

// result variables
reg [7:0] result;  // initialized in the first (sampling) cycle depending on mode
reg overflow_borrow = 0;
reg error = 0;

// sampling counter used for debouncing
reg [18:0] sampling_counter = 19'b0;

// variables used for SW1 debouncing
reg SW1_last, SW1_new;
wire SW1_pe = ~SW1_last & SW1_new;

// variables used for TA state change detection
reg [3:0] TA_last, TA_new;

// variables used for SW2 debouncing
reg SW2_last, SW2_new;
wire SW2_pe = ~SW2_last & SW2_new;
wire SW2_ne = SW2_last & ~SW2_new;

// variables used in calculator mode
reg display_mode = 0;  // 0 for operations, 1 for results
wire hex_output = TC[1];
wire operations = TC[3:2];

// mode indicator
reg mode;  // 0 for calculator, 1 for ALU

// variables used for initialization
reg initialized = 0;

// variables used in ALU mode
reg [7:0] registerA = 0;
reg [7:0] registerB = 0;
reg [7:0] registerC = 0;
reg zero_flag = 0;

// display interface
reg [3:0] dig1_i;
reg [3:0] dig2_i;
reg [4:0] dig3_i;

// variables used for display
wire [7:0] dig1_o;
wire [7:0] dig2_o;
wire [16:0] dig3_o;

always @(posedge CLK) begin
	case (mode)
	0: begin
	if (display_mode == 0) begin  // operation mode
		case (TC[3:2])
		2'b00: dig3_i = 16;
		2'b01: dig3_i = 17;
		2'b10: dig3_i = 18;
		2'b11: dig3_i = 19;
		endcase
		dig1_i = TA;
		dig2_i = TB;
	end else begin  // result mode
		if (hex_output) begin
			dig2_i = result % 16;
			dig3_i = (result / 16) % 16;
			dig1_i = (result / 256);
		end else begin
			dig2_i = result % 10;
			dig3_i = (result / 10) % 10;
			dig1_i = (result / 100);
		end
	end
	end
	1: begin
	case (KA[0])
	0: begin
		dig2_i = result % 16;
		dig3_i = (result / 16) % 16;
		dig1_i = (result / 256);
	end
	1: begin
		dig2_i = result % 10;
		dig3_i = (result / 10) % 10;
		dig1_i = (result / 100);
	end
	endcase
	end
	endcase
end

always @(posedge CLK) begin
	if (sampling_counter == 19'b111_1010_0001_0010_0000) begin
		if (!initialized) begin
			initialized = 1;
			mode = SW2;
			if (mode == 0) begin
				result = TA;
			end else begin
				result = 0;
			end
		end

		// key press detect
		SW1_new <= SW1; SW1_last <= SW1_new;
		SW2_new <= SW2; SW2_last <= SW2_new;
		TA_new <= TA; TA_last <= TA_new;
		
		// state transfer
		case (mode)
		0: begin
		if (TA_new != TA_last) begin
			overflow_borrow = 0;
			result = TA;
			display_mode = 0;
		end
		if (SW1_pe) begin
			error = 0;
			case (operations)
			2'b00: begin
				{overflow_borrow, result} = result + TB;
			end
			2'b01: begin
				{overflow_borrow, result} = result - TB;
			end
			2'b10: begin
				result = result[3:0] * TB;
			end
			2'b11: begin
				if (TB == 0) begin
					error = 1;
					result = 0;
				end else begin
					result = result / TB;
				end
			end
			endcase
			display_mode = 1;
		end
		if (SW2_pe) begin
			error = 0;
			overflow_borrow = 0;
			registerA = 0;
			registerB = 0;
			registerC = 0;
			zero_flag = 0;
			result = 0;
			mode = 1;
		end
		end
		1: begin
		if (SW2_ne) begin
			error = 0;
			overflow_borrow = 0;
			display_mode = 0;
			mode = 0;
		end
		if (SW1_pe) begin
			error = 0;
			overflow_borrow = 0;
			zero_flag = ~(|registerA);
			case (TC)
			4'b0000: registerA = {TA, TB};
			4'b0001: registerB = {TA, TB};
			4'b0010: registerC = {TA, TB};
			4'b0011: registerA = ~registerA;  // 1's complement
			4'b0100: {overflow_borrow, registerA} = registerA + registerB;
			4'b0101: {overflow_borrow, registerA} = registerA + registerC;
			4'b0110: {overflow_borrow, registerA} = registerA - registerB;
			4'b0111: {overflow_borrow, registerA} = registerA - registerC;
			4'b1000: {registerA, registerB} = registerA * registerB;
			4'b1001: begin
				if (registerB == 0) begin
					registerA = 0;
					error = 1;
				end else begin
					registerA = registerA / registerB;
				end
			end
			4'b1010: registerA = registerA << 1;
			4'b1011: registerA = registerA >> 1;
			4'b1100: result = registerA;
			4'b1101: result = registerB;
			4'b1110: result = registerC;
			4'b1111:;  // reserved
			endcase
		end
		end
		endcase

		// reset sampling counter
		sampling_counter = 0;
	end
	// update sampling counter
	sampling_counter = sampling_counter + 1;
end

// display LEDs
assign LED[7:0] = result;
assign LED[8] = overflow_borrow;
assign LED[9] = error;
assign LED[10] = zero_flag;

// display digits
seven left_displayer(
	.TA (dig1_i),
	.OUT (dig1_o)
);
seven right_displayer(
	.TA (dig2_i),
	.OUT (dig2_o)
);
sixteen middle_displayer(
	.TA (dig3_i),
	.OUT (dig3_o)
);

assign DIG1 = dig1_o;
assign DIG2 = dig2_o;
assign DIG3 = dig3_o;
endmodule
