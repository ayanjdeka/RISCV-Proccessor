module arbiter(
    input logic clk,
    input logic rst,
    input logic instruction_read,
    input logic [31:0] instruction_address,
    output logic [255:0] instruction_data,
    output logic instruction_resp,

    input logic data_read,
    input logic data_write,
    input logic [31:0] data_address,
    input logic [255:0] data_wdata,
    output logic data_resp,
    output logic [255:0] data_rdata,

    input logic pmem_resp,
    input logic [255:0] pmem_rdata,
    output logic pmem_write,
    output logic pmem_read,
    output logic [255:0] pmem_wdata,
    output logic [31:0] pmem_address
);

enum int unsigned {
    idle_state, instruction_state, data_state
} state, next_states;

function void set_defaults();
    pmem_write=1'b0;
    pmem_read=1'b0;
    pmem_address=32'b0;
    pmem_wdata=256'b0;
    data_rdata=256'b0;
    data_resp=1'b0;
    instruction_data=256'b0;
    instruction_resp=1'b0;
endfunction

always_comb begin : state_actions
    set_defaults();
    unique case (state)
        idle_state: ;

        instruction_state: begin
            pmem_read = instruction_read;
            pmem_address = instruction_address;
            instruction_data = pmem_rdata;
            instruction_resp = pmem_resp;
        end

        data_state: begin
            pmem_address = data_address;
            data_resp = pmem_resp;
             if (data_read) begin
                pmem_read = data_read;
                data_rdata = pmem_rdata;
             end else if (data_write) begin
                pmem_write = data_write;
                pmem_wdata = data_wdata;
            end
        end
        default: ;
    endcase
end
always_comb begin : next_state_logic
    unique case (state)
        idle_state: begin
            if(data_read || data_write) begin
                next_states = data_state;
            end
            else if (instruction_read) begin
                next_states = instruction_state;
            end
            else begin
                next_states = idle_state;
            end 
        end
        instruction_state: begin
            if(pmem_resp) begin
                next_states = idle_state;
            end
            else begin
                next_states = instruction_state;
            end
        end
        data_state: begin
            if(pmem_resp) begin
                next_states = idle_state;
            end
            else begin
                next_states = data_state;
            end
        end
    endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    if (rst) begin
        state <= idle_state;
    end
    else begin 
        state <= next_states;
    end
end
endmodule