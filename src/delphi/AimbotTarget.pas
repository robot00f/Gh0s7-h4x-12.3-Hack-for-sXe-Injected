unit AimbotTarget;

{ ==============================================================================
  SEPARATE MODULE: AIMBOT TARGET SEARCH & FOV CHECK
  Original RVA in Dump: 0x24CE0 (0x04C74CE0)
  ============================================================================== }

interface

uses
  Windows, SysUtils, Math, Types, Config;

function FindBestTarget(iScreenWidth, iScreenHeight: Integer; var vOutAngles: TVector3D): Boolean;

implementation

function WorldToScreen(const World: TVector3D; var Screen: TVector2D): Boolean; external 'hw.dll';
function GetEntityByIndex(index: Integer): Pointer; external 'hw.dll';
function GetPlayerTeam(index: Integer): Integer; external 'hw.dll';
function GetPlayerBone(pEnt: Pointer; bone: Integer): TVector3D; external 'hw.dll';
function GetLocalPlayerOrigin: TVector3D; external 'hw.dll';

function FindBestTarget(iScreenWidth, iScreenHeight: Integer; var vOutAngles: TVector3D): Boolean;
type
  PEntityData = ^TEntityData;
  TEntityData = packed record
    Index: Integer;
    Player: Integer;
    BaselineOrigin: TVector3D;
    CurrentOrigin: TVector3D;
    Angles: TVector3D;
    Padding: array[0..$360 - SizeOf(TVector3D)*3 - 9] of Byte;
    IsDead: Integer; // Offset $360: 0=Alive, <>0=Dead (RVA 0x24D8B)
  end;
var
  flCenterX, flCenterY, flMinDist, flDistX, flDistY, flDist, flHyp: Single;
  i, iBestIndex, iBone: Integer;
  pEnt: PEntityData;
  vBonePos, vLocalEye, vDir: TVector3D;
  vScreen: TVector2D;
begin
  Result := False;
  flCenterX := iScreenWidth / 2.0;
  flCenterY := iScreenHeight / 2.0;
  flMinDist := 999999.0;
  iBestIndex := -1;

  for i := 1 to 32 do
  begin
    pEnt := PEntityData(GetEntityByIndex(i));
    if (pEnt = nil) or (pEnt^.IsDead <> 0) then // RVA 0x24D8B
      Continue;

    // Friendly Fire Check
    if (g_Config.AimTeam = 0) and (GetPlayerTeam(i) = GetPlayerTeam(0)) then
      Continue;

    // Bone: 1 = Head (bone 8), 2 = Chest (bone 7) (RVA 0x23BF5)
    iBone := 8;
    if g_Config.AimSpot = 2 then iBone := 7;
    vBonePos := GetPlayerBone(pEnt, iBone);

    if not WorldToScreen(vBonePos, vScreen) then
      Continue;

    // 2D Screen-space FOV Box Check (RVA 0x24D04..0x24D85)
    if (vScreen.X < flCenterX - g_Config.AimFov) or (vScreen.X > flCenterX + g_Config.AimFov) or
       (vScreen.Y < flCenterY - g_Config.AimFov) or (vScreen.Y > flCenterY + g_Config.AimFov) then
      Continue;

    flDistX := vScreen.X - flCenterX;
    flDistY := vScreen.Y - flCenterY;
    flDist := Sqrt(flDistX * flDistX + flDistY * flDistY);

    if flDist < flMinDist then
    begin
      flMinDist := flDist;
      iBestIndex := i;

      vLocalEye := GetLocalPlayerOrigin;
      vLocalEye.Z := vLocalEye.Z + 64.0; // Local view offset

      vDir.X := vBonePos.X - vLocalEye.X;
      vDir.Y := vBonePos.Y - vLocalEye.Y;
      vDir.Z := vBonePos.Z - vLocalEye.Z;
      flHyp := Sqrt(vDir.X * vDir.X + vDir.Y * vDir.Y);

      vOutAngles.X := -ArcTan2(vDir.Z, flHyp) * (180.0 / PI);
      vOutAngles.Y := ArcTan2(vDir.Y, vDir.X) * (180.0 / PI);
      vOutAngles.Z := 0.0;
      Result := True;
    end;
  end;
end;

end.
