module cache_control_two_cycle #(
            parameter       s_offset = 5,
            parameter       s_index  = 4,
            parameter       s_tag    = 32 - s_offset - s_index,
            parameter       s_mask   = 2**s_offset,
            parameter       s_line   = 8*s_mask,
            parameter       num_sets = 2**s_index
)
(
    input clk,
    input rst,
    input logic mem_read,
    input logic mem_write,
    output logic mem_resp,

    input logic pmem_resp,
    output logic pmem_read,
    output logic pmem_write,

    input logic hit,
    input logic [0:0] hit_path,
    input logic [0:0] lru_path,
    input logic lru_dirty_bit,
    input logic lru_valid_bit,
    output logic load_tag_array [2],
    output logic load_valid_array [2],
    output logic load_dirty_array[2],
    output logic dirty_input_array [2],
    input logic [0:0] lru_output,
    output logic [0:0] lru_input,
    output logic load_lru,
    output logic data_bit,
    output logic addr_bit,
    output logic load_data_array[2],
    output logic dmem_resp_signal
);

enum logic [2:0] {
    idle_state,
    matching_state,
    dmem_set_state,
    writeback_state,
    load_state
} state, next_state;

//set the defaults of the arrays and other signals
function void set_defaults();
    for (int i = 0; i < 2; ++i) begin
        load_tag_array[i] = 1'b1;
        load_dirty_array[i] = 1'b1;
        load_data_array[i] = 1'b1;
        load_valid_array[i] = 1'b1;
        dirty_input_array[i] = 1'b0;
    end
    mem_resp = 1'b0;
    pmem_read = 1'b0;
    pmem_write = 1'b0;  
    load_lru = 1'b1;
    data_bit = 1'b1;
    addr_bit = 1'b0;
    dmem_resp_signal = 1'b0;
endfunction

assign lru_input = ~hit_path;
logic temp_reg;
assign temp_reg = lru_output;

always_comb begin : state_actions
    set_defaults();
    unique case (state)

        matching_state: begin
            //match load_lru to hit (negate as writing is active low)
            if (hit == 1'b1) begin
                load_lru = 1'b0;
            end else begin
                load_lru = 1'b1;
            end
            //set signal mem_resp equal to hit
            mem_resp = hit;
            //set data bit to read from memory
            data_bit = 1'b0;
            //if there is a hit and I am writing, make sure to load data array
            if ((hit & mem_write) == 1'b1) begin
                load_data_array[hit_path] = 1'b0;
            end else begin
                load_data_array[hit_path] = 1'b1;
            end
            dirty_input_array[hit_path] = 1'b1;
            if ((hit & mem_write) == 1'b1) begin
                load_dirty_array[hit_path] = 1'b0;
            end else begin
                load_dirty_array[hit_path] = 1'b1;
            end

        end

        dmem_set_state: begin
            dmem_resp_signal = 1'b1;
        end

        load_state: begin
            //load tag and valid array
            load_tag_array[lru_path] = 1'b0;
            load_valid_array[lru_path] = 1'b0;
            //set load data equal to cacheline adaptor response
            if (pmem_resp == 1'b1) begin
                load_data_array[lru_path] = 1'b0;
            end else begin
                load_data_array[lru_path] = 1'b1;
            end
            dirty_input_array[lru_path] = 1'b0;
            load_dirty_array[lru_path] = 1'b0;
            //set pmem_read to 1 and data bit to 1 so that I read from
            // pmem_rdata
            pmem_read = 1'b1;
            data_bit = 1'b1;
        end
        writeback_state: begin
            pmem_write = 1'b1;
            addr_bit = 1'b1;
        end
        default: ;
    endcase
end


always_comb begin : next_state_logic
    unique case (state)

        idle_state: begin
            //go to matching state if mem read or mem write
            if (mem_read | mem_write) begin
                next_state = matching_state;
            end else begin
                //else stay idle
                next_state = idle_state;
            end
        end
        matching_state: begin
            //if there is no hit, and valid bit is 0, then go to load
            if (~hit == 1'b1) begin
                if (~lru_valid_bit || ~lru_dirty_bit) begin
                    next_state = load_state;
                end else begin
                    next_state = writeback_state;
                end
            end else begin
                //otherwise go back to idle
                next_state = dmem_set_state;
            end  
        end

        dmem_set_state: begin
            next_state = idle_state;
        end

        load_state: begin
            if (pmem_resp == 1'b1) begin
                next_state = matching_state;
            end else begin
                next_state = load_state;
            end 
        end

        writeback_state: begin
            if (pmem_resp == 1'b1) begin
                next_state = load_state;
            end else begin
                next_state = writeback_state;
            end 
        end

        default: next_state = state;
    endcase  
end
always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    if (rst) state <= idle_state;
    else     state <= next_state;
end
endmodule : cache_control_two_cycle
