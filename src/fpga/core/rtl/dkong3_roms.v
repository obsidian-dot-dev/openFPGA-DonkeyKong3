//----------------------------------------------------------------------------
// Donkey Kong 3 Arcade
//
// Author: gaz68 (https://github.com/gaz68) July 2020
//
// ROM Modules
//----------------------------------------------------------------------------
//
// ROM addresses:
//
// 0x00000 - 0x01FFF 7B PROGRAM ROM (8KB)
// 0x02000 - 0x03FFF 7C PROGRAM ROM (8KB)
// 0x04000 - 0x05FFF 7D PROGRAM ROM (8KB)
// 0x06000 - 0x06FFF 3P GFX ROM (4KB)
// 0x07000 - 0x07FFF 3N GFX ROM (4KB)
// 0x08000 - 0x09FFF 7E PROGRAM ROM (8KB)
// 0x0A000 - 0x0AFFF 7C GFX ROM (4KB) 
// 0x0B000 - 0x0BFFF 7D GFX ROM (4KB) 
// 0x0C000 - 0x0CFFF 7E GFX ROM (4KB) 
// 0x0D000 - 0x0DFFF 7F GFX ROM (4KB) 
// 0x0E000 - 0x0FFFF 5L SOUND ROM (8KB)
// 0x10000 - 0x11FFF 6H SOUND ROM (8KB)
// 0x12000 - 0x121FF 1D PROM (512B) 512x8 CLUT PROM (only 256 entries used)
// 0x12200 - 0x123FF 1C PROM (512B) 512x4 CLUT PROM (only 256 entries used)
// 0x12400 - 0x124FF 2N PROM (256B) 256x4 Char Colour palette PROM
// 0x12500 - 0x1251F 5E PROM (32B) 32x8 Address Decoder PROM

module DLROM #(parameter AW,parameter DW)
(
   input                  CLK0,
   input        [(AW-1):0]AD0,
   output reg   [(DW-1):0]DO0,

   input                  CLK1,
   input        [(AW-1):0]AD1,
   input        [(DW-1):0]DI1,
   input                  WE1
);

reg [DW-1:0] core[0:((2**AW)-1)];

always @(posedge CLK0) DO0 <= core[AD0];
always @(posedge CLK1) if (WE1) core[AD1] <= DI1;

endmodule


module DLROMB #(parameter AW,parameter DW)
(
   input                  CLK0,
   input        [(AW-1):0]AD0,
   output reg   [(DW-1):0]DO0,

   input                  CLK1,
   input        [(AW-1):0]AD1,
   input        [(DW-1):0]DI1,
   input                  WE1
);

dpram #(AW, DW) dprom
(
   .clock_a(CLK1),
   .wren_a(WE1),
   .address_a(AD1),
   .data_a(DI1),

   .clock_b(CLK0),
   .address_b(AD0),
   .q_b(DO0)
);

endmodule

//--------------------------------
// Main CPU ROMS 7B,7C,7D and 7E.
//--------------------------------

module MAIN_ROM
(
   input         I_CLK,
   input   [15:0]I_ADDR,
   input    [3:0]I_CE,
   input         I_OE,
   output   [7:0]O_DATA,

   input         I_DLCLK,
   input   [16:0]I_DLADDR,
   input    [7:0]I_DLDATA,
   input         I_DLWR
);

wire  [7:0] dt7b, dt7c, dt7d, dt7e;

