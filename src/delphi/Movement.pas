unit Movement;

{ ==============================================================================
  SEPARATE MODULE: MOVEMENT (Bhop, FastRun, Speedhack)
  Original RVAs in Dump:
    - Bhop:      RVA 0x252BF (0x04C752BF)
    - FastRun:   RVA 0x25131 (0x04C75131)
    - Speedhack: RVA 0x24754 (0x04C74754)
  ============================================================================== }

interface

uses
  Windows, Types, Config;

const
  FL_ONGROUND = (1 shl 9); // $200 flag in GoldSrc

procedure ProcessBhop(cmd: PUserCmd);
procedure ProcessFastRun(cmd: PUserCmd);
procedure ProcessSpeedhack(cmd: PUserCmd);

implementation

function GetLocalPlayerFlags: Integer; external 'hw.dll';

var
  bStrafeToggle: Boolean = False;

procedure ProcessBhop(cmd: PUserCmd);
var
  flags: Integer;
begin
  if (g_Config.Bhop <> 1) or (cmd = nil) then
    Exit;

  if (cmd^.buttons and IN_JUMP) <> 0 then
  begin
    flags := GetLocalPlayerFlags;
    if (flags and FL_ONGROUND) = 0 then
      cmd^.buttons := cmd^.buttons and not IN_JUMP;
  end;
end;

procedure ProcessFastRun(cmd: PUserCmd);
var
  flags: Integer;
begin
  if (g_Config.FastRun <> 1) or (cmd = nil) then
    Exit;

  flags := GetLocalPlayerFlags;
  if (flags and FL_ONGROUND) = 0 then
    Exit;

  if (cmd^.buttons and IN_FORWARD) <> 0 then
  begin
    bStrafeToggle := not bStrafeToggle;
    if bStrafeToggle then
      cmd^.sidemove := 250.0
    else
      cmd^.sidemove := -250.0;
  end;
end;

procedure ProcessSpeedhack(cmd: PUserCmd);
var
  scaledMsec: Cardinal;
begin
  if (g_Config.Speedhack <= 1) or (cmd = nil) then
    Exit;

  scaledMsec := cmd^.msec * g_Config.Speedhack;
  if scaledMsec > 255 then
    scaledMsec := 255;
  cmd^.msec := Byte(scaledMsec);
end;

end.
