//----------------------------------------------------------------------------
// Donkey Kong 3 Arcade
//
// Author: gaz68 (https://github.com/gaz68) July 2020
//
// Address decoding.
//----------------------------------------------------------------------------

module dkong3_adec
(
   input        I_CLK12M,
   input        I_CLK,
   input        I_RESET_n,
   input  [15:0]I_AB,
   input   [3:0]I_DB,
   input        I_MREQ_n,
   input        I_RFSH_n,
   input        I_RD_n,
   input        I_WR_n,
   input        I_VRAMBUSY_n,
   input        I_VBLK_n,

   input        I_DLCLK,
   input  [16:0]I_DLADDR,
   input   [7:0]I_DLDATA,
   input        I_DLWR,

   output       O_WAIT_n,
   output       O_NMI_n,

   output  [3:0]O_MROM_CSn,
   output  [1:0]O_MRAM_CSn,

   output       O_5A_G_n,        // To LS245. Not used.
   output       O_OBJ_RQ_n,      // 7000 H - 73FF H
   output       O_OBJ_RD_n,      // 7000 H - 73FF H  (R mode)
   output       O_OBJ_WR_n,      // 7000 H - 73FF H  (W mode)
   output       O_VRAM_RD_n,     // 7400 H - 77FF H  (R mode)
   output       O_VRAM_WR_n,     // 7400 H - 77FF H  (W mode)
   output       O_SW1_OE_n,      // 7C00 H           (R mode)
   output       O_SW2_OE_n,      // 7C80 H           (R mode)
   output       O_DIP1_OE_n,     // 7D00 H           (R mode)
   output       O_DIP2_OE_n,     // 7D80 H           (R mode)
   output  [7:0]O_3E_Q,          // Misc control signals
   output  reg [3:0]O_4E_Q,          // Sound control
   output       O_SUB_RESETn
);

//----------
// CPU WAIT
//----------

reg    W_2D1_Qn;
reg    W_2D2_Q;
assign O_WAIT_n = W_2D1_Qn;

