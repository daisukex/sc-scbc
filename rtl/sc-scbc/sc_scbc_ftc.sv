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
//  Module: Frame Timing Controller (sc_scbc_ftc)
//-----------------------------------------------------------------------------

module sc_scbc_ftc # (
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

  // USB Port Status signals
  input UPS_OPERATIONAL,

  // Frame Timing signals
  output FT_1MS,
  output [15:0] FT_FMNUMBER
);

logic [15:0] FM_INTERVAL;
logic FM_ENABLE;
logic FM_ROLLOVER;
logic [15:0] FM_REMAINING;
logic FM_RTOGGLE;
logic FM_MODE;

// ----
// Frame Timing Controller Register
// --------------------------------------------------
sc_scbc_ftr # (
  .ADDR_WIDTH(ADDR_WIDTH)
) ftr (
  // ULPI clock and reset
  .ULPICLK(ULPICLK),
  .ULPIRSTB(ULPIRSTB),

  // Register Interface
  .WENB(WENB),
  .WADR(WADR),
  .WDAT(WDAT),
  .WBEN(WBEN),
  .RENB(RENB),
  .RADR(RADR),
  .RDAT(RDAT),

  // FTC Register signals
  .FM_INTERVAL(FM_INTERVAL),
  .FM_ENABLE(FM_ENABLE),
  .FM_ROLLOVER(FM_ROLLOVER),
  .FM_REMAINING(FM_REMAINING),
  .FM_RTOGGLE(FM_RTOGGLE),
  .FM_MODE(FM_MODE),
  .FM_NUMBER(FT_FMNUMBER)
);

// ----
// FraMe Counter
// --------------------------------------------------
sc_scbc_fmc fmc (
  // ULPI clock and reset
  .ULPICLK(ULPICLK),
  .ULPIRSTB(ULPIRSTB),

  // USB Port State signals
  .UPS_OPERATIONAL(UPS_OPERATIONAL),

  // FTC Register signals
  .FM_INTERVAL(FM_INTERVAL),
  .FM_ENABLE(FM_ENABLE),
  .FM_ROLLOVER(FM_ROLLOVER),
  .FM_REMAINING(FM_REMAINING),
  .FM_RTOGGLE(FM_RTOGGLE),
  .FM_MODE(FM_MODE),
  .FM_NUMBER(FT_FMNUMBER)
);
assign FT_1MS = FM_ROLLOVER;

endmodule
