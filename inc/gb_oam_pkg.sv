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


    // HELPER FUNCTIONS {{{

    // Determine if an object lands on a scanline
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


    // TODO: is this synthesizable? does SV add intermediate values
    // or cascade logic correctly?
    //
    // Detect 'best' object match for a specific index
    // Reads the obj_buffer (up to 10 object matches per scanline)
    // based on the current x index, returns an object that:
    //  - intersects the tile (any of the 8 pixels)
    //  - is a valid object (isValid=1)
    //
    // priority is determined as follows:
    //  - lowest x_position
    //  - if same x_position, lowest index in the obj_buffer
    //
    // Recall that oam objects store x_position+8
    function automatic logic [3:0] objectBufferSearch(obj_buffer_t [9:0] obj_buffer, logic [7:0] X);
        // Return index of best matching object
        logic [3:0] bestIndex;

        // Store the smallest x-position of all matching objects
        logic [7:0] bestObjX;

        // Set defaults before searching, out of range index indicates no match
        bestIndex = 4'hF;
        bestObjX  = 8'hFF;

        // Iterate object buffer elements to find the best match
        for (integer i = 0; i < 10; i++) begin
            if (obj_buffer[i].isValid) begin
                // store a local diff for this object
                logic [7:0] xDiff;
                // find the absolute difference from the input x position
                if (obj_buffer[i].object.x_position > X) xDiff = obj_buffer[i].object.x_position - X;
                else xDiff = X - obj_buffer[i].object.x_position;

                // Only consider objects that land in current tile
                if (xDiff < 8'd8) begin
                    // update best values if possible
                    if ((bestIndex == 4'hF) || (obj_buffer[i].object.x_position < bestObjX)) begin
                        bestIndex = i[3:0];
                        bestObjX  = obj_buffer[i].object.x_position;
                    end
                end
            end
        end

        // Return the best matching index
        return bestIndex;

    endfunction : objectBufferSearch

    // }}}

endpackage : gb_oam_pkg
