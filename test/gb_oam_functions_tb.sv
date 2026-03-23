// Test the OAM_SCAN functions of the PPU
module gb_oam_functions_tb ();

    import gb_ppu_common_pkg::*;
    import gb_oam_pkg::*;


    // object buffer
    obj_buffer_t [9:0] obj_buffer;

    function automatic logic [7:0] rand8();
        logic [31:0] tmp;
        tmp = $urandom();
        return tmp[7:0];
    endfunction : rand8

    function automatic void testOnScanline(logic [7:0] obj_y_pos, logic [7:0] Y, logic obj_size);
        $display("An %s Object with Y=%d %s intersect scanline Y=%d", obj_size ? "8x16" : "8x8", obj_y_pos,
                 objectOnScanline(obj_y_pos, Y, obj_size) ? "DOES" : "DOES NOT", Y);
    endfunction : testOnScanline


    logic [7:0] tmp;

    initial begin
        $display("Starting OAM function test");

        repeat (50) testOnScanline(rand8(), rand8(), 1'b0);
        repeat (50) testOnScanline(rand8(), rand8(), 1'b1);

        $display("\nInvalidating object buffer");
        for (int i = 0; i < 10; i++) obj_buffer[i].isValid = 1'b0;

        $display("Make sure invalid objects are not selected");
        repeat (5) begin
            tmp = rand8();
            $display("Best object match for X=%d found at index %d", tmp, objectBufferSearch(obj_buffer, tmp));
        end

        $display("Object 0 is valid at x=0, should be offscreen");
        obj_buffer[0].object.x_position = 8'd0;
        obj_buffer[0].isValid           = 1'b1;
        $display("Best object match for X=%d found at index %d", 8'd0, objectBufferSearch(obj_buffer, 8'd0));


        $display("Object 1 is valid at x=4, this is onscreen");
        obj_buffer[1].object.x_position = 8'd4;
        obj_buffer[1].isValid           = 1'b1;
        $display("Best object match for X=%d found at index %d", 8'd0, objectBufferSearch(obj_buffer, 8'd0));


        $display("Object 8 mirrors object 2, but has a worse index");
        obj_buffer[8].object.x_position = 8'd1;
        obj_buffer[8].isValid           = 1'b1;
        $display("Best object match for X=%d found at index %d", 8'd0, objectBufferSearch(obj_buffer, 8'd0));

        $display("Object 2 is valid at x=1, this is onscreen and better");
        obj_buffer[2].object.x_position = 8'd1;
        obj_buffer[2].isValid           = 1'b1;
        $display("Best object match for X=%d found at index %d", 8'd0, objectBufferSearch(obj_buffer, 8'd0));






        $finish();
    end

endmodule : gb_oam_functions_tb
