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
        oam_obj_t object;
        logic     isValid;
    } obj_buffer_t;

    // Detect if an object lands on a scanline
    function automatic logic objectOnScanline(logic [7:0] obj_y_pos, logic [7:0] Y, logic obj_size);
        // sprite y-pos value is offset by 16 from the viewport
        // A y-val of 0 is offscreen,
        // but a y-val of 1 would be onscreen if the sprite is in 8x16 mode,
        // and a y-val of 9 is onscreen in 8x8 or 8x16 mode

        if (obj_size) begin
            // 8x16 Mode
            if ((obj_y_pos == 8'd0) || (obj_y_pos >= 8'd160)) return 1'b0;
            else if ( ({obj_y_pos[7:3], 3'b000} == {Y[7:3], 3'b000}) || ({(obj_y_pos[7:3] + 5'd1), 3'b000} == {Y[7:3], 3'b000}) )
                return 1'b1;
            else return 1'b0;
        end else begin
            // 8x8 Mode
            if ((obj_y_pos <= 8'd8) || (obj_y_pos >= 8'd160)) return 1'b0;
            if ({obj_y_pos[7:3], 3'b000} == {Y[7:3], 3'b000}) return 1'b1;
            else return 1'b0;
        end

    endfunction : objectOnScanline

endpackage : gb_oam_pkg
