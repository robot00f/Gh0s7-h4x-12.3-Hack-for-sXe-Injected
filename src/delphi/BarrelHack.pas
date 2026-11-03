unit BarrelHack;

{ ==============================================================================
  SEPARATE MODULE: BARRELHACK (3D Forward Laser Beam)
  Original RVA in Dump: 0x217B0 (0x04C717B0)
  ============================================================================== }

interface

uses
  Windows, Types, Config;

type
  TfnR_BeamPoints = procedure(start, endpos: PVector3D; modelIndex: Integer; 
    life, width, amplitude, brightness, speed: Single; 
    startFrame: Integer; framerate, r, g, b: Single); cdecl;

procedure DrawBarrelHack(entIndex: Integer; const Origin, Angles: TVector3D; 
  iBeamModelIndex: Integer; pfnBeam: TfnR_BeamPoints);

implementation

function GetPlayerTeam(index: Integer): Integer; external 'hw.dll';

procedure DrawBarrelHack(entIndex: Integer; const Origin, Angles: TVector3D; 
  iBeamModelIndex: Integer; pfnBeam: TfnR_BeamPoints);
var
  vStart, vEnd, vForward: TVector3D;
  sp, cp, sy, cy, rad: Single;
  iTeam: Integer;
  r, g, b: Single;
begin
  if (g_Config.Barrelhack = 0) or not Assigned(pfnBeam) then
    Exit;

  // Eye level origin
  vStart := Origin;
  vStart.Z := vStart.Z + 60.0;

  // Convert Pitch and Yaw to Forward Vector
  rad := PI / 180.0;
  sp := Sin(Angles.X * rad); cp := Cos(Angles.X * rad);
  sy := Sin(Angles.Y * rad); cy := Cos(Angles.Y * rad);

  vForward.X := cp * cy;
  vForward.Y := cp * sy;
  vForward.Z := -sp;

  // Project 8192 units forward (RVA 0x217A5)
  vEnd.X := vStart.X + vForward.X * 8192.0;
  vEnd.Y := vStart.Y + vForward.Y * 8192.0;
  vEnd.Z := vStart.Z + vForward.Z * 8192.0;

  iTeam := GetPlayerTeam(entIndex);
  if iTeam = 1 then begin r := 255.0; g := 0.0; b := 0.0; end       // Terrorist = Red (RVA 0x217EA)
  else if iTeam = 2 then begin r := 0.0; g := 0.0; b := 255.0; end  // CT = Blue (RVA 0x21836)
  else begin r := 255.0; g := 255.0; b := 255.0; end;

  pfnBeam(@vStart, @vEnd, iBeamModelIndex, 0.02, 2.0, 0.0, 255.0, 0.0, 0, 30.0, r, g, b);
end;

end.
