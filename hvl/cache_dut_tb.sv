module cache_dut_tb;

    timeunit 1ns;
    timeprecision 1ns;


    //----------------------------------------------------------------------
    // Waveforms.
    //----------------------------------------------------------------------
    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");
    end
    logic [31:0] mem_address, pmem_address;
    logic mem_read, mem_write, mem_resp, pmem_read, pmem_write, pmem_resp;
    logic [31:0] mem_byte_enable;
    logic [255:0] mem_rdata, mem_wdata, pmem_rdata, pmem_wdata;
    assign pmem_resp = 1'b1;

    //----------------------------------------------------------------------
    // Generate the clock.
    //----------------------------------------------------------------------
    bit clk;
    initial clk = 1'b1;
    always #1 clk = ~clk;

    //default clocking tb_clk @(negedge clk); endclocking

    //----------------------------------------------------------------------
    // Generate the reset.
    //----------------------------------------------------------------------
    bit rst;
    task do_reset();
        rst <= 1'b1;
        @(posedge clk);
        rst <= 1'b0;
        @(posedge clk);
    endtask : do_reset

    task reads_to_same_set();
        mem_read <= '1;
        mem_address <= 32'h40000004;
        pmem_rdata <= 256'h600d600d600d600d600d600d600d600d600d600d600d600d600d600d600d600d;
        repeat(2) @(posedge clk);
        assert(dut.datapath.hit == 1'b0);
        $display("hit val: %d", dut.datapath.hit);
        mem_read <= '0;
        repeat(2) @(posedge clk);

        mem_read <= '1;
        mem_address <= 32'h50000004;
        pmem_rdata <= 256'h600d600d600d600d600d600d600d600d600d600d600d600d600d600d600d600d;
        repeat(2) @(posedge clk);
        assert(dut.datapath.hit == 0);
        $display("hit val: %d", dut.datapath.hit);
        mem_read <= '0;
        repeat(2) @(posedge clk);

        mem_read <= '1;
        mem_address <= 32'h60000004;
        pmem_rdata <= 256'h600d600d600d600d600d600d600d600d600d600d600d600d600d600d600d600d;
        repeat(2) @(posedge clk);
        assert(dut.datapath.hit == 1'b0);
        $display("hit val: %d", dut.datapath.hit);
        mem_read <= '0;
        repeat(2) @(posedge clk);

        mem_read <= '1;
        mem_address <= 32'h70000004;
        pmem_rdata <= 256'h600d600d600d600d600d600d600d600d600d600d600d600d600d600d600d600d;
        repeat(2) @(posedge clk);
        assert(dut.datapath.hit == 0);
        $display("hit val: %d", dut.datapath.hit);
        mem_read <= '0;
        repeat(2) @(posedge clk);

        mem_read <= '1;
        mem_address <= 32'h40000004;
        pmem_rdata <= 256'h600d600d600d600d600d600d600d600d600d600d600d600d600d600d600d600d;
        repeat(2) @(posedge clk);
        assert(dut.datapath.hit == 1);
        $display("hit val: %d", dut.datapath.hit);
        mem_read <= '0;
        repeat(2) @(posedge clk);

        mem_read <= '1;
        mem_address <= 32'h50000004;
        pmem_rdata <= 256'h600d600d600d600d600d600d600d600d600d600d600d600d600d600d600d600d;
        repeat(2) @(posedge clk);
        assert(dut.datapath.hit == 1);
        $display("hit val: %d", dut.datapath.hit);
        mem_read <= '0;
        repeat(2) @(posedge clk);

        mem_read <= '1;
        mem_address <= 32'h60000004;
        pmem_rdata <= 256'h600d600d600d600d600d600d600d600d600d600d600d600d600d600d600d600d;
        repeat(2) @(posedge clk);
        assert(dut.datapath.hit == 1);
        $display("hit val: %d", dut.datapath.hit);
        mem_read <= '0;
        repeat(2) @(posedge clk);

        mem_read <= '1;
        mem_address <= 32'h70000004;
        pmem_rdata <= 256'h600d600d600d600d600d600d600d600d600d600d600d600d600d600d600d600d;
        repeat(2) @(posedge clk);
        assert(dut.datapath.hit == 1);
        $display("hit val: %d", dut.datapath.hit);
        mem_read <= '0;
        repeat(2) @(posedge clk);
    
        mem_read <= '1;
        mem_address <= 32'h80000004;
        pmem_rdata <= 256'h600d600d600d600d600d600d600d600d600d600d600d600d600d600d600d600d;
        repeat(2) @(posedge clk);
        assert(dut.datapath.hit == 0);
        $display("hit val: %d", dut.datapath.hit);
        mem_read <= '0;
        repeat(2) @(posedge clk);

        mem_read <= '1;
        mem_address <= 32'h60000004;
        pmem_rdata <= 256'h600d600d600d600d600d600d600d600d600d600d600d600d600d600d600d600d;
        repeat(2) @(posedge clk);
        assert(dut.datapath.hit == 1);
        $display("hit val: %d", dut.datapath.hit);
        mem_read <= '0;
        repeat(2) @(posedge clk);



    endtask : reads_to_same_set

    // task read_n_hit();
    //     mem_read <= 1;
    //     mem_address <= 32'h40000004;
    //     @(tb_clk);


    // endtask : read

    // task coldstart_read();

    // endtask: coldstart_read();

    //----------------------------------------------------------------------
    // Collect coverage here:
    //----------------------------------------------------------------------
    // covergroup cache_cg with function sample(...)
    //     // Fill this out!
    // endgroup
    // Note that you will need the covergroup to get `make covrep_dut` working.

    //----------------------------------------------------------------------
    // Want constrained random classes? Do that here:
    //----------------------------------------------------------------------
    // class RandAddr;
    //     rand bit [31:0] addr;
    //     // Fill this out!
    // endclass : RandAddr

    //----------------------------------------------------------------------
    // Instantiate your DUT here.
    //----------------------------------------------------------------------


    cache #(5, 4, 3) dut (.*);

    //----------------------------------------------------------------------
    // Write your tests and run them here!
    //----------------------------------------------------------------------
    // Recommended: package your tests into tasks.

    initial begin
        $display("Hello from mp3_cache_dut!");

        do_reset();
        reads_to_same_set();

        $finish;
    end


    //----------------------------------------------------------------------
    // You likely want a process for pmem responses, like this:
    //----------------------------------------------------------------------
    // always @(posedge clk) begin
    //     // Set pmem signals here to behaviorally model physical memory.
    //     pmem_resp <= 1;

    // end


endmodule
