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
//  Module: Interrupt Signal Synchronizer (sc_scbc_sss)
//-----------------------------------------------------------------------------

module sc_scbc_iss (
  // System bus clock and reset
  input SYSCLK,
  input SYSRSTB,

  // Interrupt asynchronous input signal
  input UPC_ISR,

  // Interrupt Synchronus output signal
  output UPC_ISR_SYSCLK
);

// Synchronus UPC_ISR signal
sclib_tmr_syncff # (
  .SYNCC(2),
  .SET1RST0(0)
) sync_upcisr (
  .CLK(SYSCLK),
  .SRB(SYSRSTB),
  .DIN(UPC_ISR),
  .QOUT(UPC_ISR_SYSCLK)
);

endmodule
