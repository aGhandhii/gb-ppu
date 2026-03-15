/* Top Level Testbench for PPU */
module gb_ppu_tb ();

    import gb_ppu_common_pkg::*;
    import gb_oam_pkg::*;

    // IO Replication
    logic                   clk_t;
    logic                   clk_m;
    logic                   reset;
    logic            [15:0] addr;
    logic            [ 7:0] data_i;
    logic                   wren_cpu;
    ppu_mode_state_t        ppu_mode;
    logic            [ 7:0] data_o;
    logic                   irq_vblank;
    logic                   irq_stat;
    logic                   dma_start;
    logic            [15:0] dma_start_addr;

    // Instance
    gb_ppu dut (.*);

    // clock emulation
    logic [2:0] cntr;
    assign clk_t = cntr[0];
    assign clk_m = cntr[2];
    initial begin
        cntr = 3'd0;
        forever #10 cntr = cntr + 3'd1;
    end

    // Testbench
    initial begin
        $dumpfile("gb_ppu_tb.fst");
        $dumpvars();

        repeat (9999) @(posedge clk_t);

        $finish();
    end


endmodule : gb_ppu_tb
