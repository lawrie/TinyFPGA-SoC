module mcu (
    input clock,

    output reg [7:0] leds,
    output usbpu,
    output led
);

    // Show data fetched on leds 
    assign leds = cpu_dat_i;
    assign led = 1;

    // Disable USB
    assign usbpu = 0;

    // Generate reset
    wire reset = !(&reset_counter);
    reg [14:0] reset_counter = 0;

    always @(posedge clock) begin
      if (reset) reset_counter <= reset_counter + 1;
    end

    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    ///
    /// Arlet 6502 Core
    ///
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    // 6502 cpu interface
    wire [15:0] address_bus; 
    wire [7:0] read_bus;    
    wire [7:0] write_bus;  
    wire write_enable;    
    wire irq = 1'b0;            
    wire nmi = 1'b0;           
    reg ready;        

    cpu cpu_inst (
        .clk(clock),
        .reset(reset),
        .AB(address_bus),
        .DI(read_bus),
        .DO(write_bus),
        .WE(write_enable),
        .IRQ(irq),
        .NMI(nmi),
        .RDY(ready)
    );

    // 6502 wishbone interface
    wire cpu_stb_o;
    reg cpu_we_o;
    reg [15:0] cpu_adr_o;
    reg [7:0] cpu_dat_o;
    wire cpu_ack_i;
    wire [7:0] cpu_dat_i;
    
    wb_6502_bridge wb_6502_bridge_inst (
        .clk_i(clock),
        .rst_i(reset),
        .stb_o(cpu_stb_o),
        .we_o(cpu_we_o),
        .adr_o(cpu_adr_o),
        .dat_o(cpu_dat_o),
        .ack_i(cpu_ack_i),
        .dat_i(cpu_dat_i),
        .address_bus(address_bus),
        .read_bus(read_bus),
        .write_bus(write_bus),
        .write_enable(write_enable),
        .ready(ready)
    );

    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    ///
    /// RAM
    ///
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    wire ram_stb_i;
    wire ram_we_i;
    wire [15:0] ram_adr_i;
    wire [7:0] ram_dat_i;
    wire ram_ack_o;
    wire [7:0] ram_dat_o;

    wb_ram #(
        .WB_DATA_WIDTH(8),
        .WB_ADDR_WIDTH(9),
        .WB_ALWAYS_READ(0),
        .RAM_DEPTH(512)
    ) main_ram (
        .clk_i(clock),
        .rst_i(reset),
        .stb_i(ram_stb_i),
        .we_i(ram_we_i),
        .adr_i(ram_adr_i[8:0]),
        .dat_i(ram_dat_i),
        .ack_o(ram_ack_o),
        .dat_o(ram_dat_o)
    );

    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    ///
    /// ROM
    ///
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    wire rom_stb_i;
    wire rom_we_i;
    wire [15:0] rom_adr_i;
    wire [7:0] rom_dat_i;
    wire rom_ack_o;
    wire [7:0] rom_dat_o;

    wb_rom #(
        .WB_DATA_WIDTH(8),
        .WB_ADDR_WIDTH(12),
        .ROM_DEPTH(4096)
    ) main_rom (
        .clk_i(clock),
        .rst_i(reset),
        .stb_i(rom_stb_i),
        .we_i(rom_we_i),
        .adr_i(rom_adr_i[11:0]),
        .dat_i(rom_dat_i),
        .ack_o(rom_ack_o),
        .dat_o(rom_dat_o)
    );

    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    ///
    /// Wishbone Bus
    ///
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    wb_bus #(
        .WB_DATA_WIDTH(8),
        .WB_ADDR_WIDTH(16),
        .WB_NUM_SLAVES(2)
    ) bus (
        // syscon
        .clk_i(clock),
        .rst_i(reset),

        // connection to wishbone master
        .mstr_stb_i(cpu_stb_o),
        .mstr_we_i(cpu_we_o),
        .mstr_adr_i(cpu_adr_o),
        .mstr_dat_i(cpu_dat_o),
        .mstr_ack_o(cpu_ack_i),
        .mstr_dat_o(cpu_dat_i),

        // wishbone slave decode         RAM         ROM 
        .bus_slv_addr_decode_value({16'h0000,   16'hF000}),
        .bus_slv_addr_decode_mask ({16'hF000,   16'hF000}),

        // connection to wishbone slaves
        .slv_stb_o                ({ram_stb_i,  rom_stb_i}),
        .slv_we_o                 ({ram_we_i,   rom_we_i}),
        .slv_adr_o                ({ram_adr_i,  rom_adr_i}),
        .slv_dat_o                ({ram_dat_i,  rom_dat_i}),
        .slv_ack_i                ({ram_ack_o,  rom_ack_o}),
        .slv_dat_i                ({ram_dat_o,  rom_dat_o})
    );
endmodule
