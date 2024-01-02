module prefetch (
    input logic clk,
    input logic rst,
    input logic cache_resp,
    input logic mem_read,
    input logic [31:0] mem_address,

    output logic [31:0] mem_address_out,
    output logic cache_read,
    output logic cpu_resp
);

enum int unsigned {
    prefetch, read
} state, next_state;
logic should_load_mem;
assign should_load_mem = mem_read && (state == read);
logic [31:0] mem_prefetch_address_in;
assign mem_prefetch_address_in = mem_address + 32'h0020; //prefetching the data
logic [31:0] mem_prefetch_address_out;
register mem_prefetch_address(
    .clk(clk),
    .rst(rst),
    .load(should_load_mem),
    .in(mem_prefetch_address_in), //prefetching the data
    .out(mem_prefetch_address_out)
);

always_comb begin : state_actions
    cache_read = mem_read;
    cpu_resp = cache_resp;
    mem_address_out = mem_address;
    case (state)
        prefetch: begin
            mem_address_out = mem_prefetch_address_out;
            cpu_resp = 1'b0;
            cache_read = 1'b1;
        end 
        read: begin
            
        end
        default: ;
    endcase
end

always_comb begin : next_state_logic

    next_state = state;
    unique case (state)
        read: begin
            if (mem_read && cache_resp) begin
                next_state = prefetch;
            end else begin
                next_state = read;
            end
        end
        prefetch: begin
            if (cache_resp == 1'b0) begin
                next_state = prefetch;
            end else begin
                next_state = read;
            end
        end 
        default: ;
    endcase
    
end

always_ff @( posedge clk ) begin : next_state_assignment

    if (rst) state <= read;
    else     state <= next_state;
    
end
    
endmodule : prefetch


module register(
    input clk,
    input rst,
    input load,
    input [31:0] in,
    output logic [31:0] out
);

logic [31:0] data;

always_ff @(posedge clk) begin
    if (rst) begin
        data <= '0;
    end else if (load == 1) begin
        data <= in;
    end else begin
        data <= data;
    end
end

assign out = data;

endmodule : register