module prefetch_dut_tb;

timeunit 1ns;
timeprecision 1ns;

bit clk;
always #5 clk = ~clk;

logic rst;

logic [31:0] mem_address;
logic mem_read;
logic cpu_resp;

logic [31:0] mem_address_out;
logic cache_read;
logic cache_resp;

prefetch dut(
    .clk(clk),
    .rst(rst),
    .mem_address(mem_address), 
    .mem_read(mem_read),
    .cpu_resp(cpu_resp),
    .mem_address_out(mem_address_out),
    .cache_read (cache_read),
    .cache_resp(cache_resp)
);

task automatic reset();

    rst = 1'b1;
    repeat (5) @(posedge clk);
    rst = 1'b0;
    
endtask //automatic


task automatic prefetch_after_read(logic [31:0] addr, logic [31:0] expect_addr);
    // start reading
    mem_address=addr;
    mem_read=1'b1;
    @(posedge clk);
    assert(cache_read == 1'b1);
    assert(mem_address_out == addr);
    repeat (10) @(posedge clk);
    cache_resp=1'b1;
    @(posedge clk);
    cache_resp=1'b0;
    assert(cpu_resp == 1'b1);
    assert(cache_read == 1'b1);
    @(posedge clk);
    mem_address=32'b0;
    mem_read=1'b0;
    repeat (9) @(posedge clk);
    cache_resp=1'b1; 
    @(posedge clk);
    cache_resp=1'b0;
    assert(cpu_resp == 1'b0);
endtask


//this will test a prefetch, and another prefetch that happens right after
task automatic read_while_prefetch(logic [31:0] addr, logic [31:0] expect_addr,logic [31:0] second_addr, logic [31:0] second_expect_addr);
    mem_address = addr;
    mem_read = 1'b1;
    @(posedge clk);
    assert(cache_read == 1'b1);
    assert(mem_address_out == addr);
    repeat(10) @(posedge clk);
    cache_resp = 1'b1;
    @(posedge clk);
    cache_resp = 1'b0;
    assert(cpu_resp == 1'b1);
    assert(mem_address_out == expect_addr);
    assert(cache_read == 1'b1);
    @(posedge clk);
    mem_read = 1'b1;
    mem_address = second_addr;
    repeat (10) @(posedge clk);
    cache_resp=1'b1; 
    @(posedge clk);
    cache_resp=1'b0;
    assert(cpu_resp == 1'b1);
    assert(mem_address_out == second_expect_addr);
    assert(cache_read == 1'b1);


endtask

task automatic read_while_prefetching(logic [31:0] addr, logic [31:0] expect_addr);
    // start reading
    mem_address=addr;
    mem_read=1'b1;
    // next clock cycle check the output
    @(posedge clk);
    assert(cache_read == 1);
    assert(mem_address_out == addr);
    repeat (10) @(posedge clk);
    cache_resp=1'b1;
    @(posedge clk);
    cache_resp=1'b0;
    assert(cache_read == 1);
    assert(cpu_resp == 1);
endtask


initial begin : test_vectors
    

    reset();
    prefetch_after_read(32'hABCD1234,32'hABCD1334);
    read_while_prefetching(32'hABCD1234,32'hABCD1334);
    $finish;
    
end




endmodule