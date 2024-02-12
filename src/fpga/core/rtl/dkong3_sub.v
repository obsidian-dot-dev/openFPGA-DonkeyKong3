//----------------------------------------------------------------------------
// Donkey Kong 3 Arcade
//
// Author: gaz68 (https://github.com/gaz68) July 2020
//
// Sub CPU - Ricoh 2A03 (6502 + APU).
// Two of these are used.
// APU code taken from the NES_MiSTer project.
//----------------------------------------------------------------------------

module dkong3_sub
(
   input        I_SUBCLK,
   input        I_SUB_RESETn,
   input        I_SUB_NMIn,
   input   [7:0]I_SUB_DBI,
   input        I_CPU_CE,
   input        I_PHI2,
   input        I_ODD_OR_EVEN,

   output [15:0]O_SUB_ADDR,
   output  [7:0]O_SUB_DB0,
   output       O_SUB_RNW,

   output signed [15:0]O_SAMPLE
);


//-----
// CPU
//-----

wire [7:0] from_data_bus;
wire [7:0] cpu_dout;

wire [15:0] cpu_addr;
wire cpu_rnw;
//wire pause_cpu;
wire nmi;
wire mapper_irq;
wire apu_irq;

T65 cpu(
   .mode   (2'b00),
   .BCD_en (1'b0),

   .res_n  (I_SUB_RESETn),
   .clk    (I_SUBCLK),
   .enable (I_CPU_CE),
   //.rdy    (~pause_cpu),
   .rdy    (1'b1),

   .IRQ_n  (~apu_irq),
   .NMI_n  (I_SUB_NMIn),
   .R_W_n  (cpu_rnw),

   .A      (cpu_addr),
   .DI     (cpu_rnw ? W_CPU_DBUS : cpu_dout),
   .DO     (cpu_dout)
);

assign O_SUB_ADDR = cpu_addr;
assign O_SUB_DB0  = cpu_dout;
assign O_SUB_RNW  = cpu_rnw;

// CPU Data Bus (Data In)
wire   [7:0]W_CPU_DBUS = (cpu_addr == 16'h4015 & cpu_rnw) ? apu_dout : I_SUB_DBI;


//-----
// APU
//-----

wire apu_cs = cpu_addr >= 'h4000 && cpu_addr < 'h4018;
wire [7:0]apu_dout;
wire [15:0] sample_apu;

APU apu(
   .MMC5           (1'b0),
   .clk            (I_SUBCLK),
   .PHI2           (I_PHI2),
   .CS             (apu_cs),
   .PAL            (1'b0),
   .ce             (I_CPU_CE),
   .reset          (~I_SUB_RESETn),
   .cold_reset     (1'b0),
   .ADDR           (cpu_addr[4:0]),
   .RW             (cpu_rnw),
   .DIN            (cpu_dout),
   .DOUT           (apu_dout),
   .audio_channels (5'b11111),
   .Sample         (sample_apu),
   .DmaReq         (/*apu_dma_request*/), // TODO: DMA
   .DmaAck         (/*apu_dma_ack*/),
   .DmaAddr        (/*apu_dma_addr*/),
   .DmaData        (/*from_data_bus*/),
   .odd_or_even    (I_ODD_OR_EVEN),
   .IRQ            (apu_irq)
);

wire [15:0] sample_inverted = 16'hFFFF - sample_apu;

assign O_SAMPLE = {~sample_inverted[15],sample_inverted[14:0]};


endmodule
