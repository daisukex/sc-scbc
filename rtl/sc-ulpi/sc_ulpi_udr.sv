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
//  Module: ULPI Data Receiver (sc_scbc_udr)
//-----------------------------------------------------------------------------

module sc_ulpi_udr
  import sc_usb_pkg::*;
  import sc_ulpi_pkg::*;
(
  // System Interface
  input ULPICLK,
  input ULPIRSTB,

  // Receive Data Interface
  input RXD_CMD_VALID,
  input RXD_DATA_VALID,
  input [7:0] ULPI_DATA,

  // USB Event
  output logic ULPI_CSC,         // Connect Status Change
  output logic [1:0] ULPI_CCS    // Current Connect Status
);

rxCmd_s rxCmd, rxCmd_1p;         // Receive Command Byte

always @ (posedge ULPICLK or negedge ULPIRSTB) begin
  if (!ULPIRSTB) begin
    rxCmd <= '{lineState: 2'b00, vbusState: 2'b00, rxEvent: hostDiscon, id: 1'b0, altInt: 1'b0};
    rxCmd_1p <= '{lineState: 2'b00, vbusState: 2'b00, rxEvent: hostDiscon, id: 1'b0, altInt: 1'b0};
  end
  else begin
    rxCmd_1p = rxCmd;

    // Update receive command
    if (RXD_CMD_VALID)
      rxCmd = rxCmd_s'(ULPI_DATA);
  end
end

always @ (posedge ULPICLK or negedge ULPIRSTB) begin
  if (!ULPIRSTB) begin
    ULPI_CCS <= 2'b00;
    ULPI_CSC <= 1'b0;
  end
  else begin
    ULPI_CSC <= 1'b0;

    // Receive Comand Byte changes
    if (rxCmd_1p != rxCmd) begin

      // RxEvent changes
      if (rxCmd_1p.rxEvent != rxCmd.rxEvent) begin
        // Connect -> Disconnect
        if (ULPI_CCS[0] & rxCmd.rxEvent == hostDiscon) begin
          ULPI_CCS <= 2'b00;
          ULPI_CSC <= 1'b1;
        end
        // Disconnect -> Connect
        else if (!ULPI_CCS[0] & rxCmd.rxEvent != hostDiscon) begin
          ULPI_CCS[0] <= 1'b1;
          ULPI_CSC <= 1'b1;
          if (rxCmd.lineState == 2'b10)
            ULPI_CCS[1] <= 1'b1;
          else
            ULPI_CCS[1] <= 1'b0;
        end
      end
    end
  end
end

endmodule
