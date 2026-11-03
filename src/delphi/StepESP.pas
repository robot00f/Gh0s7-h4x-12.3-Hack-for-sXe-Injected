unit StepESP;

{ ==============================================================================
  SEPARATE MODULE: STEPESP (SOUND ESP / FOOTSTEPS)
  Decompiled directly from payload_memory_dump.bin
  ============================================================================== }

interface

uses
  Windows, SysUtils;

type
  TVector3D = packed record
    X, Y, Z: Single;
  end;

  TVector2D = packed record
    X, Y: Single;
  end;

  TStepEntry = packed record
    Origin: TVector3D; // RVA 0x2D414
    dwTime: DWORD;     // RVA 0x2D420
  end;

const
  MAX_STEP_ENTRIES = 32;

var
  g_StepBuffer: array[0..MAX_STEP_ENTRIES - 1] of TStepEntry;
  g_iStepIndex: Integer = 0;    // RVA 0x2B068 (0x04C7B068)
  g_iStepESP_Mode: Integer = 0; // 0=Off, 1=Text, 2=Circle (RVA 0x2E5EC)

procedure Hooked_PlaySoundByName(entindex: Integer; const szSample: PChar; 
  volume, attenuation: Single; fFlags, pitch: Integer; pOrigin: ^TVector3D); cdecl;
procedure DrawStepESP(iScreenWidth, iScreenHeight: Integer);

implementation

function WorldToScreen(const World: TVector3D; var Screen: TVector2D): Boolean; external 'hw.dll';
procedure DrawString(x, y: Integer; const text: PChar; r, g, b: Integer); external 'hw.dll';
procedure DrawCircle(x, y, radius, r, g, b: Integer); external 'hw.dll';

function VectorDistance(const A, B: TVector3D): Single;
begin
  Result := Sqrt(Sqr(A.X - B.X) + Sqr(A.Y - B.Y) + Sqr(A.Z - B.Z));
end;

// Sound Hook: RVA 0x21190
procedure Hooked_PlaySoundByName(entindex: Integer; const szSample: PChar; 
  volume, attenuation: Single; fFlags, pitch: Integer; pOrigin: ^TVector3D); cdecl;
var
  SampleStr: string;
begin
  if (pOrigin = nil) or (szSample = nil) then Exit;
  SampleStr := LowerCase(string(szSample));

  // Filters 'step' or 'dirt' (RVA 0x212B4 and 0x212BC)
  if (Pos('step', SampleStr) > 0) or (Pos('dirt', SampleStr) > 0) then
  begin
    Inc(g_iStepIndex);
    if g_iStepIndex >= MAX_STEP_ENTRIES then
      g_iStepIndex := 0;

    g_StepBuffer[g_iStepIndex].Origin := pOrigin^;
    g_StepBuffer[g_iStepIndex].dwTime := GetTickCount;
  end;
end;

// Rendering: RVA 0x22108
procedure DrawStepESP(iScreenWidth, iScreenHeight: Integer);
var
  i: Integer;
  dwNow, dwDelta: DWORD;
  vScreen: TVector2D;
  flDistance, flRadius: Single;
  vLocalOrigin: TVector3D;
begin
  if g_iStepESP_Mode = 0 then Exit;
  dwNow := GetTickCount;
  FillChar(vLocalOrigin, SizeOf(vLocalOrigin), 0);

  for i := 0 to MAX_STEP_ENTRIES - 1 do
  begin
    // Timeout 300 ms (RVA 0x22137)
    dwDelta := dwNow - g_StepBuffer[i].dwTime;
    if dwDelta >= 300 then Continue;

    if not WorldToScreen(g_StepBuffer[i].Origin, vScreen) then Continue;
    if (vScreen.X <= 0) or (vScreen.Y <= 0) or 
       (vScreen.X >= iScreenWidth) or (vScreen.Y >= iScreenHeight) then Continue;

    // Mode 1: 'step' text (RVA 0x221AC)
    if g_iStepESP_Mode = 1 then
      DrawString(Round(vScreen.X), Round(vScreen.Y), 'step', 255, 255, 255)
    // Mode 2: Scaled circle (RVA 0x221E0)
    else if g_iStepESP_Mode = 2 then
    begin
      flDistance := VectorDistance(vLocalOrigin, g_StepBuffer[i].Origin);
      flRadius := 150.0 / (flDistance / 22.0); // RVA 0x22280 and 0x22284
      if flRadius < 2.0 then flRadius := 2.0;
      if flRadius > 40.0 then flRadius := 40.0;
      DrawCircle(Round(vScreen.X), Round(vScreen.Y), Round(flRadius), 255, 255, 255);
    end;
  end;
end;

end.
