`timescale 1ns / 1ps

module addressDecoderTop(
    input clk,
    input rst,
    input [15:0] switches,       // Control, locker address, and data input
    output [15:0] leds,          // Physical LEDs display
    output [6:0] seg,            // 7-segment display segments
    output [3:0] an              // 7-segment display anodes
    );

    // Updated Switch Mapping:
    // sw[1:0]  = 01: Read from selected memory locker
    // sw[1:0]  = 10: Write to selected memory locker
    // sw[5:2]  = Locker / Memory Address Selector (4 bits -> Lockers 0 to 15)
    // sw[15:6] = Data to write into the selected locker (10 bits)

    wire [1:0] control     = switches[1:0];
    wire [3:0] locker_addr = switches[5:2];
    wire [9:0] dataIn      = switches[15:6];

    reg [31:0] address;
    reg readEnable, writeEnable;
    wire [31:0] writeData;
    wire [31:0] readData;
    wire [15:0] leds_decoder;

    // Assign write data (pad 10-bit input to 32 bits)
    assign writeData = {22'b0, dataIn};

    // Control logic based on switch input
    always @(*) begin
        // Default: Point to selected locker in Data Memory (address[9:8] = 00)
        // Note: If your RAM is word-aligned (uses address[7:2]), change this to:
        // address = {26'b0, locker_addr, 2'b00};
        address = {28'b0, locker_addr};
        readEnable = 1'b0;
        writeEnable = 1'b0;

        case(control)
            2'b01: begin  // Read from selected memory locker
                address = {28'b0, locker_addr};
                readEnable = 1'b1;
                writeEnable = 1'b0;
            end
            
            2'b10: begin  // Write to selected memory locker
                address = {28'b0, locker_addr};
                readEnable = 1'b0;
                writeEnable = 1'b1;
            end
            
            default: begin
                address = {28'b0, locker_addr};
                readEnable = 1'b0;
                writeEnable = 1'b0;
            end
        endcase
    end

    // Instantiate the Address Decoder
    AddressDecoder DUT (
        .clk(clk),
        .rst(rst),
        .address(address),
        .readEnable(readEnable),
        .writeEnable(writeEnable),
        .writeData(writeData),
        .switches_in(switches),
        .readData(readData),
        .leds_out(leds_decoder)
    );

    // Route output to physical LEDs when reading from memory
    // Otherwise, show whatever was last written to LED address
    assign leds = (control == 2'b01) ? readData[15:0] : leds_decoder;

    // Instantiate the 7-Segment Display Controller
    // Display lower 16 bits of readData (memory read results)
    sevenseg_basys3 Display (
        .clk(clk),
        .rst(rst),
        .value(readData[15:0]),
        .seg(seg),
        .an(an)
    );

endmodule