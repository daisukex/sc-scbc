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
//  Module: ULPI Packet Generator (sc_scbc_upg)
//-----------------------------------------------------------------------------

module sc_ulpi_upg import sc_usb_pkg::*; (
  // System Interface
  input ULPICLK,
  input ULPIRSTB,

  // USB Transaction Interface
  input PKT_TX_START,
  output logic PKT_TX_COMP,
  input [3:0] PKT_TX_PID,
  input [6:0] PKT_TX_ADR,
  input [3:0] PKT_TX_EPN,
  input [7:0] PKT_TX_DAT,
  input [10:0] PKT_TX_FMN,
  input [10:0] PKT_TX_NUM,

  // ULPI Protocol Engine Interface
  output logic TXD_REQ,
  input TXD_ACK,
  output logic [5:0] TXD_CPD,
  output logic TXD_VALID,
  input TXD_READY,
  output logic TXD_LAST,
  output logic [7:0] TXD_DATA
);

typedef struct packed {
  logic addr;
  logic endp;
  logic fmnum;
  logic data;
  logic tcrc;
  logic dcrc;
} pktFormat_t;

pktFormat_t pktFormat[logic [3:0]];
always_comb begin
  pktFormat[tokenOut]       = '{addr: 1, endp: 1, fmnum: 0, data: 0, tcrc: 1, dcrc: 0};
  pktFormat[tokenIn]        = '{addr: 1, endp: 1, fmnum: 0, data: 0, tcrc: 1, dcrc: 0};
  pktFormat[tokenSof]       = '{addr: 1, endp: 0, fmnum: 1, data: 0, tcrc: 1, dcrc: 0};
  pktFormat[tokenSetup]     = '{addr: 1, endp: 1, fmnum: 0, data: 0, tcrc: 1, dcrc: 0};
  pktFormat[dataData0]      = '{addr: 0, endp: 0, fmnum: 0, data: 1, tcrc: 0, dcrc: 1};
  pktFormat[dataData1]      = '{addr: 0, endp: 0, fmnum: 0, data: 1, tcrc: 0, dcrc: 1};
  pktFormat[dataData2]      = '{addr: 0, endp: 0, fmnum: 0, data: 1, tcrc: 0, dcrc: 1};
  pktFormat[dataMdata]      = '{addr: 0, endp: 0, fmnum: 0, data: 1, tcrc: 0, dcrc: 1};
  pktFormat[handshakeAck]   = '{addr: 0, endp: 0, fmnum: 0, data: 0, tcrc: 0, dcrc: 0};
  pktFormat[handshakeNak]   = '{addr: 0, endp: 0, fmnum: 0, data: 0, tcrc: 0, dcrc: 0};
  pktFormat[handshakeStall] = '{addr: 0, endp: 0, fmnum: 0, data: 0, tcrc: 0, dcrc: 0};
  pktFormat[handshakeNyet]  = '{addr: 0, endp: 0, fmnum: 0, data: 0, tcrc: 0, dcrc: 0};
  pktFormat[specialPre]     = '{addr: 1, endp: 1, fmnum: 0, data: 0, tcrc: 0, dcrc: 0};
  pktFormat[specialSplit]   = '{addr: 1, endp: 1, fmnum: 0, data: 0, tcrc: 0, dcrc: 0};
  pktFormat[specialPing]    = '{addr: 1, endp: 1, fmnum: 0, data: 0, tcrc: 0, dcrc: 0};
  pktFormat[specialReseved] = '{addr: 0, endp: 0, fmnum: 0, data: 0, tcrc: 0, dcrc: 0};
end

// ----
// ULPI Packet Generator State Machine
// --------------------------------------------------
typedef enum logic [2:0] {
             txIdle,
             txAddrEndp,
             txFmnum,
             txData,
             txCRC16,
             txEndWait
} upgState_t;
upgState_t upgState;

always @ (posedge ULPICLK or negedge ULPIRSTB) begin
  if (!ULPIRSTB) begin
    TXD_REQ <= 1'b0;
    TXD_CPD <= 6'h0;
    TXD_VALID <= 1'b0;
    TXD_LAST <= 1'b0;
    PKT_TX_COMP <= 1'b0;
    upgState <= txIdle;
  end
  else begin
    PKT_TX_COMP <= 1'b0;

    // txIdle State
    // ----------------
    if (upgState == txIdle) begin
      if (PKT_TX_START & !PKT_TX_COMP) begin
        TXD_REQ <= 1'b1;
        TXD_CPD <= PKT_TX_PID;

        // Send Token Packet (OUT/IN/SETUP)
        if (pktFormat[PKT_TX_PID].addr & pktFormat[PKT_TX_PID].endp) begin
          TXD_DATA <= {PKT_TX_EPN[0], PKT_TX_ADR};
          upgState <= txAddrEndp;
        end
        // Send Token Packet (SOF)
        else if (pktFormat[PKT_TX_PID].fmnum) begin
          TXD_DATA <= PKT_TX_FMN[7:0];
          upgState <= txFmnum;
        end
        TXD_VALID <= 1'b1;
      end
    end

    // txAddrEndp State
    // ----------------
    // Transmit ADDR/ENDP field for Token(OUT/IN/SETUP) Packet
    else if (upgState == txAddrEndp) begin
      if (TXD_VALID & TXD_READY) begin
        TXD_DATA <= {CRC5({PKT_TX_EPN, PKT_TX_ADR}), PKT_TX_EPN[3:1]};
        TXD_VALID <= 1'b1;
        TXD_LAST <= 1'b1;
        upgState <= txEndWait;
      end
    end

    // txFmnum State
    // ----------------
    // Transmit Frame Number field for Token(SOF) Packet
    else if (upgState == txFmnum) begin
      if (TXD_VALID & TXD_READY) begin
        TXD_DATA <= {CRC5(PKT_TX_FMN), PKT_TX_FMN[10:8]};
        TXD_VALID <= 1'b1;
        TXD_LAST <= 1'b1;
        upgState <= txEndWait;
      end
    end

    // txEndWait State
    // ----------------
    // Transmit completion wait state
    else if (upgState == txEndWait) begin
      if (TXD_VALID & TXD_READY) begin
        TXD_VALID <= 1'b0;
        TXD_LAST <= 1'b0;
      end
      else if (TXD_ACK) begin
        PKT_TX_COMP <= 1'b1;
        TXD_REQ <= 1'b0;
        upgState <= txIdle;
      end
    end
  end
end

// ----
// Generate CRC-5
// --------------------------------------------------
function [0:4] CRC5;
  input [10:0] data;
  integer bc;
begin
  // initialize
  CRC5 = 0;

  // Calc CRC5 (X^5 + X^2 + 1)
  for (bc=0; bc<11; bc=bc+1)
    CRC5 = {CRC5[4] ^ data[bc], CRC5[0], ~(CRC5[1] ^ (CRC5[4] ^ data[bc])), CRC5[2], CRC5[3]};
end
endfunction

endmodule
