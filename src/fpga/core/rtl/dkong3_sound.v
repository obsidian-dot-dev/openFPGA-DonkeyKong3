//----------------------------------------------------------------------------
// Donkey Kong 3 Arcade
//
// Author: gaz68 (https://github.com/gaz68) July 2020
//
// Sound sub-system. 2 x Ricoh 2A03 chips, ROM and RAM.
//----------------------------------------------------------------------------

module dkong3_sound
(
   input        I_CLK_24M, 
   input        I_SUBCLK,
   input        I_SUB_NMIn,
   input        I_SUB_RESETn,
   input   [3:0]I_4E_Q,
   input   [7:0]I_MCPU_DO,
   
   input  [16:0]I_DLADDR,
   input   [7:0]I_DLDATA,
   input        I_DLWR,

   output signed [15:0]O_SAMPLE
);


reg [7:0]I_MCPU_DO_REG;
always @(posedge I_SUBCLK) begin
   I_MCPU_DO_REG<=I_MCPU_DO;
end
//--------
// Clocks
//--------

// Odd or even apu cycle, AKA div_apu or apu_/clk2.
// This is actually not 50% duty cycle. It is high for 18 master cycles 
// and low for 6 master cycles. It is considered active when low or "even".
reg odd_or_even = 1; // 1 == odd, 0 == even

// Clock Divider and counter
localparam div_cpu_n = 5'd12;
reg [4:0] div_cpu = 5'd1;

wire cpu_ce  = (div_cpu == div_cpu_n);
wire phi2 = (div_cpu > 4 && div_cpu < div_cpu_n);

always @(posedge I_SUBCLK) begin

   div_cpu <= cpu_ce || (div_cpu > div_cpu_n) ? 5'd1 : div_cpu + 5'd1;

   if (~I_SUB_RESETn) begin
      odd_or_even <= 1;
   end else if (cpu_ce) begin
      odd_or_even <= ~odd_or_even;
   end

end

//-----------------------------
// Sub CPU 1 @ 4M (Ricoh 2A03)
//-----------------------------

wire  [15:0]W_SUB1_ADDR;
wire   [7:0]W_SUB1_DBO;
wire        W_SUB1_RnW;
wire  [15:0]W_APU1_SAMPLE;

dkong3_sub sub1
(
   .I_SUBCLK(I_SUBCLK),
   .I_SUB_NMIn(I_SUB_NMIn),
   .I_SUB_RESETn(I_SUB_RESETn),

   .I_SUB_DBI(W_SUB1_DBI),
   .I_CPU_CE(cpu_ce),
   .I_PHI2(phi2),
   .I_ODD_OR_EVEN(odd_or_even),
   
   .O_SUB_ADDR(W_SUB1_ADDR),
   .O_SUB_DB0(W_SUB1_DBO),
   .O_SUB_RNW(W_SUB1_RnW),
   .O_SAMPLE(W_APU1_SAMPLE)
);

//--------------------
// Sub CPU 1 Data Bus
//--------------------

wire   [7:0]W_SUB1_DBI = W_SUB1ROM_DO | W_SUB1RAM_DO | W_SUB1INP0_DO | W_SUB1INP1_DO;

//----------------------
// ROM 5L for Sub CPU 1
//----------------------

