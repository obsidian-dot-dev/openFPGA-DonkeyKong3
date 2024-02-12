//----------------------------------------------------------------------------
// Donkey Kong 3 Arcade
//
// Author: gaz68 (https://github.com/gaz68) July 2020
//
// Top level video module.
//----------------------------------------------------------------------------

module dkong3_video
(
   input        I_CLK_24M,
   input        I_CLK_12M,
   input        I_RESETn,
   input   [9:0]I_CPU_A,
   input   [7:0]I_CPU_D,
   input        I_VRAM_WRn,
   input        I_VRAM_RDn,
   input   [7:0]I_3E_Q,
   input   [9:0]I_H_CNT,
   input   [7:0]I_VF_CNT,
   input        I_CBLANKn, 
   input   [9:0]I_OBJDMA_A,
   input   [7:0]I_OBJDMA_D,
   input        I_OBJDMA_CE,
   input  [17:0]I_DLADDR,
   input   [7:0]I_DLDATA,
   input        I_DLWR,
   input        flip_screen,

   output  [7:0]O_VRAM_DB,
   output       O_VRAMBUSYn,
   output       O_FLIP_HV,
   output  [7:0]O_OBJ_DB,
   output  [3:0]O_VGA_RED,
   output  [3:0]O_VGA_GRN,
   output  [3:0]O_VGA_BLU
);

//------------------
// VRAM
// Background tiles
//------------------

wire   [3:0]W_VRAM_COL;
wire   [1:0]W_VRAM_VID;
wire   [7:0]W_VRAM_DB;
wire        W_VRAMBUSYn;

dkong3_vram vram
(
   .I_CLK_24M(I_CLK_24M),
   .I_CLK_12M(~I_CLK_12M),
   .I_AB(I_CPU_A),
   .I_DB(I_CPU_D),
   .I_VRAM_WRn(I_VRAM_WRn),
   .I_VRAM_RDn(I_VRAM_RDn),
   .I_FLIP(W_FLIP_VRAM),
   .I_H_CNT(I_H_CNT),
   .I_VF_CNT(I_VF_CNT),
   .I_CMPBLK(I_CBLANKn),
   .I_GFXBANK(~I_3E_Q[1]),
   .I_DLCLK(I_CLK_24M),
   .I_DLADDR(I_DLADDR),
   .I_DLDATA(I_DLDATA),
   .I_DLWR(I_DLWR),

   .O_DB(W_VRAM_DB),
   .O_COL(W_VRAM_COL),
   .O_VID(W_VRAM_VID),
   .O_VRAMBUSYn(W_VRAMBUSYn), 
   .O_ESBLKn() // Not used
);

wire   [5:0]W_VRAM_DAT = {W_VRAM_COL[3:0],W_VRAM_VID[1:0]};

assign O_VRAM_DB   = W_VRAM_DB;
assign O_VRAMBUSYn = W_VRAMBUSYn;

//-------------------
// Objects / Sprites
//-------------------

wire  [5:0]W_OBJ_DAT;
wire       W_FLIP_VRAM;
wire       W_FLIP_HV;
wire       W_FLIPn = I_3E_Q[2];
wire       W_2PSL  = I_3E_Q[3];
wire       W_L_CMPBLKn;
wire  [7:0]W_OBJ_DB;

dkong3_obj sprites
(
   .I_CLK_24M(I_CLK_24M),
   .I_CLK_12M(I_CLK_12M),
   .I_AB(),            // not used
   .I_DB(/*W_2N_DO*/), // not used
   .I_OBJ_WRn(1'b1),   // not used
   .I_OBJ_RDn(1'b1),   // not used
   .I_OBJ_RQn(1'b1),   // not used
   .I_2PSL(W_2PSL),
   .I_FLIPn(W_FLIPn),
   .I_CMPBLKn(I_CBLANKn),
   .I_H_CNT(I_H_CNT),
   .I_VF_CNT(I_VF_CNT),
   .I_OBJ_DMA_A(I_OBJDMA_A),
   .I_OBJ_DMA_D(I_OBJDMA_D),
   .I_OBJ_DMA_CE(I_OBJDMA_CE),
   .I_DLADDR(I_DLADDR),
   .I_DLDATA(I_DLDATA),
   .I_DLWR(I_DLWR),
   .flip_screen(flip_screen),

   .O_DB(W_OBJ_DB), // not used
   .O_OBJ_DO(W_OBJ_DAT),
   .O_FLIP_VRAM(W_FLIP_VRAM),
   .O_FLIP_HV(W_FLIP_HV),
   .O_L_CMPBLKn(W_L_CMPBLKn)
);

assign O_OBJ_DB  = W_OBJ_DB;
assign O_FLIP_HV = W_FLIP_HV;

//----------------
// Colour Palette
//----------------

wire   [3:0]W_R;
wire   [3:0]W_G;
wire   [3:0]W_B;

dkong3_col_pal cpal
(
   .I_CLK_24M(I_CLK_24M),
   .I_CLK_6M(I_H_CNT[0]),
   .I_VRAM_D(W_VRAM_DAT),
   .I_OBJ_D(W_OBJ_DAT),
   .I_CMPBLKn(W_L_CMPBLKn),
   .I_CPAL_SEL(I_3E_Q[7:6]),
   .I_DLCLK(I_CLK_24M),
   .I_DLADDR(I_DLADDR),
   .I_DLDATA(I_DLDATA),
   .I_DLWR(I_DLWR),

   .O_R(W_R),
   .O_G(W_G),
   .O_B(W_B)
);

assign O_VGA_RED = W_R;
assign O_VGA_GRN = W_G;
assign O_VGA_BLU = W_B;

endmodule
