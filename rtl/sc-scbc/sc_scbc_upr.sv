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
//  Module: USB Port Register (sc_scbc_upr)
//-----------------------------------------------------------------------------

module sc_scbc_upr
  import sc_ipreg_pkg_v1_0::*;
  import sc_scbc_reg_pkg::*;
# (
  parameter ADDR_WIDTH = 32
) (
  // ULPI clock and reset
  input ULPICLK,
  input ULPIRSTB,

  // Port Controller interrupt
  output UPC_ISR,

  // Register interface
  input WENB,
  input [ADDR_WIDTH-1:0] WADR,
  input [31:0] WDAT,
  input [3:0] WBEN,
  input RENB,
  input [ADDR_WIDTH-1:0] RADR,
  output logic [31:0] RDAT,

  // USB Port Register signals
  output CFG_HOST,
  output CFG_DEVICE,
  output PRESET_REQ,

  // USB port status signals
  input UPS_CONNECT,
  input UPS_RESET,
  input UPS_OPERATIONAL,
  input UPS_SUSPEND,

  // USB port event signal
  input [1:0] ULPI_CCS,

  // Low-level access interface to ULPI Register
  output ULLA_REQ,
  input ULLA_ACK,
  output [7:0] ULLA_ADDR,
  output ULLA_WR0RD1,
  output [7:0] ULLA_WRDATA,

  // ULPI read data signal
  input [7:0] URC_DATA
);

// ----
// SCBC Configuration Register
// --------------------------------------------------
scRegHit_t regHitCfg;
assign regHitCfg = isRegHit(scbcCfg_p, addrDecodeBits, WADR, RADR, WENB, RENB);
scbcCfg_t scbcCfg;

always_ff @ (posedge ULPICLK) begin
  if (!ULPIRSTB)
    scbcCfg <= scbcCfg_p.init;
  else
    scbcCfg <= scRegWr(scbcCfg_p, regHitCfg, scbcCfg, WDAT, WBEN);
end

assign CFG_HOST = scbcCfg.hostMode;
assign CFG_DEVICE = (scbcCfg.hostMode) ? 1'b0: scbcCfg.deviceMode;

// ----
// USB Port Status Register
// --------------------------------------------------
scRegHit_t regHitUPS;
assign regHitUPS = isRegHit(scbcUPS_p, addrDecodeBits, WADR, RADR, WENB, RENB);
scbcUPS_t scbcUPS, scbcUPSRdD;

logic upsConnect;
always_ff @ (posedge ULPICLK) begin
  if (!ULPIRSTB) begin
    upsConnect <= 1'b0;
    scbcUPS <= scbcUPS_p.init;
  end
  else begin
    upsConnect <= UPS_CONNECT;
    scbcUPS <= scRegWr(scbcUPS_p, regHitUPS, scbcUPS, WDAT, WBEN);
    if (scbcUPS.spr & UPS_OPERATIONAL) begin
      scbcUPS.spr <= 1'b0;
      scbcUPS.prsc <= 1'b1;
      scbcUPS.pesc <= 1'b1;
    end

    // Port Interrupt
    if (upsConnect ^ UPS_CONNECT)
      scbcUPS.csc <= 1'b1;

  end
end
assign PRESET_REQ = scbcUPS.spr;

always_comb begin
  scbcUPSRdD = scbcUPS;
  scbcUPSRdD.lsda = ULPI_CCS[1];
  scbcUPSRdD.spr = 1'b0;
  scbcUPSRdD.prs = UPS_RESET;
  scbcUPSRdD.pss = UPS_SUSPEND;
  scbcUPSRdD.pes = UPS_OPERATIONAL;
  scbcUPSRdD.ccs = UPS_CONNECT;
end
assign UPC_ISR = scbcUPS.csc | scbcUPS.pesc | scbcUPS.pssc | scbcUPS.prsc;

// ----
// SCBC ULPI Low-Level Access Register
// --------------------------------------------------
scRegHit_t regHitULLA;
assign regHitULLA = isRegHit(scbcULLA_p, addrDecodeBits, WADR, RADR, WENB, RENB);
scbcULLA_t scbcULLA;

always_ff @ (posedge ULPICLK) begin
  if (!ULPIRSTB)
    scbcULLA <= scbcULLA_p.init;
  else begin
    scbcULLA <= scRegWr(scbcULLA_p, regHitULLA, scbcULLA, WDAT, WBEN);
    if (ULLA_ACK) begin
      scbcULLA.busy <= 1'b0;
      scbcULLA.rdData <= URC_DATA;
    end
  end
end
assign ULLA_REQ = scbcULLA.busy;
assign ULLA_ADDR = scbcULLA.addr;
assign ULLA_WR0RD1 = scbcULLA.wr0rd1;
assign ULLA_WRDATA = scbcULLA.wrData;

// ----
// Register Read Control
//-----------------------------------------------
always @ (posedge ULPICLK) begin
  if (!ULPIRSTB)
    RDAT <= 32'h0000_0000;
  else begin
    if (RENB) begin
      if (regHitCfg.rd)      RDAT <= scbcCfg;
      else if (regHitULLA.rd) RDAT <= scbcULLA;
      else if (regHitUPS.rd) RDAT <= scbcUPSRdD;
      else                   RDAT <= 32'h0000_0000;
    end
  end
end

endmodule
