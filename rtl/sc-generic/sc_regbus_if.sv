//-----------------------------------------------------------------------------
// Copyright 2023 Space Cubics, LLC
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
// Space Cubics Register Bus Interface
//-----------------------------------------------------------------------------

interface sc_regbus_if;
  // Write Channel
  logic [31:0] WADR;    // Write Address
  logic [9:0]  WTYP;    // Write Type
  logic [3:0]  WENB;    // Write Enable
  logic [31:0] WDAT;    // Write Data
  logic        WWAT;    // Write Wait
  logic        WERR;    // Write Error

  // Read Channel
  logic [31:0] RADR;    // Read Address
  logic [9:0]  RTYP;    // Read Type
  logic        RENB;    // Read Enable
  logic [31:0] RDAT;    // Read Data
  logic        RWAT;    // Read Wait
  logic        RERR;    // Read Error

  // Bus IP
  modport busip (
    output WADR,
    output WTYP,
    output WENB,
    output WDAT,
    input  WWAT,
    input  WERR,

    output RADR,
    output RTYP,
    output RENB,
    input  RDAT,
    input  RWAT,
    input  RERR
  );

  // Register
  modport regif (
    input  WADR,
    input  WTYP,
    input  WENB,
    input  WDAT,
    output WWAT,
    output WERR,

    input  RADR,
    input  RTYP,
    input  RENB,
    output RDAT,
    output RWAT,
    output RERR
  );
endinterface
