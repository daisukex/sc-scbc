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
//  Module: USB Port Controller (sc_scbc_upc)
//-----------------------------------------------------------------------------

module sc_scbc_upc import sc_ulpi_pkg::*; # (
  parameter ADDR_WIDTH = 32
) (
  // ULPI clock and reset
  input ULPICLK,
  input ULPIRSTB,

  // Port Controller interrupt
  output UPC_ISR,

  // Register Interface
  input WENB,
  input [ADDR_WIDTH-1:0] WADR,
  input [31:0] WDAT,
  input [3:0] WBEN,
  input RENB,
  input [ADDR_WIDTH-1:0] RADR,
  output logic [31:0] RDAT,

  // USB port control signals
  output UPSI_REQ,
  input UPSI_ACK,
  output UPSI_TYPE,
  output [4:0] UPSI_STATE,
  output UPSI_CFG,

  // ULPI port status
  output UPS_OPERATIONAL,

  // USB port event
  input ULPI_CSC,
  input [1:0] ULPI_CCS,

  // Low-level access interface to ULPI Register
  output ULLA_REQ,
  input ULLA_ACK,
  output ULLA_WR0RD1,
  output [7:0] ULLA_ADDR,
  output [7:0] ULLA_WRDATA,

  // ULPI read data signal
  input [7:0] URC_DATA,

  // Frame Timing signal
  input FT_1MS
);

logic CFG_HOST;
logic CFG_DEVICE;
logic PRESET_REQ;
logic UPS_CONNECT;
logic UPS_RESET;
logic UPS_SUSPEND;

// ----
// USB Port Register
// --------------------------------------------------
sc_scbc_upr # (
  .ADDR_WIDTH(ADDR_WIDTH)
) upr (
  // ULPI clock and reset
  .ULPICLK(ULPICLK),
  .ULPIRSTB(ULPIRSTB),

  // Port Controller interrupt
  .UPC_ISR(UPC_ISR),

  // Register interface
  .WENB(WENB),
  .WADR(WADR),
  .WDAT(WDAT),
  .WBEN(WBEN),
  .RENB(RENB),
  .RADR(RADR),
  .RDAT(RDAT),

  // USB Port Register signal
  .CFG_HOST(CFG_HOST),
  .CFG_DEVICE(CFG_DEVICE),
  .PRESET_REQ(PRESET_REQ),

  // USB port status
  .UPS_CONNECT(UPS_CONNECT),
  .UPS_RESET(UPS_RESET),
  .UPS_OPERATIONAL(UPS_OPERATIONAL),
  .UPS_SUSPEND(UPS_SUSPEND),

  // ULPI port event
  .ULPI_CCS(ULPI_CCS),

  // Low-level access interface to ULPI Register
  .ULLA_REQ(ULLA_REQ),
  .ULLA_ACK(ULLA_ACK),
  .ULLA_WR0RD1(ULLA_WR0RD1),
  .ULLA_ADDR(ULLA_ADDR),
  .ULLA_WRDATA(ULLA_WRDATA),

  // ULPI read data signal
  .URC_DATA(URC_DATA)
);

// ----
// USB Port State Machnie
// --------------------------------------------------
sc_scbc_ups ups (
  // System Interface
  .ULPICLK(ULPICLK),
  .ULPIRSTB(ULPIRSTB),

   // USB Port Register
  .CFG_HOST(CFG_HOST),
  .CFG_DEVICE(CFG_DEVICE),
  .PRESET_REQ(PRESET_REQ),

  // USB Port State
  .UPS_CONNECT(UPS_CONNECT),
  .UPS_RESET(UPS_RESET),
  .UPS_OPERATIONAL(UPS_OPERATIONAL),
  .UPS_SUSPEND(UPS_SUSPEND),

  // Frame Timing
  .FT_1MS(FT_1MS),

  .UPSI_REQ(UPSI_REQ),
  .UPSI_ACK(UPSI_ACK),
  .UPSI_TYPE(UPSI_TYPE),
  .UPSI_STATE(UPSI_STATE),
  .UPSI_CFG(UPSI_CFG),
  .URC_DATA(URC_DATA),

  // ULPI Port Event
  .ULPI_CCS(ULPI_CCS)
);

endmodule
