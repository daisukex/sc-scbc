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
//  Module: USB Package
//-----------------------------------------------------------------------------

`ifndef _SC_USB_PKG_
`define _SC_USB_PKG_

package sc_usb_pkg;

// USB Configuration
typedef enum logic {
             hostMode = 0,
             deviceMode
} usbConfig_t;

// ----
// ULPI PID Types: USB spec 8.3.1
// --------------------------------------------------
typedef enum logic [3:0] {
             specialReseved = 4'b0000,
             tokenOut       = 4'b0001,
             handshakeAck   = 4'b0010,
             dataData0      = 4'b0011,
             specialPing    = 4'b0100,
             tokenSof       = 4'b0101,
             handshakeNyet  = 4'b0110,
             dataData2      = 4'b0111,
             specialSplit   = 4'b1000,
             tokenIn        = 4'b1001,
             handshakeNak   = 4'b1010,
             dataData1      = 4'b1011,
             specialPre     = 4'b1100,
             tokenSetup     = 4'b1101,
             handshakeStall = 4'b1110,
             dataMdata      = 4'b1111
} pidType_t;

endpackage: sc_usb_pkg

`endif
