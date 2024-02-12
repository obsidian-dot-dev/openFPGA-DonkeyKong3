//----------------------------------------------------------------------------
// Donkey Kong 3 Arcade
//
// Author: gaz68 (https://github.com/gaz68) July 2020
//
// Colour palette.
// Based on the Donkey Kong version by Katsumi Degawa.
//----------------------------------------------------------------------------

module dkong3_col_pal
(
   input        I_CLK_24M,
   input        I_CLK_6M,
   input   [5:0]I_VRAM_D,
   input   [5:0]I_OBJ_D,
   input        I_CMPBLKn,
   input   [1:0]I_CPAL_SEL,
   input        I_DLCLK,
   input  [17:0]I_DLADDR,
   input   [7:0]I_DLDATA,
   input        I_DLWR,

   output  [3:0]O_R,
   output  [3:0]O_G,
   output  [3:0]O_B
);

// Link CL1 on the schematics
// Uncut = 0 - Inverted colour palette
// Cut   = 1 - Standard colour palette
parameter CL1 = 1'b1;

//-------------------------------------
// Parts 3M, 3L (74LS157)
// Selects sprites or backgound pixels
// Sprites take priority
//-------------------------------------

wire   [5:0]W_3ML_Y = (~(I_OBJ_D[0]|I_OBJ_D[1])) ? I_VRAM_D: I_OBJ_D;

//--------------
// Parts 1B, 2C
//--------------

wire   [8:0]W_1B2C_D = {I_CPAL_SEL,W_3ML_Y[5:0],I_CMPBLKn};
reg    [8:0]W_1B2C_Q;
wire   W_1B2C_RST  =  I_CMPBLKn | W_1B2C_Q[0];

always@(posedge I_CLK_6M or negedge W_1B2C_RST)
begin
   if(W_1B2C_RST == 1'b0)
      W_1B2C_Q <= 1'b0;
   else
      W_1B2C_Q <= W_1B2C_D;
end

//--------------------------------------------------------------
// Colour PROM's 1D (512 x 8bit) and 1C (512 x 4bit)
// The PROM actually contains 2 versions of the colour palette:
//      0 - 255 = Inverted palette
//    256 - 512 = Standard palette
// Link CL1 on the PCB is used for selecting the palette.
//--------------------------------------------------------------

wire   [8:0]W_PAL_AB = {CL1,W_1B2C_Q[8:1]};
wire   [7:0]W_1D_DO;
wire   [3:0]W_1C_DO;

CLUT_PROM_512_8 prom1d(I_CLK_24M, W_PAL_AB, W_1D_DO,
                       I_DLCLK, I_DLADDR, I_DLDATA, I_DLWR);

CLUT_PROM_512_4 prom1c(I_CLK_24M, W_PAL_AB, W_1C_DO,
                       I_DLCLK, I_DLADDR, I_DLDATA, I_DLWR);

assign {O_R, O_G, O_B} = {W_1D_DO,W_1C_DO};

endmodule

