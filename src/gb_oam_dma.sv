import gb_oam_pkg::*;
/* GameBoy Object Attribute Memory and DMA Transfer

Contains Object Attribute Memory (OAM) and the Direct Memory Access Controller
for the GameBoy.

Inputs:
    clk             - System Clock (M Clock, ~1MHz)
    reset           - System Reset

    dma_start       - DMA Transfer Start Signal
    dma_start_addr  - 16-Bit DMA Transfer Start Address
    data_dma_i      - 8-Bit Data for DMA Transfer Request

    addr_cpu_i      - 16-Bit Address Bus
    data_cpu_i      - 8-Bit Input Data from CPU
    wren_cpu        - CPU Write Enable

    index_ppu_i     - Requested Object Index from PPU

Outputs:
    dma_active      - If DMA Transfer is Active

    addr_dma_o      - DMA Address Line

    data_o          - 8-Bit Output Data from OAM
    obj_o           - Output OAM Object from Requested Index for PPU

*/
/* verilator lint_off MULTIDRIVEN */
module gb_oam_dma (
    input  logic            clk,
    input  logic            reset,
    input  logic            dma_start,
    input  logic     [15:0] dma_start_addr,
    input  logic     [ 7:0] data_dma_i,
    input  logic     [15:0] addr_cpu_i,
    input  logic     [ 7:0] data_cpu_i,
    input  logic            wren_cpu,
    input  logic     [ 6:0] index_ppu_i,
    output logic            dma_active,
    output logic     [15:0] addr_dma_o,
    output logic     [ 7:0] data_o,
    output oam_obj_t        obj_o
);

    // OAM is 160 Bytes mapped to 0xFE00-0xFE9F in Memory
    logic [7:0] OAM[160];

    // OAM is comprised of 40 Objects (Sprites)
    oam_obj_t [39:0] oam_objects;
    assign obj_o = oam_objects[index_ppu_i];
    always_comb
        for (logic [7:0] index = 8'd0; index < 8'd160; index = index + 8'd4) begin
            oam_objects[index>>2].y_position   = OAM[index];
            oam_objects[index>>2].x_position   = OAM[index+8'd1];
            oam_objects[index>>2].tile_index   = OAM[index+8'd2];
            oam_objects[index>>2].obj_priority = OAM[index+8'd3][7];
            oam_objects[index>>2].y_flip       = OAM[index+8'd3][6];
            oam_objects[index>>2].x_flip       = OAM[index+8'd3][5];
            oam_objects[index>>2].dmg_palette  = OAM[index+8'd3][4];
        end

    // CPU Reads
    always_comb
        if ((addr_cpu_i[15:8] == 8'hFE) && (addr_cpu_i[7:0] < 8'hA0)) data_o = OAM[addr_cpu_i[7:0]];
        else data_o = 8'hxx;

    // CPU Writes
    always_ff @(posedge clk, reset)
        if (reset) for (integer i = 0; i < 160; i++) OAM[i] <= 8'h00;
        else if (wren_cpu && (addr_cpu_i[15:8] == 8'hFE) && (addr_cpu_i[7:0] < 8'hA0) && ~dma_active)
            OAM[addr_cpu_i[7:0]] <= data_cpu_i;


    // We need a counter for DMA Transfer - this takes 160 M-Cycles
    logic [7:0] dma_transfer_counter;

    // The DMA request address is tied to the counter
    assign addr_dma_o = dma_start_addr + {8'h00, dma_transfer_counter};

    // Main Logic - DMA Transfer
    always_ff @(posedge clk, reset)
        if (reset) begin
            dma_transfer_counter <= 8'd0;
            dma_active           <= 1'b0;
        end else begin
            if (dma_start) begin
                OAM[dma_transfer_counter] <= data_dma_i;
                dma_transfer_counter      <= 8'd0;
                dma_active                <= 1'b1;
            end else begin
                OAM[dma_transfer_counter] <= dma_active ? data_dma_i : OAM[dma_transfer_counter];
                dma_transfer_counter      <= (dma_transfer_counter == 8'd159) ? 8'd0 : dma_transfer_counter + 8'd1;
                dma_active                <= (dma_transfer_counter == 8'd159) ? 1'b0 : 1'b1;
            end
        end

endmodule : gb_oam_dma
/* verilator lint_on MULTIDRIVEN */
