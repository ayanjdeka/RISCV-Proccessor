module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);
    logic read_write_input_value;
	logic read_write;
	logic [31:0] address_o_input;
	logic [63:0] burst_o_input;
	logic [255:0] line_o_input;

	enum logic [2:0] {
		start_state,
		delay_state,
		first_state,
		second_state,
		third_state,
		fourth_state,
		done_state
	} state, next_state;

	function void set_defaults();
		
		read_write_input_value = read_write;
		line_o_input = line_o;
		burst_o_input = 64'b0;
		resp_o = 1'b0;
		
	endfunction

	always_comb begin : state_logic
		address_o_input = address_i;
		set_defaults();
		if (state == fourth_state || state == second_state || state == first_state || state == third_state) begin
			read_o = (~read_write);
			write_o = read_write;
		end else begin
			write_o = 1'b0;
			read_o = 1'b0;
		end

		unique case (state)

			start_state: begin
				if (write_i == 1'b1) begin
					read_write_input_value = 1'b1;
					burst_o_input = line_i[0 +: 64];
				end else if (read_i == 1'b1) begin
					read_write_input_value = 1'b0;
				end
			end

			first_state: begin
				if (read_write == 1'b0) begin
					line_o_input[0 +: 64] = burst_i;
				end else begin
					if (resp_i == 1'b1) begin
						burst_o_input = line_i[64 +: 64];
					end else begin
						burst_o_input = line_i[0 +: 64];
					end
				end
			end

			second_state: begin
				if (read_write == 1'b0) begin
					line_o_input[64 +: 64] = burst_i;
				end else begin
					burst_o_input = line_i[128 +: 64];
				end
			end

			third_state: begin
				if (read_write == 1'b0) begin
					line_o_input[128 +: 64] = burst_i;
				end else begin
					burst_o_input = line_i[192 +: 64];
				end
			end

			fourth_state: begin
				if (read_write == 1'b0) begin
					line_o_input[192 +: 64] = burst_i;
				end
			end

			done_state: begin
				resp_o = 1'b1;
			end
			default: ;
		endcase
	end

	always_comb begin : next_state_logic
		unique case (state)
			start_state: begin
				if (write_i == 1'b1) begin
					next_state = first_state;
				end else if (read_i == 1'b1) begin
					next_state = first_state;
				end else begin
					next_state = start_state;
				end
			end 
			first_state: begin
				if (resp_i == 1'b1) begin
					next_state = second_state;
				end else begin
					next_state = first_state;
				end
			end
			second_state: begin
				next_state = third_state;
			end
			third_state: begin
				next_state = fourth_state;
			end
			fourth_state: begin
				next_state = done_state;
			end
			done_state: begin
				next_state = start_state;
			end
			default: next_state = state;
		endcase
	end

	always_ff @(posedge clk) begin
		if (~reset_n) begin
			state <= start_state;
			read_write <= 1'b0;
			line_o <= '0;
			address_o <= '0;
			burst_o <= '0;
		end else begin
			state <= next_state;
			read_write <= read_write_input_value;
			line_o <= line_o_input;
			address_o <= address_o_input;
			burst_o <= burst_o_input;
		end
	end

endmodule : cacheline_adaptor
