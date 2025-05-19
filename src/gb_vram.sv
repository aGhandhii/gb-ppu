/* GameBoy Video RAM Module

Contains Video RAM for use by the CPU and PPU.

Inputs:
    clk     - M-Clock (~1MHz)
    reset   - System Reset
    addr    - 16-Bit Address Bus (Either CPU or PPU Mode 3)
    data_i  - 8-Bit Input Data from CPU
    wren    - CPU Write Enable (Inactive During PPU Mode 3)

Outputs:
    data_o  - Requested 8-Bit VRAM Data
*/
module gb_vram (
    input  logic        clk,
    input  logic        reset,
    input  logic [15:0] addr,
    input  logic [ 7:0] data_i,
    input  logic        wren,
    output logic [ 7:0] data_o
);

    // VRAM is 8KiB (8192 Bytes) located in Memory 0x8000-0x9FFF
    logic [7:0] VRAM[8192];

    always_comb
        if (addr[15:13] == 3'b100) data_o = VRAM[addr[12:0]];
        else data_o = 8'hxx;

    always_ff @(posedge clk, reset)
        if (reset) for (integer i = 0; i < 8192; i++) VRAM[i] <= 8'h00;
        else if (wren && (addr[15:13] == 3'b100)) VRAM[addr[12:0]] <= data_i;

endmodule : gb_vram
