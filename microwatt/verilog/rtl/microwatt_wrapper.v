`default_nettype none

module microwatt_wrapper (
`ifdef USE_POWER_PINS
    inout vccd1,
    inout vssd1,
`endif
    
    input clk,
    input rst,
    
    // Instruction bus - simplified names
    output [31:0] insn_adr,
    output insn_cyc,
    output insn_stb,
    output [7:0] insn_sel,
    output insn_we,
    output [63:0] insn_dat_o,
    input [63:0] insn_dat_i,
    input insn_ack,
    input insn_stall,
    
    // Data bus - simplified names
    output [31:0] data_adr,
    output [63:0] data_dat_o,
    output [7:0] data_sel,
    output data_cyc,
    output data_stb,
    output data_we,
    input [63:0] data_dat_i,
    input data_ack,
    input data_stall,
    
    // Debug
    input [3:0] dmi_addr,
    input [63:0] dmi_din,
    input dmi_req,
    input dmi_wr,
    output [63:0] dmi_dout,
    output dmi_ack,
    
    // Interrupt
    input ext_irq
);

    // Internal signals
    wire alt_reset;
    wire terminated_out;
    
    // Tie off unused signals
    assign alt_reset = 1'b0;
    
    // Snoop bus signals (tie off if not used)
    wire [63:0] wb_snoop_adr;
    wire [63:0] wb_snoop_dat;
    wire [7:0] wb_snoop_sel;
    wire wb_snoop_cyc;
    wire wb_snoop_stb;
    wire wb_snoop_we;
    
    assign wb_snoop_adr = 64'b0;
    assign wb_snoop_dat = 64'b0;
    assign wb_snoop_sel = 8'b0;
    assign wb_snoop_cyc = 1'b0;
    assign wb_snoop_stb = 1'b0;
    assign wb_snoop_we = 1'b0;

    // Instantiate core module with ESCAPED port names
    core u_cpu_core (
        `ifdef USE_POWER_PINS
        .vccd1(vccd1),
        .vssd1(vssd1),
        `endif
        
        .clk(clk),
        .rst(rst),
        .alt_reset(alt_reset),
        
        // Instruction Wishbone IN (from memory to CPU)
        .\wishbone_insn_in.dat (insn_dat_i),
        .\wishbone_insn_in.ack (insn_ack),
        .\wishbone_insn_in.stall (insn_stall),
        
        // Instruction Wishbone OUT (from CPU to memory)
        .\wishbone_insn_out.adr (insn_adr),
        .\wishbone_insn_out.dat (insn_dat_o),
        .\wishbone_insn_out.sel (insn_sel),
        .\wishbone_insn_out.cyc (insn_cyc),
        .\wishbone_insn_out.stb (insn_stb),
        .\wishbone_insn_out.we (insn_we),
        
        // Data Wishbone IN (from memory to CPU)
        .\wishbone_data_in.dat (data_dat_i),
        .\wishbone_data_in.ack (data_ack),
        .\wishbone_data_in.stall (data_stall),
        
        // Data Wishbone OUT (from CPU to memory)
        .\wishbone_data_out.adr (data_adr),
        .\wishbone_data_out.dat (data_dat_o),
        .\wishbone_data_out.sel (data_sel),
        .\wishbone_data_out.cyc (data_cyc),
        .\wishbone_data_out.stb (data_stb),
        .\wishbone_data_out.we (data_we),
        
        // Snoop bus (tie off)
        .\wb_snoop_in.adr (wb_snoop_adr),
        .\wb_snoop_in.dat (wb_snoop_dat),
        .\wb_snoop_in.sel (wb_snoop_sel),
        .\wb_snoop_in.cyc (wb_snoop_cyc),
        .\wb_snoop_in.stb (wb_snoop_stb),
        .\wb_snoop_in.we (wb_snoop_we),
        
        // Debug
        .dmi_addr(dmi_addr),
        .dmi_din(dmi_din),
        .dmi_req(dmi_req),
        .dmi_wr(dmi_wr),
        .dmi_dout(dmi_dout),
        .dmi_ack(dmi_ack),
        
        // Interrupt
        .ext_irq(ext_irq),
        
        // Terminated output
        .terminated_out(terminated_out)
    );

endmodule

`default_nettype wire

