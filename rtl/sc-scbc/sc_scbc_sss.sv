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
//  Module: Slave Signal Synchronizer (sc_scbc_sss)
//-----------------------------------------------------------------------------

module sc_scbc_sss (
  // System bus clock and reset
  input SYSCLK,
  input SYSRSTB,

  // ULPI clock and reset
  input ULPICLK,
  input ULPIRSTB,

  // Register interface handshake
  input SYS_WENB,
  output SYS_WCOMP,
  input SYS_RENB,
  output SYS_RCOMP,

  // Register interface Write and Read enable
  output ULPI_WENB,
  output ULPI_RENB
);


// SYSCLK synchronous signals
logic regWrToggle;
logic regRdToggle;

logic syncRegWrCompToggle;
logic regWrCompToggleP;
logic syncRegRdCompToggle;
logic regRdCompToggleP;

// ULPICLK synchronous signals
logic syncRegWrToggle;
logic regWrToggleP;

logic syncRegRdToggle;
logic regRdToggleP;


// ----
// SYSCLK Domain Circuit
// --------------------------------------------------

always @ (posedge SYSCLK) begin
  if (!SYSRSTB) begin
    regWrToggle <= 1'b0;
    regRdToggle <= 1'b0;
  end
  else begin
    if (SYS_WENB)
      regWrToggle <= ~regWrToggle;
    if (SYS_RENB)
      regRdToggle <= ~regRdToggle;
  end
end

// Synchronous write complite
sclib_tmr_syncff # (
  .SYNCC(2),
  .SET1RST0(0)
) sync_wr_complite (
  .CLK(SYSCLK),
  .SRB(SYSRSTB),
  .DIN(regWrToggleP),
  .QOUT(syncRegWrCompToggle)
);

always @ (posedge SYSCLK) begin
  if (!SYSRSTB)
    regWrCompToggleP <= 1'b0;
  else
    regWrCompToggleP <= syncRegWrCompToggle;
end
assign SYS_WCOMP = syncRegWrCompToggle ^ regWrCompToggleP;


// Synchronous read complite
sclib_tmr_syncff # (
  .SYNCC(2),
  .SET1RST0(0)
) sync_rd_complite (
  .CLK(SYSCLK),
  .SRB(SYSRSTB),
  .DIN(regRdToggleP),
  .QOUT(syncRegRdCompToggle)
);

always @ (posedge SYSCLK) begin
  if (!SYSRSTB)
    regRdCompToggleP <= 1'b0;
  else
    regRdCompToggleP <= syncRegRdCompToggle;
end
assign SYS_RCOMP = syncRegRdCompToggle ^ regRdCompToggleP;

// ----
// ULPICLK Domain Circuit
// --------------------------------------------------

// Synchronous write enable
sclib_tmr_syncff # (
  .SYNCC(2),
  .SET1RST0(0)
) sync_wr_enable (
  .CLK(ULPICLK),
  .SRB(ULPIRSTB),
  .DIN(regWrToggle),
  .QOUT(syncRegWrToggle)
);

always @ (posedge ULPICLK) begin
  if (!ULPIRSTB)
    regWrToggleP <= 1'b0;
  else
    regWrToggleP <= syncRegWrToggle;
end
assign ULPI_WENB = syncRegWrToggle ^ regWrToggleP;


// Synchronous read enable
sclib_tmr_syncff # (
  .SYNCC(2),
  .SET1RST0(0)
) sync_rd_enable (
  .CLK(ULPICLK),
  .SRB(ULPIRSTB),
  .DIN(regRdToggle),
  .QOUT(syncRegRdToggle)
);

always @ (posedge ULPICLK) begin
  if (!ULPIRSTB)
    regRdToggleP <= 1'b0;
  else
    regRdToggleP <= syncRegRdToggle;
end
assign ULPI_RENB = syncRegRdToggle ^ regRdToggleP;

endmodule
