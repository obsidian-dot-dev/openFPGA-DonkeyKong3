//----------------------------------------------------------------------------
// Donkey Kong 3 Arcade
//
// Author: gaz68 (https://github.com/gaz68) July 2020
//
// Video RAM (background tiles)
// Based on the Donkey Kong version by Katsumi Degawa.
//----------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------
// H_CNT[0],H_CNT[1],H_CNT[2],H_CNT[3],H_CNT[4],H_CNT[5],H_CNT[6],H_CNT[7],H_CNT[8],H_CNT[9]  
//   1/2 H     1 H     2 H      4H       8H       16 H     32H      64 H     128 H   256 H
//-----------------------------------------------------------------------------------------
// V_CNT[0], V_CNT[1], V_CNT[2], V_CNT[3], V_CNT[4], V_CNT[5], V_CNT[6], V_CNT[7]  
//    1 V      2 V       4 V       8 V       16 V      32 V      64 V     128 V 
//-----------------------------------------------------------------------------------------
// VF_CNT[0],VF_CNT[1],VF_CNT[2],VF_CNT[3],VF_CNT[4],VF_CNT[5],VF_CNT[6],VF_CNT[7]  
//    1 VF     2 VF      4 VF      8 VF      16 VF     32 VF     64 VF    128 VF 
//-----------------------------------------------------------------------------------------

module dkong3_vram(

   input        I_CLK_24M,
   input        I_CLK_12M,
   input   [9:0]I_AB,
   input   [7:0]I_DB,
   input        I_VRAM_WRn,
   input        I_VRAM_RDn,
   input        I_FLIP,
   input   [9:0]I_H_CNT,
   input   [7:0]I_VF_CNT,
   input        I_CMPBLK,
   input        I_GFXBANK,
   input        I_DLCLK,
   input  [17:0]I_DLADDR,
   input   [7:0]I_DLDATA,
   input        I_DLWR,

   output     [7:0]O_DB,
   output reg [3:0]O_COL,
   output     [1:0]O_VID,
   output          O_VRAMBUSYn,
   output          O_ESBLKn
);

//-------------------------
// VRAM
// 2 x 2114 @ 2P, 2R (1KB)
//-------------------------

wire   [7:0]WI_DB = I_VRAM_WRn ? 8'h00: I_DB;
wire   [7:0]WO_DB;

assign O_DB       = I_VRAM_RDn ? 8'h00: WO_DB;

wire   [4:0]W_HF_CNT  = I_H_CNT[8:4]^{5{I_FLIP}};
wire   [9:0]W_cnt_AB  = {I_VF_CNT[7:3],W_HF_CNT[4:0]};
wire   [9:0]W_vram_AB = I_CMPBLK ? W_cnt_AB : I_AB ;
wire        W_vram_CS = I_CMPBLK ? 1'b0     : I_VRAM_WRn & I_VRAM_RDn;
wire        W_2S4     = I_CMPBLK ? 1'b0     : 1'b1 ;

ram_1024_8 U_2PR(

   .I_CLK(~I_CLK_12M),
   .I_ADDR(W_vram_AB),
   .I_D(WI_DB),
   .I_CE(~W_vram_CS),
   .I_WE(~I_VRAM_WRn),
   .O_D(WO_DB)

);

//----------------
// Colour PROM 2N
//----------------

wire  [7:0]W_2N_AD = {W_vram_AB[9:7],W_vram_AB[4:0]};
wire  [3:0]W_2N_DO;

COL_PROM_256_4 prom2n(I_CLK_12M, W_2N_AD, W_2N_DO,
                      I_DLCLK, I_DLADDR, I_DLDATA, I_DLWR);

//-----------------
// Part 2M (LS174)
//-----------------

reg    CLK_2M;
reg    [3:0]COL;

