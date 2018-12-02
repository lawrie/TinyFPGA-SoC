/*
 * Simple Wishbone compliant ROM module.
 */
module wb_rom #(
    parameter WB_DATA_WIDTH = 8,
    parameter WB_ADDR_WIDTH = 9,
    parameter ROM_DEPTH = 512
) (
    // wishbone interface
    input                           clk_i,
    input                           rst_i,

    input                           stb_i,
    input                           we_i,
    input [WB_ADDR_WIDTH-1:0]       adr_i,
    input [WB_DATA_WIDTH-1:0]       dat_i,

    output reg                      ack_o,
    output reg [WB_DATA_WIDTH-1:0]  dat_o
);
    reg [WB_DATA_WIDTH-1:0] rom [ROM_DEPTH-1:0];

    wire valid_cmd = !rst_i && stb_i;
    wire valid_read_cmd = valid_cmd && !we_i;

    initial begin
        rom[0] <= 8'ha9; // LDA #$FF
        rom[1] <= 8'hff;
        rom[2] <= 8'h8d; // STA $0004 
        rom[3] <= 8'h04;
        rom[4] <= 8'h00;
        rom[5] <= 8'ha9; // lda #$01
        rom[6] <= 8'h01;
        rom[7] <= 8'hee; // LOOP: INC $0004 
        rom[8] <= 8'h04;
        rom[9] <= 8'h00;
        rom[10] <= 8'h4c; // JMP $07FE LOOP
        rom[11] <= 8'h07;
        rom[12] <= 8'hf0;

        rom[12'hffc] <= 8'h00; // Reset vector: F000
        rom[12'hffd] <= 8'hf0;
    end

    always @(posedge clk_i) begin
        if (valid_read_cmd) begin
            dat_o <= rom[adr_i];
        end

        ack_o <= valid_cmd;
    end
endmodule
