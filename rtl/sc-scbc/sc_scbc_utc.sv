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
//  Module: USB Transaction Controller (sc_scbc_utc)
//-----------------------------------------------------------------------------

module sc_scbc_utc import sc_usb_pkg::*; (
  // ULPI clock and reset
  input ULPICLK,
  input ULPIRSTB,

  // USB port state signal
  input UPS_OPERATIONAL,

  // Frame timing signal
  input FT_1MS,

  // USB transaction control signals
  output logic PKT_TX_START,
  input PKT_TX_COMP,
  output logic [3:0] PKT_TX_PID,
  output logic [6:0] PKT_TX_ADR,
  output logic [3:0] PKT_TX_EPN,
  output logic [7:0] PKT_TX_DAT,
  output logic [10:0] PKT_TX_NUM
);

typedef enum logic [1:0] {
             utcIdle,
             utcSof,
             utcWait
} utcState_t;
utcState_t utcState;

always_ff @ (posedge ULPICLK) begin
  if (!ULPIRSTB) begin
    PKT_TX_START <= 1'b0;
    PKT_TX_PID <= 4'h0;
    PKT_TX_ADR <= 7'h00;
    PKT_TX_EPN <= 4'h0;
    PKT_TX_DAT <= 8'h00;
    PKT_TX_NUM <= 0;
    utcState <= utcIdle;
  end
  else begin

    // Idle state
    // ---------------------------
    if (utcState == utcIdle) begin
      if (UPS_OPERATIONAL & FT_1MS)
        utcState <= utcSof;
    end

    // SOF state
    // ---------------------------
    else if (utcState == utcSof) begin
      PKT_TX_START <= 1'b1;
      PKT_TX_PID <= tokenSof;
      PKT_TX_ADR <= 7'h00;
      PKT_TX_EPN <= 4'h0;
      PKT_TX_DAT <= 8'h00;
      PKT_TX_NUM <= 0;
      utcState <= utcWait;
    end

    // Transaction wait state
    // ---------------------------
    else if (utcState == utcWait) begin
      if (PKT_TX_COMP) begin
        PKT_TX_START <= 1'b0;
        PKT_TX_PID <= 4'h0;
        PKT_TX_ADR <= 7'h00;
        PKT_TX_EPN <= 4'h0;
        PKT_TX_DAT <= 8'h00;
        PKT_TX_NUM <= 0;
        utcState <= utcIdle;
      end
    end
  end
end

endmodule