always@(posedge I_CLK or negedge I_VBLK_n)
begin
   if(I_VBLK_n == 1'b0)
      W_2D1_Qn <= 1'b1;
   else
      W_2D1_Qn <= I_VRAMBUSY_n | W_3B2_Q[1] | ~I_RFSH_n;
end

// Enable signal for writing to VRAM and OBJRAM.
always@(negedge I_CLK)
begin
   W_2D2_Q <= W_2D1_Qn;
end

//-----------------------------------------------
// CPU NMI
// NMI is activated at the start of each VBLANK.
// CPU can clear the NMI via register @ 3E.
//-----------------------------------------------

wire  W_VBLK = ~I_VBLK_n;
reg   NMI_n;
always@(posedge W_VBLK or negedge W_3E_Q[4])
begin
   if(~W_3E_Q[4])
      NMI_n <= 1'b1;
   else
      NMI_n <= 1'b0;
end

assign O_NMI_n = NMI_n;

//---------------------------
// Address Decoder PROM @ 5E
//---------------------------

wire  [7:0]W_PROM5E_Q;

ADEC_PROM prom5e(I_CLK12M, I_AB[15:11], W_PROM5E_Q, 
                 I_DLCLK, I_DLADDR, I_DLDATA, I_DLWR);

assign O_MROM_CSn = W_PROM5E_Q[4:1];
assign O_MRAM_CSn = W_PROM5E_Q[6:5];

//--------------
// 74LS139 @ 3B
//--------------

wire   [3:0]W_3B1_Q, W_3B2_Q;

logic_74xx139 U_3B_1
(
   .I_G(W_PROM5E_Q[0]),
   .I_Sel({1'b0,I_AB[11]}),
   .O_Q(W_3B1_Q)
);

assign O_5A_G_n = W_3B1_Q[0]; // Not used.

logic_74xx139 U_3B_2
(
   .I_G(W_PROM5E_Q[0] | I_MREQ_n),
   .I_Sel(I_AB[11:10]),
   .O_Q(W_3B2_Q)
);

assign O_OBJ_RQ_n = W_3B2_Q[0];

//--------------
// 74LS138 @ 2A
//--------------

wire  [7:0]W_2A_Q;

logic_74xx138 U_2A
(
   .I_G1(W_2D2_Q),
   //.I_G1(1'b1), // No Wait
   .I_G2a(I_WR_n),
   .I_G2b(I_MREQ_n),
   .I_Sel({W_PROM5E_Q[0],I_AB[11:10]}),
   .O_Q(W_2A_Q)
);

assign O_OBJ_WR_n  = W_2A_Q[0];
assign O_VRAM_WR_n = W_2A_Q[1];

//--------------
// 74LS138 @ 3A
//--------------

wire  [7:0]W_3A_Q;

logic_74xx138 U_3A
(
   .I_G1(1'b1),
   .I_G2a(I_RD_n),
   .I_G2b(I_MREQ_n),
   .I_Sel({W_PROM5E_Q[0],I_AB[11:10]}),
   .O_Q(W_3A_Q)
);

assign O_OBJ_RD_n  = W_3A_Q[0];
assign O_VRAM_RD_n = W_3A_Q[1];

//--------------------------------------
// 74LS138 @ 4E
// Same as 4F except used for writes.
// Control signals mostly for sub CPU's
//--------------------------------------

wire [7:0]W_4E_Q;

logic_74xx138 U_4E
(
   .I_G1(1'b1),
   .I_G2a(I_WR_n),
   .I_G2b(W_3B2_Q[3]),
   .I_Sel(I_AB[9:7]),
   .O_Q(W_4E_Q)
);

always @(posedge I_CLK12M)
 O_4E_Q = W_4E_Q[3:0];

//-----------------------------------
// 74LS138 @ 4F
// Enable signals for reading inputs
// and and DIP switches
//-----------------------------------
//  ADDR DEC  7C00H - 7FFFH  (R)

wire [7:0]W_4F_Q;

logic_74xx138 U_4F
(
   .I_G1(1'b1),
   .I_G2a(I_RD_n),
   .I_G2b(W_3B2_Q[3]),
   .I_Sel(I_AB[9:7]),
   .O_Q(W_4F_Q)
);

assign O_SW1_OE_n  = W_4F_Q[0]; //Menu,2PStart,1PStart,Push,D,U,L,R
assign O_SW2_OE_n  = W_4F_Q[1]; //X,C2,C1,Push2,2D,2U,2L,2R
assign O_DIP2_OE_n = W_4F_Q[2];
assign O_DIP1_OE_n = W_4F_Q[3];

//--------------------------------------
// 74LS259 @ 3E
// Misc control signals (7E80H - 7E87H)
//--------------------------------------

reg   [7:0]W_3E_Q;

always@(posedge I_CLK12M or negedge I_RESET_n)
begin
   if(I_RESET_n == 1'b0) begin
      W_3E_Q <= 0;
   end 
   else begin
      if(W_4E_Q[5] == 1'b0) begin
         case(I_AB[2:0])
            3'h0 : W_3E_Q[0] <= I_DB[0]; // 7E80H Coin counter write
            3'h1 : W_3E_Q[1] <= I_DB[0]; // 7E81H VROM - GFX bank select
            3'h2 : W_3E_Q[2] <= I_DB[0]; // 7E82H Flip (must be inverted)
            3'h3 : W_3E_Q[3] <= I_DB[0]; // 7E83H 2PSL - sprite bank select?
            3'h4 : W_3E_Q[4] <= I_DB[0]; // 7E84H Reset NMI (Sets flip flop)
            3'h5 : W_3E_Q[5] <= I_DB[0]; // 7E85H Z80 DMA RDY write
            3'h6 : W_3E_Q[6] <= I_DB[0]; // 7E86H CAD6. Colour palette bank select.
            3'h7 : W_3E_Q[7] <= I_DB[0]; // 7E87H CAD7. Colour palette bank select.
         endcase
      end
   end
end

assign O_3E_Q = W_3E_Q;

//---------------------------
// 74LS174 @ 5H
// Reset signal to sub CPU's
//---------------------------

reg  sub_resetn;

always@(posedge I_CLK12M or negedge I_RESET_n)
begin

   reg prev;

   if(I_RESET_n == 1'b0) begin
      sub_resetn <= 0;
   end 
   else begin
      prev <= W_4E_Q[3];
      if (~prev & W_4E_Q[3]) begin
         sub_resetn <= I_DB[0];
      end
   end

end

assign O_SUB_RESETn = sub_resetn;


endmodule
