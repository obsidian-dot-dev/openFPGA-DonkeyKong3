//----------------------------------------------------------------------------
// Donkey Kong 3 Arcade
//
// Author: gaz68 (https://github.com/gaz68) July 2020
//
// Control inputs and DIP Switches.
//----------------------------------------------------------------------------

//---------------------------------------------------------------------------------
// CONTROL INPUTS
//
//              B0       B1      B2      B3      B4       B5         B6       B7
//---------------------------------------------------------------------------------
// SW1(MAIN)   RIGHT    LEFT     UP     DOWN    FIRE   1P START   2P START   MENU
// SW2(SUB)    RIGHT2   LEFT2    UP2    DOWN2   FIRE2   COIN 1     COIN 2     -
//---------------------------------------------------------------------------------

//---------------------------------------------------------------------------------
//  DIP SWITCHES
//
//  https://www.arcade-museum.com/dipswitch-settings/7611.html
//
//  Toggle (DIP1) Settings:
//  A   B   C   D   E   F   G   H    Option
//---------------------------------------------------------------------------------
//                                   Number of Players per Game
//                                   --------------------------
// Off Off                           3
// On  Off                           4
// Off On                            5
// On  On                            6
// 
//                                   Extra Life
//                                   ----------
//         Off Off                   30,000 points
//         On  Off                   40,000 points
//         Off On                    50,000 points
//         On  On                    No extra life
// 
//                                   Additional Extra Life
//                                   ---------------------
//                 Off Off           30,000 points
//                 On  Off           40,000 points
//                 Off On            50,000 points
//                 On  On            No additional extra life
// 
//                                   Difficulty
//                                   ----------
//                         Off Off   (1) Easy
//                         On  Off   (2)
//                         Off On    (3)
//                         On  On    (4) Hard 
//
//---------------------------------------------------------------------------------
//  Toggle (DIP2) Settings
//  I   J   K   L   M   N   O   P    Option
//---------------------------------------------------------------------------------
//                                   Coins per Credit
//                                   ----------------
// Off On  Off                       3 Coins 1 Credit
// Off Off On                        2 Coins 1 Credit
// Off Off Off                       1 Coin  1 Credit
// Off On  On                        1 Coin  2 Credits
// On  Off Off                       1 Coin  3 Credits
// On  On  Off                       1 Coin  4 Credits
// On  Off On                        1 Coin  5 Credits
// On  On  On                        1 Coin  6 Credits
// 
//                                    Game Test
//                                    ---------
//                          Off       Off
//                          On        On
// 
//                                   Upright/Table
//                                   -------------
//                             Off   Upright
//                             On    Table
//---------------------------------------------------------------------------------

module dkong3_input
(
	input       clk,
   input  [7:0]I_SW1,
   input  [7:0]I_SW2,
   input  [7:0]I_DIP1,
   input  [7:0]I_DIP2,
   input       I_SW1_OE_n,
   input       I_SW2_OE_n,
   input       I_DIP1_OE_n,
   input       I_DIP2_OE_n,

   output reg [7:0]O_D
);


wire   [7:0]W_SW1  = I_SW1_OE_n  ?  8'h00: ~I_SW1;
wire   [7:0]W_SW2  = I_SW2_OE_n  ?  8'h00: !I_DIP2[7] ? ~I_SW2 : {~I_SW2[7:5],~I_SW1[4:0]};
wire   [7:0]W_DIP1 = I_DIP1_OE_n ?  8'h00:  I_DIP1;
wire   [7:0]W_DIP2 = I_DIP2_OE_n ?  8'h00:  {I_DIP2[7:3],I_DIP2[0],I_DIP2[1],I_DIP2[2]};

always @(posedge clk) 
 O_D = W_SW1 | W_SW2 | W_DIP1 | W_DIP2;

endmodule
