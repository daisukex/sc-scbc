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
//  Module: PLL Lock Detect (sc_scbc_pld)
//-----------------------------------------------------------------------------

module sc_scbc_pld # (
  PLL_DETECT_CYCLE = 10
) (
  // System bus clock and reset
  input SYSCLK,
  input SYSRSTB,
  input ULPI_RSTB,
  input ULPI_PWRDWNB,

  // ULPI clock and reset
  input ULPICLK,
  output ULPIRSTB,

  // ULPI signal
  input DIR
);

logic pllWakeup;
always_ff @ (posedge SYSCLK) begin
  if (!SYSRSTB)
    pllWakeup <= 1'b0;
  else
    pllWakeup <= ULPI_PWRDWNB & ULPI_RSTB;
end

logic pllLock  = 1'b0;
logic sync_DIR;
logic [PLL_DETECT_CYCLE-1:0] dirP;
logic ulpiRstb = 0;
always_ff @ (posedge ULPICLK) begin
  if (pllWakeup) begin
    if (!pllLock) begin
      sync_DIR <= DIR;
      dirP <= {dirP[PLL_DETECT_CYCLE-2:0], sync_DIR};
      if (dirP[PLL_DETECT_CYCLE-1:PLL_DETECT_CYCLE-2] == 2'b00) begin
        pllLock <= 1'b1;
        ulpiRstb <= 1'b1;
      end
    end
  end
  else begin
    ulpiRstb <= 1'b0;
    pllLock <= 1'b0;
  end
end
assign ULPIRSTB = ulpiRstb;

endmodule
