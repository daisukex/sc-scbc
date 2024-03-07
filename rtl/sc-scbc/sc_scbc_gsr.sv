//-----------------------------------------------------------------------------
// Copyright 2024 Space Cubics, LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//-----------------------------------------------------------------------------
// Space Cubics Standard IP Core
//  Space Communication Bus Controller
//  Module: General Synchronizer Register (sc_scbc_gsr)
//-----------------------------------------------------------------------------

module sc_scbc_gsr
  import sc_ipreg_pkg_v1_0::*;
  import sc_scbc_reg_pkg::*;
# (
  parameter ADDR_WIDTH = 32
) (
  // System bus clock and resrt
  input SYSCLK,
  input SYSRSTB,
  // System bus interrupt output signal
  output INTERRUPT,

  // Register Interface
  input WENB,
  input [ADDR_WIDTH-1:0] WADR,
  input [31:0] WDAT,
  input [3:0] WBEN,
  input RENB,
  input [ADDR_WIDTH-1:0] RADR,
  output logic [31:0] RDAT,

  // Interrupt input signal
  input UPC_ISR,

  // ULPI PHY control signals
  output ULPI_PWRDWNB,
  output ULPI_RSTB,
  input ULPI_CLKSTATE
);

`include "sc_scbc_version.vh"

// ----
// SCBC Version Register
// --------------------------------------------------
scRegHit_t regHitVer;
assign regHitVer = isRegHit(scbcVer_p, addrDecodeBits, WADR, RADR, WENB, RENB);

scbcVer_t scbcVer;
assign scbcVer.majorVer = majorVersion;
assign scbcVer.minorVer = minorVersion;
assign scbcVer.patchVer = patchVersion;


// ----
// ULPI PHY Control Status Register
// --------------------------------------------------
scRegHit_t regHitUPC;
scbcUPC_t scbcUPC, scbcUPCRdD;
assign regHitUPC = isRegHit(scbcUPC_p, addrDecodeBits, WADR, RADR, WENB, RENB);

always_ff @ (posedge SYSCLK) begin
  if (!SYSRSTB) 
    scbcUPC <= scbcUPC_p.init;
  else
    scbcUPC <= scRegWr(scbcUPC_p, regHitUPC, scbcUPC, WDAT, WBEN);
end
assign ULPI_PWRDWNB = ~scbcUPC.ulpiPowerDown;
assign ULPI_RSTB = ~scbcUPC.ulpiReset;
always_comb begin
  scbcUPCRdD = scbcUPC;
  scbcUPCRdD.ulpiClkSt = ULPI_CLKSTATE;
end


// ----
// SCBC Interrupt Status Register
// --------------------------------------------------
scRegHit_t regHitISR;
assign regHitISR = isRegHit(scbcISR_p, addrDecodeBits, WADR, RADR, WENB, RENB);
scbcISR_t scbcISR;

always_comb begin
  scbcISR = 0;
  scbcISR.portStatusST = UPC_ISR;
end


// ----
// SCBC Interrupt Enable Register
// --------------------------------------------------
scRegHit_t regHitIER;
assign regHitIER = isRegHit(scbcIER_p, addrDecodeBits, WADR, RADR, WENB, RENB);
scbcIER_t scbcIER;

always_ff @ (posedge SYSCLK) begin
  if (!SYSRSTB) 
    scbcIER <= scbcIER_p.init;
  else
    scbcIER <= scRegWr(scbcIER_p, regHitIER, scbcIER, WDAT, WBEN);
end
assign INTERRUPT = |(scbcIER & scbcISR);


// ----
// Register Read Control
//-----------------------------------------------
always @ (posedge SYSCLK) begin
  if (!SYSRSTB)
    RDAT <= 32'h0000_0000;
  else begin
    if (regHitVer.rd)      RDAT <= scbcVer;
    else if (regHitUPC.rd) RDAT <= scbcUPCRdD;
    else if (regHitISR.rd) RDAT <= scbcISR;
    else if (regHitIER.rd) RDAT <= scbcIER;
    else                   RDAT <= 32'h0000_0000;
  end
end

endmodule
