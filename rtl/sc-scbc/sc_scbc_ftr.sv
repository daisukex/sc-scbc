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
//  Module: Frame Timing controller Register (sc_scbc_ftr)
//-----------------------------------------------------------------------------

module sc_scbc_ftr
  import sc_ipreg_pkg_v1_0::*;
  import sc_scbc_reg_pkg::*;
# (
  parameter ADDR_WIDTH = 32
) (
  // ULPI clock and reset
  input ULPICLK,
  input ULPIRSTB,

  // Register Interface
  input WENB,
  input [ADDR_WIDTH-1:0] WADR,
  input [31:0] WDAT,
  input [3:0] WBEN,
  input RENB,
  input [ADDR_WIDTH-1:0] RADR,
  output logic [31:0] RDAT,

  // FTC Register Signals
  output [15:0] FM_INTERVAL,
  output FM_ENABLE,
  input FM_ROLLOVER,
  input [15:0] FM_REMAINING,
  input FM_RTOGGLE,
  output FM_MODE,
  input [15:0] FM_NUMBER
);

// ----
// Frame Interval Register
// --------------------------------------------------
scRegHit_t regHitFmI;
assign regHitFmI = isRegHit(scbcFmI_p, addrDecodeBits, WADR, RADR, WENB, RENB);
scbcFmI_t scbcFmI;

always_ff @ (posedge ULPICLK) begin
  if (!ULPIRSTB)
    scbcFmI <= scbcFmI_p.init;
  else
    scbcFmI <= scRegWr(scbcFmI_p, regHitFmI, scbcFmI, WDAT, WBEN);
end
assign FM_INTERVAL = scbcFmI.fmInterval;

// ----
// Frame Remaining Register
// --------------------------------------------------
scRegHit_t regHitFmR;
assign regHitFmR = isRegHit(scbcFmR_p, addrDecodeBits, WADR, RADR, WENB, RENB);
scbcFmR_t scbcFmR, scbcFmRRdD;

always_ff @ (posedge ULPICLK) begin
  if (!ULPIRSTB)
    scbcFmR <= scbcFmR_p.init;
  else
    scbcFmR <= scRegWr(scbcFmR_p, regHitFmR, scbcFmR, WDAT, WBEN);
end
assign FM_ENABLE = scbcFmR.fmEnable;

always_comb begin
  scbcFmRRdD = scbcFmR;
  scbcFmRRdD.fmRToggle = FM_RTOGGLE;
  scbcFmRRdD.fmRemaining = FM_REMAINING;
end

// ----
// Frame Number Register
// --------------------------------------------------
scRegHit_t regHitFmN;
assign regHitFmN = isRegHit(scbcFmN_p, addrDecodeBits, WADR, RADR, WENB, RENB);
scbcFmN_t scbcFmN, scbcFmNRdD;

always_ff @ (posedge ULPICLK) begin
  if (!ULPIRSTB)
    scbcFmN <= scbcFmN_p.init;
  else
    scbcFmN <= scRegWr(scbcFmN_p, regHitFmN, scbcFmN, WDAT, WBEN);
end
assign FM_MODE = scbcFmN.fmNMode;

always_comb begin
  scbcFmNRdD = scbcFmN;
  scbcFmNRdD.fmNumber = FM_NUMBER;
end

// ----
// Register Read Control
//-----------------------------------------------
always @ (posedge ULPICLK) begin
  if (!ULPIRSTB)
    RDAT <= 32'h0000_0000;
  else begin
    if (RENB) begin
      if (regHitFmI.rd)      RDAT <= scbcFmI;
      else if (regHitFmR.rd) RDAT <= scbcFmRRdD;
      else if (regHitFmN.rd) RDAT <= scbcFmNRdD;
      else                   RDAT <= 32'h0000_0000;
    end
  end
end

endmodule
