package gb_ppu_common_pkg;

    // PPU Rendering Modes
    typedef enum logic [1:0] {
        OAM_SCAN   = 2'b10,
        DRAW_PIXEL = 2'b11,
        HBLANK     = 2'b00,
        VBLANK     = 2'b01
    } ppu_mode_state_t;

    // FIFO Pixel Fetcher States
    typedef enum logic [2:0] {
        GET_TILE,
        GET_TILE_DATA_LOW,
        GET_TILE_DATA_HIGH,
        SLEEP,
        PUSH
    } fifo_pixel_fetcher_state_t;

    // Enumerated Pixel Colors
    typedef enum logic [1:0] {
        WHITE      = 2'b00,
        LIGHT_GREY = 2'b01,
        DARK_GREY  = 2'b10,
        BLACK      = 2'b11
    } pixel_color_t;


    // Each Pixel in the FIFO contains these properties
    typedef struct packed {
        logic [1:0] color_index;  // Palette ID
        logic       obj_palette;
        logic       bg_priority;
    } fifo_pixel_t;


    // PPU REGISTER ABSTRACTIONS {{{

    // LCDC Register Signals
    typedef struct packed {
        logic lcd_ppu_enable;          // 0: OFF          1: ON
        logic win_tile_map;            // 0: 9800-9BFF    1: 9C00-9FFF
        logic win_enable;              // 0: OFF          1: ON
        logic bg_win_tiles;            // 0: 8800-97FF    1: 8000-87FF
        logic bg_tile_map;             // 0: 9800-9BFF    1: 9C00-9FFF
        logic obj_size;                // 0: 8x8          1: 8x16
        logic obj_enable;              // 0: OFF          1: ON
        logic bg_win_enable_priority;  // 0: OFF          1: ON
    } lcd_control_t;

    // STAT Register Signals
    typedef struct packed {
        logic            lyc_irq_cond;     // LY==LYC    STAT interrupt request
        logic            mode_2_irq_cond;  // PPU Mode 2 STAT interrupt request
        logic            mode_1_irq_cond;  // PPU Mode 1 STAT interrupt request
        logic            mode_0_irq_cond;  // PPU Mode 0 STAT interrupt request
        logic            lyc_ly_compare;   // LY == LYC
        ppu_mode_state_t ppu_mode;         // PPU Mode
    } lcd_status_t;

    // Palette Registers
    typedef struct packed {
        pixel_color_t id_0;
        pixel_color_t id_1;
        pixel_color_t id_2;
        pixel_color_t id_3;
    } palette_register_t;

    // }}}

endpackage : gb_ppu_common_pkg