wire  [7:0]W_SUB1ROM_DO;
wire       W_SUB1ROM_OEn = (W_SUB1_ADDR[15] == 1'b0);

// ~phi2 not working as chip enable
SUB1_ROM sub1rom(I_SUBCLK, W_SUB1_ADDR[12:0], 1'b0, W_SUB1ROM_OEn, W_SUB1ROM_DO, 
                 I_CLK_24M, I_DLADDR, I_DLDATA, I_DLWR);

//----------
// RAM @ 5K
//----------

reg   [7:0]W_SUB1RAM_DO;
wire  [7:0]W_RAM5K_DO;

ram_2048_8 U_5K
(
   .I_CLK(I_SUBCLK),
   .I_ADDR(W_SUB1_ADDR[10:0]),
   .I_D(W_SUB1_DBO),
   .I_CE(1'b1), // phi2 doesn't work here.
   .I_WE(~W_SUB1_RnW & (W_SUB1_ADDR[15:14] == 2'b00)),
   .O_D(W_RAM5K_DO)
);

always@(posedge I_SUBCLK)
begin
   W_SUB1RAM_DO <= (W_SUB1_ADDR[15:14] == 2'b00 & W_SUB1_RnW == 1'b1) ? W_RAM5K_DO : 8'h00;
end


//----------------------------
// 74LS374 @ 4J
// Input port 0 for Sub CPU 1
//----------------------------

reg   [7:0]sub1inp0;
wire  [7:0]W_SUB1INP0_DO;

always@(posedge I_SUBCLK)
begin

   reg prev4EQ0;
   prev4EQ0 <= I_4E_Q[0];
   
   if (~prev4EQ0 & I_4E_Q[0]) begin
      sub1inp0 <= I_MCPU_DO_REG;
   end

end


// Input ports are mapped into the APU's range.
assign W_SUB1INP0_DO = (W_SUB1_ADDR == 16'h4016) & W_SUB1_RnW ? sub1inp0 : 8'h00;


//----------------------------
// 74LS374 @ 4H
// Input port 1 for sub CPU 1
//----------------------------

reg   [7:0]sub1inp1;
wire  [7:0]W_SUB1INP1_DO;

always@(posedge I_SUBCLK)
begin

   reg prev4EQ1;
   prev4EQ1 <= I_4E_Q[1];
   
   if (~prev4EQ1 & I_4E_Q[1]) begin
      sub1inp1 <= I_MCPU_DO_REG;
   end

end

// Input ports are mapped into the APU's range.
assign W_SUB1INP1_DO = (W_SUB1_ADDR == 16'h4017) & W_SUB1_RnW ? sub1inp1 : 8'h00;


//-----------------------------
// Sub CPU 2 @ 5J (Ricoh 2A03)
//-----------------------------

wire  [15:0]W_SUB2_ADDR;
wire   [7:0]W_SUB2_DBO;
wire        W_SUB2_RnW;
wire  [15:0]W_APU2_SAMPLE;

dkong3_sub sub2
(
   .I_SUBCLK(I_SUBCLK),
   .I_SUB_NMIn(I_SUB_NMIn),
   .I_SUB_RESETn(I_SUB_RESETn),

   .I_SUB_DBI(W_SUB2_DBI),
   .I_CPU_CE(cpu_ce),
   .I_PHI2(phi2),
   .I_ODD_OR_EVEN(odd_or_even),
   
   .O_SUB_ADDR(W_SUB2_ADDR),
   .O_SUB_DB0(W_SUB2_DBO),
   .O_SUB_RNW(W_SUB2_RnW),
   .O_SAMPLE(W_APU2_SAMPLE)
);

//--------------------
// Sub CPU 2 Data Bus
//--------------------

wire   [7:0]W_SUB2_DBI = W_SUB2ROM_DO | W_SUB2RAM_DO | W_SUB2INP_DO;

//----------------------
// ROM 6M for Sub CPU 2
//----------------------

wire  [7:0]W_SUB2ROM_DO;
wire       W_SUB2ROM_OEn = (W_SUB2_ADDR[15] == 1'b0);

// ~phi2 not working as chip enable
SUB2_ROM sub2rom(I_SUBCLK, W_SUB2_ADDR[12:0], 1'b0, W_SUB2ROM_OEn, W_SUB2ROM_DO, 
                 I_CLK_24M, I_DLADDR, I_DLDATA, I_DLWR);

//------------------------
// RAM @ 6F for Sub CPU 2
//------------------------

reg   [7:0]W_SUB2RAM_DO;
wire  [7:0]W_RAM6F_DO;

ram_2048_8 U_6F
(
   .I_CLK(I_SUBCLK),
   .I_ADDR(W_SUB2_ADDR[10:0]),
   .I_D(W_SUB2_DBO),
   .I_CE(1'b1),
   .I_WE(~W_SUB2_RnW & (W_SUB2_ADDR[15:14] == 2'b00)),
   .O_D(W_RAM6F_DO)
);

always@(posedge I_SUBCLK)
begin
   W_SUB2RAM_DO <= (W_SUB2_ADDR[15:14] == 2'b00 & W_SUB2_RnW == 1'b1) ? W_RAM6F_DO : 8'h00;
end


//--------------------------
// 74LS374 @ 5F
// Input port for Sub CPU 2
//--------------------------

reg   [7:0]sub2inp;
wire  [7:0]W_SUB2INP_DO;

always@(posedge I_SUBCLK)
begin

   reg prev4EQ2;
   prev4EQ2 <= I_4E_Q[2];
   
   if (~prev4EQ2 & I_4E_Q[2]) begin
      sub2inp <= I_MCPU_DO_REG;
   end

end


// Input port is mapped into the APU's range.
assign W_SUB2INP_DO = (W_SUB2_ADDR == 16'h4016) & W_SUB2_RnW ? sub2inp : 8'h00;

// Attenuate and mix
assign O_SAMPLE = {W_APU1_SAMPLE[15],W_APU1_SAMPLE[15:1]} + 
                  {W_APU2_SAMPLE[15],W_APU2_SAMPLE[15:1]};

endmodule
