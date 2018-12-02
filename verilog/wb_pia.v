/*
 * Simple Wishbone compliant Atari 2600 PIA module.
 */
module wb_pia (
    // wishbone interface
    input                           clk_i,
    input                           rst_i,

    input                           stb_i,
    input                           we_i,
    input [6:0]                     adr_i,
    input [7:0]                     dat_i,

    output reg                      ack_o,
    output reg [7:0]                dat_o,
    input [7:0]                     buttons
);

    wire valid_cmd = !rst_i && stb_i;
    wire valid_write_cmd = valid_cmd && we_i;
    wire valid_read_cmd = valid_cmd && !we_i;

    reg [7:0] timer_64;
    reg [23:0] time_counter;
    wire [7:0]  reset_timer;

    always @(posedge clk_i) begin
        reset_timer <= 0;

        if (valid_read_cmd) begin
          case (adr_i) 
          'h00: dat_o <= buttons; // SWCHA
          'h01: ; // SWACNT
          'h02: ; // SWCHB
          'h03: ; // SWBCNT
          'h04: dat_o <= timer_64; // INTIM
          endcase
        end

        if (valid_write_cmd) begin
          case (adr_i)
          'h14: ; // TIM1T
          'h15: ; // TIM8T
          'h16: reset_timer <= dat_i; // TIM64T
          'h17: ; // T1024T
          endcase
        end

        ack_o <= valid_cmd;
    end

    always @(posedge clk_i) begin
      if (reset_timer > 0) begin
        time_counter <= 0;
        timer_64 <= reset_timer;
      end else time_counter <= time_counter + 1;

      if (&time_counter[9:0]) begin
        if (timer_64 != 0) timer_64 <= timer_64 - 1;
      end

    end
   
endmodule
