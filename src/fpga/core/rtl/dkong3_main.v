//----------------------------------------------------------------------------
// Donkey Kong 3 Arcade
//
// Author: gaz68 (https://github.com/gaz68) July 2020
//
// Main CPU, ROM, RAM, address decoding, DMA and inputs.
//----------------------------------------------------------------------------

module dkong3_main
(
   input        I_CLK_24M,
   input        I_CLK_12M,
   input        I_MCPU_CLK,
   input        I_MCPU_RESETn,

   input        I_VRAMBUSY_n,
   input        I_VBLK_n,
   input   [7:0]I_SW1,
   input   [7:0]I_SW2,
   input   [7:0]I_DIP1,
   input   [7:0]I_DIP2,
   input   [7:0]I_VRAM_DB,

   input  [16:0]I_DLADDR,
   input   [7:0]I_DLDATA,
   input        I_DLWR,

   output [15:0]O_MCPU_A,
   output [7:0] WI_D,
   output       O_MCPU_RDn,
   output       O_MCPU_WRn,

   output  [9:0]O_DMAD_A,
   output  [7:0]O_DMAD_D,
   output       O_DMAD_CE,

   output       O_OBJ_RQn,
   output       O_OBJ_RDn,
   output       O_OBJ_WRn,
   output       O_VRAM_RDn,
   output       O_VRAM_WRn,
   output  [7:0]O_3E_Q,
   output  [3:0]O_4E_Q,
   output       O_SUB_RESETn
);

//-----------------------
// Main CPU - Z80 (4MHz)
//-----------------------

wire   W_MCPU_WAITn;
wire   W_MCPU_RFSHn;
wire   W_MCPU_M1n;
wire   W_MCPU_NMIn;
wire   W_MCPU_MREQn;
wire   W_MCPU_RDn;  
wire   W_MCPU_WRn;
wire   [15:0]W_MCPU_A;

// INPUT DATA BUS
wire   [7:0]ZDO, ZDI;
//wire   [7:0]WI_D = ZDI;
assign WI_D = ZDI;



