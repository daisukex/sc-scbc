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
//  Module: FraMe Counter (sc_scbc_fmc)
//-----------------------------------------------------------------------------

module sc_scbc_fmc (
  // ULPI clock and reset
  input ULPICLK,
  input ULPIRSTB,

  input UPS_OPERATIONAL,

  // FTC Register
  input [15:0] FM_INTERVAL,
  input FM_ENABLE,
  output logic FM_ROLLOVER,
  output logic [15:0] FM_REMAINING,
  output logic FM_RTOGGLE,
  input FM_MODE,
  output logic [15:0] FM_NUMBER
);

// ----
// Frame Interval Counter (1 ms counter)
// --------------------------------------------------
always_ff @ (posedge ULPICLK) begin
  if (!ULPIRSTB) begin
    FM_REMAINING <= FM_INTERVAL;
    FM_RTOGGLE <= 1'b0;
  end
  else if (FM_ENABLE) begin
    if (FM_REMAINING == 0) begin
      FM_REMAINING <= FM_INTERVAL;
      FM_RTOGGLE <= ~FM_RTOGGLE;
    end
    else
      FM_REMAINING <= FM_REMAINING - 1;
  end
  else
    FM_REMAINING <= FM_INTERVAL;
end

always_ff @ (posedge ULPICLK) begin
  if (!ULPIRSTB)
    FM_ROLLOVER <= 1'b0;
  else if (FM_ENABLE & (FM_REMAINING == 1))
    FM_ROLLOVER <= 1'b1;
  else
    FM_ROLLOVER <= 1'b0;
end

// ----
// Frame Number Counter
// --------------------------------------------------
always_ff @ (posedge ULPICLK) begin
  if (!ULPIRSTB)
    FM_NUMBER <= 16'h0;
  else if (UPS_OPERATIONAL & FM_ROLLOVER) begin
    if (FM_MODE & FM_NUMBER == 16'h03F7)
      FM_NUMBER <= 16'h0;
    else
      FM_NUMBER <= FM_NUMBER + 1;
  end
end

endmodule
