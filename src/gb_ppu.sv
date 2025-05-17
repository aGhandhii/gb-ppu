import gb_ppu_common_pkg::*;
/* Top Level Module for GameBoy PPU

Inputs:
    clk         - System Clock (T Clock, ~4MHz)
    reset       - System Reset
    addr        - 16-Bit Address Bus
    data_i      - 8-Bit Input Data

Outputs:
    data_o      - 8-bit Output Data
*/
module gb_ppu ();

    // Store PPU state information
    ppu_mode_state_t ppu_mode;

    /* DMG PPU CONTROL REGISTERS (0xFF40-0xFF4B)
        0xFF40 - LCDC (LCD Control Register)
        0xFF41 - STAT (LCD Status) (bits [2:0] are READ-ONLY)
        0xFF42 - SCY  (Background Viewport Y position)
        0xFF43 - SCX  (Background Viewport X position)
        0xFF44 - LY   (LCD Y-Coordinate) (READ-ONLY)
        0xFF45 - LYC  (LCD Y-Coordinate Compare)
        0xFF46 - DMA  (OAM DMA Source Address and Start)
            - Starts DMA transfer, takes 640 T-Cycles (160 M-Cycles)
                - Register value can range from [0x00-0xDF]
                - Start Address is 0x00XX, where XX is the register value
            - CPU can only access HRAM (0xFF80-0xFFFE) during DMA Transfer
        0xFF47 - BGP  (Background Palette Data)
        0xFF48 - OBP0 (Object Palette 0)
        0xFF49 - OBP1 (Object Palette 1)
        0xFF4A - WY   (Window Y Position)
        0xFF4B - WX   (Window X Position + 7)
    */
    logic [7:0]
        reg_LCDC,
        reg_STAT,
        reg_SCY,
        reg_SCX,
        reg_LY,
        reg_LYC
        ,\
        reg_DMA,
        reg_BGP,
        reg_OBP0,
        reg_OBP1,
        reg_WY,
        reg_WX;

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



endmodule : gb_ppu