always@(negedge I_CLK_24M) begin

   reg CLK_2Mp, H_CNT0p;

   CLK_2M  <= ~(&I_H_CNT[3:1]);
   CLK_2Mp <= CLK_2M;
   
   if (CLK_2Mp && !CLK_2M) COL <= W_2N_DO[3:0];
   
   // Fix for timing issue
   H_CNT0p <= I_H_CNT[0];
   if (!H_CNT0p && I_H_CNT[0]) O_COL <= COL;

end

//-------------------
// Video ROMs 3N, 3P
//-------------------

wire [11:0]W_VRAM_AB = {I_GFXBANK,WO_DB[7:0],I_VF_CNT[2:0]};
wire [15:0]W_3PN_DO;

VID_ROM roms3PN(I_CLK_12M, W_VRAM_AB, 1'b0, W_3PN_DO,
                I_DLCLK, I_DLADDR, I_DLDATA, I_DLWR);

//-------------------
// Shift register 4P
//-------------------

wire   CLK_4PN = I_H_CNT[0];

wire   W_4P_Qa,W_4P_Qh;

wire   [1:0]C_4P = W_4M_Y[1:0];
wire   [7:0]I_4P = W_3PN_DO[7:0];
reg    [7:0]reg_4P;

always@(posedge CLK_4PN)
begin
   case(C_4P)
      2'b00: reg_4P <= reg_4P;
      2'b10: reg_4P <= {reg_4P[6:0],1'b0};
      2'b01: reg_4P <= {1'b0,reg_4P[7:1]};
      2'b11: reg_4P <= I_4P;
   endcase
end

assign W_4P_Qa = reg_4P[7];
assign W_4P_Qh = reg_4P[0];

//-------------------
// Shift register 4N
//-------------------

wire   W_4N_Qa,W_4N_Qh;

wire   [1:0]C_4N = W_4M_Y[1:0];
wire   [7:0]I_4N = W_3PN_DO[15:8];
reg    [7:0]reg_4N;

always@(posedge CLK_4PN)
begin
   case(C_4N)
      2'b00: reg_4N <= reg_4N;
      2'b10: reg_4N <= {reg_4N[6:0],1'b0};
      2'b01: reg_4N <= {1'b0,reg_4N[7:1]};
      2'b11: reg_4N <= I_4N;
   endcase
end

assign W_4N_Qa = reg_4N[7];
assign W_4N_Qh = reg_4N[0];

//-----------------
// Part 4M (LS157)
//-----------------

wire   [3:0]W_4M_a,W_4M_b;
wire   [3:0]W_4M_Y;

assign W_4M_a = {W_4P_Qa,W_4N_Qa,1'b1,~(CLK_2M|W_2S4)};
assign W_4M_b = {W_4P_Qh,W_4N_Qh,~(CLK_2M|W_2S4),1'b1};
assign W_4M_Y = I_FLIP ? W_4M_b:W_4M_a;

assign O_VID[0] = W_4M_Y[2];
assign O_VID[1] = W_4M_Y[3];

//-----------------------
// VRAM BUSY signal @ 2K
//-----------------------

reg    W_VRAMBUSY;

always@(posedge I_H_CNT[2] or negedge I_H_CNT[9])
begin
   if(I_H_CNT[9] == 1'b0)
      W_VRAMBUSY <= 1'b1;
   else
      W_VRAMBUSY <= I_H_CNT[4]&I_H_CNT[5]&I_H_CNT[6]&I_H_CNT[7];
end

assign O_VRAMBUSYn = ~W_VRAMBUSY;

//-------------------
// ESBLK signal @ 2K
// This signal doesn't go anywhere on the schematic.
//-------------------

reg    W_ESBLK;

always@(posedge I_H_CNT[6] or negedge I_H_CNT[9])
begin
   if(I_H_CNT[9] == 1'b0)
      W_ESBLK <= 1'b0;
   else
      W_ESBLK <= ~I_H_CNT[7];
end

assign O_ESBLKn = ~W_ESBLK;

endmodule