Z80IP CPU
(
   .CLK2X(),
   .CLK(I_MCPU_CLK),
   .RESET_N(I_MCPU_RESETn),
   .INT_N(1'b1),
   .NMI_N(W_MCPU_NMIn),
   .ADRS(W_MCPU_A),
   .DOUT(ZDI),
   .DINP(ZDO),
   .M1_N(W_MCPU_M1n),
   .MREQ_N(W_MCPU_MREQn),
   .IORQ_N(),
   .RD_N(W_MCPU_RDn),
   .WR_N(W_MCPU_WRn),
   .WAIT_N(W_MCPU_WAITn),
   //.WAIT_N(1'b1),
   .BUSWO(),
   .RFSH_N(W_MCPU_RFSHn),
   .HALT_N()
);

assign O_MCPU_A    = W_MCPU_A;
assign O_MCPU_RDn  = W_MCPU_RDn;
assign O_MCPU_WRn  = W_MCPU_WRn;

// CPU Data Bus (Data In)
wire   [7:0]WO_D = W_MROM_DO | W_MRAM7F_DO | W_MRAM7H_DO | W_SW_DO | I_VRAM_DB;
assign ZDO = WO_D;

//------------------
// Address decoding
//------------------

wire  [3:0]W_MROM_CS_n;
wire  [1:0]W_MRAM_CS_n;
wire       W_OBJ_RQn;
wire       W_OBJ_RDn;
wire       W_OBJ_WRn;
wire       W_VRAM_RDn;
wire       W_VRAM_WRn;
wire       W_SW1_OEn;
wire       W_SW2_OEn;
wire       W_DIP1_OEn;
wire       W_DIP2_OEn;
wire  [7:0]W_3E_Q;
wire  [3:0]W_4E_Q;
wire       W_SUB_RESETn;

dkong3_adec adec
(
   .I_CLK12M(I_CLK_12M),
   .I_CLK(I_MCPU_CLK),
   .I_RESET_n(I_MCPU_RESETn),
   .I_AB(W_MCPU_A),
   .I_DB(WI_D),
   .I_MREQ_n(W_MCPU_MREQn),
   .I_RFSH_n(W_MCPU_RFSHn),
   .I_RD_n(W_MCPU_RDn),
   .I_WR_n(W_MCPU_WRn),
   .I_VRAMBUSY_n(I_VRAMBUSY_n),
   .I_VBLK_n(I_VBLK_n),
   .I_DLCLK(I_CLK_24M),
   .I_DLADDR(I_DLADDR),
   .I_DLDATA(I_DLDATA),
   .I_DLWR(I_DLWR),

   .O_WAIT_n(W_MCPU_WAITn),
   .O_NMI_n(W_MCPU_NMIn),
   
   .O_MROM_CSn(W_MROM_CS_n),
   .O_MRAM_CSn(W_MRAM_CS_n),

   .O_5A_G_n(/*W_5A_Gn*/),
   .O_OBJ_RQ_n(W_OBJ_RQn),
   .O_OBJ_RD_n(W_OBJ_RDn),
   .O_OBJ_WR_n(W_OBJ_WRn),
   .O_VRAM_RD_n(W_VRAM_RDn),
   .O_VRAM_WR_n(W_VRAM_WRn),
   .O_SW1_OE_n(W_SW1_OEn),
   .O_SW2_OE_n(W_SW2_OEn),
   .O_DIP1_OE_n(W_DIP1_OEn),
   .O_DIP2_OE_n(W_DIP2_OEn), 
   .O_3E_Q(W_3E_Q),
   .O_4E_Q(W_4E_Q),
   .O_SUB_RESETn(W_SUB_RESETn)
);

assign O_OBJ_RQn     = W_OBJ_RQn;
assign O_OBJ_RDn     = W_OBJ_RDn;
assign O_OBJ_WRn     = W_OBJ_WRn;
assign O_VRAM_RDn    = W_VRAM_RDn;
assign O_VRAM_WRn    = W_VRAM_WRn;
assign O_3E_Q        = W_3E_Q;
assign O_4E_Q        = W_4E_Q;
assign O_SUB_RESETn  = W_SUB_RESETn;

//----------
// Main ROM
//----------

wire  [7:0]W_MROM_DO;

MAIN_ROM mrom(I_CLK_12M, W_MCPU_A[12:0], W_MROM_CS_n, W_MCPU_RDn, W_MROM_DO, 
              I_CLK_24M, I_DLADDR, I_DLDATA, I_DLWR);

//-----------------------
// Main CPU RAM 7F (2KB)
//-----------------------

wire  [7:0]W_7F_DO;
reg   [7:0]W_MRAM7F_DO;

ram_2048_8 U_7F
(
   .I_CLK(~I_CLK_12M),
   .I_ADDR(W_MCPU_A[10:0]),
   .I_D(WI_D),
   .I_CE(~W_MRAM_CS_n[0]),
   .I_WE(~W_MCPU_WRn),
   .O_D(W_7F_DO)
);

always@(posedge I_CLK_12M)
begin
   W_MRAM7F_DO <= (W_MCPU_RDn == 1'b0 & W_MRAM_CS_n[0] == 1'b0) ? W_7F_DO : 8'b0;
end

//------------------------------------------
// Main CPU RAMs 7H (2KB)
// This is also read by the DMA controller.
//------------------------------------------

wire  [7:0]W_MRAM7H_DO;

ram_2048_8_8 U_7H
(
   // A Port
   .I_CLKA(~I_CLK_12M),
   .I_ADDRA(W_MCPU_A[10:0]),
   .I_DA(WI_D),
   .I_CEA(~W_MRAM_CS_n[1]),
   .I_OEA(~W_MCPU_RDn),
   .I_WEA(~W_MCPU_WRn),
   .O_DA(W_MRAM7H_DO),

   // B Port - DMA port (read-only)
   .I_CLKB(I_CLK_12M),
   .I_ADDRB(W_DMAS_A),
   .I_DB(8'h00),
   .I_CEB(W_DMAS_CE),
   .I_OEB(1'b1),
   .I_WEB(1'b0),
   .O_DB(W_DMAS_D)
);

//------------------------------------------
// Sprite DMA
// transfers $19F bytes from $6900 to $7000
//------------------------------------------

wire  [9:0]W_DMAS_A;
wire  [7:0]W_DMAS_D;
wire       W_DMAS_CE;
wire  [9:0]W_DMAD_A;
wire  [7:0]W_DMAD_D;
wire       W_DMAD_CE;

dkong3_dma sprite_dma
(
   .I_CLK(~I_MCPU_CLK),
   .I_DMA_TRIG(W_3E_Q[5]),
   .I_DMA_DS(W_DMAS_D),

   .O_DMA_AS(W_DMAS_A),
   .O_DMA_CES(W_DMAS_CE),
   .O_DMA_AD(W_DMAD_A),
   .O_DMA_DD(W_DMAD_D),
   .O_DMA_CED(W_DMAD_CE)
);

assign O_DMAD_A  = W_DMAD_A;
assign O_DMAD_D  = W_DMAD_D;
assign O_DMAD_CE = W_DMAD_CE;

//---------------------------
// Inputs
// Controls and dip switches
//---------------------------

wire [7:0]W_SW_DO;

dkong3_input inputs
(
	.clk(I_CLK_12M),
   .I_SW1(I_SW1),
   .I_SW2(I_SW2),
   .I_DIP1(I_DIP1),
   .I_DIP2(I_DIP2),
   .I_SW1_OE_n(W_SW1_OEn),
   .I_SW2_OE_n(W_SW2_OEn),
   .I_DIP1_OE_n(W_DIP1_OEn),
   .I_DIP2_OE_n(W_DIP2_OEn),

   .O_D(W_SW_DO)
);


endmodule
