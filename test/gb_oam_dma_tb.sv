/* Testbench for OAM DMA Module */
module gb_oam_dma_tb ();

    import gb_oam_pkg::*;

    // IO Replication
    logic            clk;
    logic            reset;
    logic            dma_start;
    logic     [15:0] dma_start_addr;
    logic     [ 7:0] data_dma_i;
    logic     [15:0] addr_cpu_i;
    logic     [ 7:0] data_cpu_i;
    logic            wren_cpu;
    logic     [ 6:0] index_ppu_i;
    logic            dma_active;
    logic     [15:0] addr_dma_o;
    logic     [ 7:0] data_o;
    oam_obj_t        obj_o;

    // Module Instance
    gb_oam_dma dut (.*);

    initial begin
        clk = 1'b1;
        forever #2 clk = ~clk;
    end

    initial begin
        $dumpfile("gb_oam_dma_tb.fst");
        $dumpvars();

        repeat (10) @(posedge clk);

        $finish();
    end

endmodule : gb_oam_dma_tb
