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

module sclib_tmr_syncff # (
  parameter SYNCC = 2,   // Synchronizer F/F Count
  parameter SET1RST0 = 1'b0 // SetReset Value
) (
  input DIN,
  input CLK,
  input SRB,
  output reg QOUT
);

(* dont_touch = "yes" *) reg [SYNCC-1:0] sync_0;
(* dont_touch = "yes" *) reg [SYNCC-1:0] sync_1;
(* dont_touch = "yes" *) reg [SYNCC-1:0] sync_2;

always @ (posedge CLK or negedge SRB) begin
  if (!SRB) begin
    sync_0 <= {SYNCC{SET1RST0}};
    sync_1 <= {SYNCC{SET1RST0}};
    sync_2 <= {SYNCC{SET1RST0}};
  end
  else begin
    sync_0 <= {sync_0[SYNCC-2:0], DIN};
    sync_1 <= {sync_1[SYNCC-2:0], DIN};
    sync_2 <= {sync_2[SYNCC-2:0], DIN};
  end
end

always @ (*) begin
  case ({sync_2[SYNCC-1], sync_1[SYNCC-1], sync_0[SYNCC-1]})
    3'b011:  QOUT = 1'b1;
    3'b101:  QOUT = 1'b1;
    3'b110:  QOUT = 1'b1;
    3'b111:  QOUT = 1'b1;
    default: QOUT = 1'b0;
  endcase
end

endmodule
