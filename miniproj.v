module miniproj(
	input [3:0] TA,
	input [3:0] TB,
	input [3:0] TC,
	input SW1,
	input SW2,
	input CLK,
	output [9:0] LED,
	output [7:0] DIG1,
	output [7:0] DIG2,
	output [16:0] DIG3
);
	reg [7:0] result;
	reg overflow_borrow;
	reg error;
	
	reg [18:0] sampling_counter = 19'b0;
	
	reg SW1_last, SW1_new;
	wire SW1_pe = ~SW1_last & SW1_new;

	reg [3:0] TA_last, TA_new;
	
	reg display_mode = 0;  // 0 for operations, 1 for results
	wire hex_output = TC[1];

	// display decoder inputs and outputs
	reg [3:0] dig1_i;
	wire [7:0] dig1_o;
	reg [3:0] dig2_i;
	wire [7:0] dig2_o;
	reg [4:0] dig3_i;
	wire [16:0] dig3_o;
	
	initial begin
		result = TA;
		overflow_borrow = 0;
		error = 0;
	end
	
	always @(posedge CLK) begin
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
	
	always @(posedge CLK) begin
		if (sampling_counter == 19'b111_1010_0001_0010_0000) begin
			// key press detect
			SW1_new <= SW1; SW1_last <= SW1_new;
			TA_new <= TA; TA_last <= TA_new;
			
			// state transfer
			if (TA_new != TA_last) begin
				overflow_borrow = 0;
				result = TA;
				display_mode = 0;
			end
			if (SW1_pe) begin
				error = 0;
				case (TC[3:2])
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
