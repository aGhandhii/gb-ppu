package gb_oam_pkg;

    // OAM Object Properties
    typedef struct packed {
        logic [7:0] y_position;
        logic [7:0] x_position;
        logic [7:0] tile_index;
        logic       obj_priority;
        logic       y_flip;
        logic       x_flip;
        logic       dmg_palette;
    } oam_obj_t;

    // Object Buffer data type for the PPU
    // Used to hold objects to render in a frame
    typedef struct packed {
        oam_obj_t obj_buffer;
        logic     isValid;
    } obj_buffer_t;

endpackage : gb_oam_pkg
