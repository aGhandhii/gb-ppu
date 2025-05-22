import gb_ppu_common_pkg::*;
import gb_oam_pkg::*;
/* Top Level Module for GameBoy PPU

Inputs:
    clk_t           - System Clock  (T Clock, ~4MHz)
    clk_m           - Machine Clock (M Clock, ~1MHz)
    reset           - System Reset
    addr            - 16-Bit Address Bus
    data_i          - 8-Bit Input Data

Outputs:
    data_o          - 8-bit Output Data
    irq_stat        - STAT Interrupt Request Line
    dma_start       - Start DMA Transfer
    dma_start_addr  - Start Address for DMA Transfer
*/
module gb_ppu (
    input  logic        clk_t,
    input  logic        clk_m,
    input  logic        reset,
    input  logic [15:0] addr,
    input  logic [ 7:0] data_i,
    output logic [ 7:0] data_o,
    output logic        irq_stat,
    output logic        dma_start,
    output logic        dma_start_addr
);

    // Store PPU state information
    ppu_mode_state_t ppu_mode;

    // For Interrupts, store whether PPU is in certain state
    logic in_mode_0, in_mode_1, in_mode_2;
    assign in_mode_0 = (ppu_mode == HBLANK) ? 1'b1 : 1'b0;
    assign in_mode_1 = (ppu_mode == VBLANK) ? 1'b1 : 1'b0;
    assign in_mode_2 = (ppu_mode == OAM_SCAN) ? 1'b1 : 1'b0;

    /* DMG PPU CONTROL REGISTERS (0xFF40-0xFF4B)
        0xFF40 - LCDC (LCD Control Register)
        0xFF41 - STAT (LCD Status) (bits [2:0] are READ-ONLY)
        0xFF42 - SCY  (Background Viewport Y position)
        0xFF43 - SCX  (Background Viewport X position)
        0xFF44 - LY   (LCD Y-Coordinate) (READ-ONLY)
        0xFF45 - LYC  (LCD Y-Coordinate Compare)
        0xFF46 - DMA  (OAM DMA Source Address and Start)
        0xFF47 - BGP  (Background Palette Data)
        0xFF48 - OBP0 (Object Palette 0)
        0xFF49 - OBP1 (Object Palette 1)
        0xFF4A - WY   (Window Y Position)
        0xFF4B - WX   (Window X Position + 7)
    */
    logic [7:0]
        reg_LCDC, reg_STAT, reg_SCY, reg_SCX, reg_LY, reg_LYC, reg_DMA, reg_BGP, reg_OBP0, reg_OBP1, reg_WY, reg_WX;

    // Store LCDC register signals
    lcd_control_t LCDC;
    always_comb begin : setLCDCsignals
        LCDC.lcd_ppu_enable         = reg_LCDC[7];
        LCDC.win_tile_map           = reg_LCDC[6];
        LCDC.win_enable             = reg_LCDC[5];
        LCDC.bg_win_tiles           = reg_LCDC[4];
        LCDC.bg_tile_map            = reg_LCDC[3];
        LCDC.obj_size               = reg_LCDC[2];
        LCDC.obj_enable             = reg_LCDC[1];
        LCDC.bg_win_enable_priority = reg_LCDC[0];
    end

    // Store LCD Status Signals
    lcd_status_t STAT;
    always_comb begin : setSTATsignals
        STAT.lyc_irq_cond    = reg_STAT[6];
        STAT.mode_2_irq_cond = reg_STAT[5];
        STAT.mode_1_irq_cond = reg_STAT[4];
        STAT.mode_0_irq_cond = reg_STAT[3];
        STAT.lyc_ly_compare  = (reg_LY == reg_LYC) ? 1'b1 : 1'b0;
        STAT.ppu_mode        = ppu_mode;
    end
    assign reg_STAT[2] = STAT.lyc_ly_compare;
    assign reg_STAT[1:0] = STAT.ppu_mode;

    // Handle the STAT Interrupt Request
    assign irq_stat = (STAT.lyc_ly_compare & STAT.lyc_irq_cond) |
                      (in_mode_0 & STAT.mode_0_irq_cond) |
                      (in_mode_1 & STAT.mode_1_irq_cond) |
                      (in_mode_2 & STAT.mode_2_irq_cond);

    // Store Palette Registers
    palette_register_t BGP, OBP0, OBP1;
    always_comb begin : setPaletteRegisters
        BGP.id_0  = pixel_color_t'(reg_BGP[1:0]);
        BGP.id_1  = pixel_color_t'(reg_BGP[3:2]);
        BGP.id_2  = pixel_color_t'(reg_BGP[5:4]);
        BGP.id_3  = pixel_color_t'(reg_BGP[7:6]);
        OBP0.id_0 = WHITE;
        OBP0.id_1 = pixel_color_t'(reg_OBP0[3:2]);
        OBP0.id_2 = pixel_color_t'(reg_OBP0[5:4]);
        OBP0.id_3 = pixel_color_t'(reg_OBP0[7:6]);
        OBP1.id_0 = WHITE;
        OBP1.id_1 = pixel_color_t'(reg_OBP1[3:2]);
        OBP1.id_2 = pixel_color_t'(reg_OBP1[5:4]);
        OBP1.id_3 = pixel_color_t'(reg_OBP1[7:6]);
    end

    // Specify DMA Start Address for Transfer
    assign dma_start_addr = {reg_DMA, 8'h00};

    // PPU Register Reads
    always_comb begin : PPUregRead
        case (addr) inside
            16'hFF40: data_o = reg_LCDC;
            16'hFF41: data_o = reg_STAT;
            16'hFF42: data_o = reg_SCY;
            16'hFF43: data_o = reg_SCX;
            16'hFF44: data_o = reg_LY;
            16'hFF45: data_o = reg_LYC;
            16'hFF46: data_o = reg_DMA;
            16'hFF47: data_o = reg_BGP;
            16'hFF48: data_o = reg_OBP0;
            16'hFF49: data_o = reg_OBP1;
            16'hFF4A: data_o = reg_WY;
            16'hFF4B: data_o = reg_WX;
            default:  data_o = 8'hxx;
        endcase
    end : PPUregRead

    // PPU Register Writes and DMA Start Signal
    always_ff @(posedge clk_m, reset)
        if (reset) begin
            dma_start <= 1'b0;
            reg_LCDC  <= 8'h00;
            reg_STAT  <= 8'h00;
            reg_SCY   <= 8'h00;
            reg_SCX   <= 8'h00;
            reg_LY    <= 8'h00;
            reg_LYC   <= 8'h00;
            reg_DMA   <= 8'h00;
            reg_BGP   <= 8'h00;
            reg_OBP0  <= 8'h00;
            reg_OBP1  <= 8'h00;
            reg_WY    <= 8'h00;
            reg_WX    <= 8'h00;
        end else if (wren_cpu) begin
            case (addr) inside
                16'hFF40: reg_LCDC <= data_i;
                16'hFF41: reg_STAT[7:3] <= data_i[7:3];
                16'hFF42: reg_SCY <= data_i;
                16'hFF43: reg_SCX <= data_i;
                16'hFF45: reg_LYC <= data_i;
                16'hFF46: begin
                    reg_DMA   <= data_i;
                    dma_start <= 1'b1;
                end
                16'hFF47: reg_BGP <= data_i;
                16'hFF48: reg_OBP0 <= data_i;
                16'hFF49: reg_OBP1 <= data_i;
                16'hFF4A: reg_WY <= data_i;
                16'hFF4B: reg_WX <= data_i;
            endcase
        end else if (dma_start && ~(wren && (addr == 16'hFF46))) begin
            dma_start <= 1'b0;
        end


endmodule : gb_ppu