DLROM #(13,8) mrom7b(I_CLK, I_ADDR[12:0], dt7b,
                     I_DLCLK, I_DLADDR[12:0], I_DLDATA,
                     I_DLWR & (I_DLADDR[16:13]==4'b0_000));

DLROM #(13,8) mrom7c(I_CLK, I_ADDR[12:0], dt7c,
                     I_DLCLK, I_DLADDR[12:0], I_DLDATA,
                     I_DLWR & (I_DLADDR[16:13]==4'b0_001));

DLROM #(13,8) mrom7d(I_CLK, I_ADDR[12:0], dt7d,
                     I_DLCLK, I_DLADDR[12:0], I_DLDATA, 
                     I_DLWR & (I_DLADDR[16:13]==4'b0_010));

DLROM #(13,8) mrom7e(I_CLK, I_ADDR[12:0], dt7e,
                     I_DLCLK, I_DLADDR[12:0], I_DLDATA,
                     I_DLWR & (I_DLADDR[16:13]==4'b0_100));

assign O_DATA = (I_CE[0] == 1'b0 & I_OE == 1'b0) ? dt7b :
                (I_CE[1] == 1'b0 & I_OE == 1'b0) ? dt7c :
                (I_CE[2] == 1'b0 & I_OE == 1'b0) ? dt7d :
                (I_CE[3] == 1'b0 & I_OE == 1'b0) ? dt7e :
                8'h00;

endmodule

//----------------=-------------------
// Object/Sprite ROMs 7C,7D,7E,7F.
// OEn tied to ground. CEn is common.
// 32-bit output.
//------------------------------------

module OBJ_ROM
(
   input          I_CLK,
   input    [11:0]I_ADDR,
   input          I_CE,
   output   [31:0]O_DATA,

   input          I_DLCLK,
   input    [16:0]I_DLADDR,
   input     [7:0]I_DLDATA,
   input          I_DLWR
);

wire [7:0] dt7c, dt7d, dt7e, dt7f;

DLROM #(12,8) objrom7c(I_CLK, I_ADDR, dt7c,
                       I_DLCLK, I_DLADDR[11:0], I_DLDATA,
                       I_DLWR & (I_DLADDR[16:12]==5'b0_1010));

DLROM #(12,8) objrom7d(I_CLK, I_ADDR, dt7d,
                       I_DLCLK, I_DLADDR[11:0], I_DLDATA,
                       I_DLWR & (I_DLADDR[16:12]==5'b0_1011));

DLROM #(12,8) objrom7e(I_CLK, I_ADDR, dt7e,
                       I_DLCLK, I_DLADDR[11:0], I_DLDATA,
                       I_DLWR & (I_DLADDR[16:12]==5'b0_1100));

DLROM #(12,8) objrom7f(I_CLK, I_ADDR, dt7f,
                       I_DLCLK, I_DLADDR[11:0], I_DLDATA,
                       I_DLWR & (I_DLADDR[16:12]==5'b0_1101));

assign O_DATA = (I_CE == 1'b0) ? {dt7c,dt7d,dt7e,dt7f} : 32'h0000;

endmodule

//-----------------------------------------
// Backgound character tiles ROM's 3P, 3N. 
// OEn tied to ground. CEn is common.
// 16-bit output.
//-----------------------------------------

module VID_ROM
(
   input         I_CLK,
   input   [11:0]I_ADDR,
   input         I_CE,
   output  [15:0]O_DATA,

   input         I_DLCLK,
   input	  [16:0]I_DLADDR,
   input    [7:0]I_DLDATA,
   input         I_DLWR
);

wire [7:0] dt3p, dt3n;

DLROM #(12,8) vidrom3p(I_CLK, I_ADDR, dt3p,
                       I_DLCLK, I_DLADDR[11:0], I_DLDATA,
                       I_DLWR & (I_DLADDR[16:12]==5'b0_0110));

DLROM #(12,8) vidrom3n(I_CLK, I_ADDR, dt3n,
                       I_DLCLK, I_DLADDR[11:0], I_DLDATA,
                       I_DLWR & (I_DLADDR[16:12]==5'b0_0111));

assign O_DATA = (I_CE == 1'b0) ? {dt3n,dt3p} : 16'h0000;

endmodule

//-----------------------------------
// CLUT PROM 1D (512x8)
// Only 256 entries are used.
// 8-bit output.
//-----------------------------------

module CLUT_PROM_512_8
(
   input          I_CLK,
   input     [8:0]I_ADDR,
   output    [7:0]O_DATA,

   input          I_DLCLK,
   input    [16:0]I_DLADDR,
   input     [7:0]I_DLDATA,
   input          I_DLWR
);

wire [7:0] dt;

DLROM #(9,8) prom1d(I_CLK, I_ADDR, dt,
                    I_DLCLK, I_DLADDR[8:0], I_DLDATA,
                    I_DLWR & (I_DLADDR[16:9]==8'b1_0010_000));

assign O_DATA = dt;

endmodule

//-----------------------------------
// CLUT PROM 1C (512x4)
// Only 256 entries are used.
// 4-bit output.
//-----------------------------------

module CLUT_PROM_512_4
(
   input          I_CLK,
   input     [8:0]I_ADDR,
   output    [3:0]O_DATA,

   input          I_DLCLK,
   input    [16:0]I_DLADDR,
   input     [7:0]I_DLDATA,
   input          I_DLWR
);

wire [3:0] dt;

DLROM #(9,4) prom1c(I_CLK, I_ADDR, dt,
                    I_DLCLK, I_DLADDR[8:0], I_DLDATA[3:0],
                    I_DLWR & (I_DLADDR[16:9]==8'b1_0010_001));

assign O_DATA = dt;

endmodule

//-----------------------------------
// Colour palette PROM 2N (256x4)
// 4-bit output.
//-----------------------------------

module COL_PROM_256_4
(
   input          I_CLK,
   input     [7:0]I_ADDR,
   output    [3:0]O_DATA,

   input          I_DLCLK,
   input    [16:0]I_DLADDR,
   input     [7:0]I_DLDATA,
   input          I_DLWR
);

wire [3:0] dt;

DLROM #(8,4) prom2n(I_CLK, I_ADDR, dt,
                    I_DLCLK, I_DLADDR[7:0], I_DLDATA[3:0],
                    I_DLWR & (I_DLADDR[16:8]==9'h124));

assign O_DATA = dt;

endmodule

//-----------------------------------
// Address decoder PROM 5E (32x8)
//-----------------------------------

module ADEC_PROM
(
   input          I_CLK,
   input     [4:0]I_ADDR, //A15,A14,A13,A12,A11
   output    [7:0]O_DATA,

   input          I_DLCLK,
   input    [16:0]I_DLADDR,
   input     [7:0]I_DLDATA,
   input          I_DLWR
);

wire [7:0] dt;

DLROM #(5,8) prom5e(I_CLK, I_ADDR, dt,
                    I_DLCLK, I_DLADDR[4:0], I_DLDATA,
                    I_DLWR & (I_DLADDR[16:5]==12'b1_0010_0101_000));

assign O_DATA = dt;

endmodule

//---------------------------
// Sub CPU 1 (Sound) ROM 5L.
//---------------------------

module SUB1_ROM
(
   input          I_CLK,
   input    [12:0]I_ADDR,
   input          I_CE,
   input          I_OE,
   output    [7:0]O_DATA,

   input          I_DLCLK,
   input    [16:0]I_DLADDR,
   input     [7:0]I_DLDATA,
   input          I_DLWR
);

wire [7:0] dt;

DLROM #(13,8) srom5l(I_CLK, I_ADDR[12:0], dt,
                     I_DLCLK, I_DLADDR[12:0], I_DLDATA,
                     I_DLWR & (I_DLADDR[16:13]==4'b0_111));

assign O_DATA = (I_CE == 1'b0 & I_OE == 1'b0) ? dt : 8'h00;

endmodule

//---------------------------
// Sub CPU 2 (Sound) ROM 6H.
//---------------------------

module SUB2_ROM
(
   input          I_CLK,
   input    [12:0]I_ADDR,
   input          I_CE,
   input          I_OE,
   output    [7:0]O_DATA,

   input          I_DLCLK,
   input    [16:0]I_DLADDR,
   input     [7:0]I_DLDATA,
   input          I_DLWR
);

wire [7:0] dt;

DLROM #(13,8) srom6h(I_CLK, I_ADDR[12:0], dt,
                     I_DLCLK, I_DLADDR[12:0], I_DLDATA,
                     I_DLWR & (I_DLADDR[16:13]==4'b1_000));

assign O_DATA = (I_CE == 1'b0 & I_OE == 1'b0) ? dt : 8'h00;

endmodule

