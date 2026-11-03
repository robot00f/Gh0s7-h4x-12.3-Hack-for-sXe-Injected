unit ESP;

{ ==============================================================================
  SEPARATE MODULE: ESP (BoxESP, NameESP, WeaponESP, DistanceESP)
  Original RVA in Dump: 0x224D0 (0x04C724D0)
  ============================================================================== }

interface

uses
  Windows, SysUtils, Types, Config, Math3D;

procedure DrawPlayerESP(iScreenWidth, iScreenHeight: Integer);

implementation

// Engine imports (hw.dll)
function WorldToScreen(const World: TVector3D; var Screen: TVector2D): Boolean; external 'hw.dll';
procedure DrawString(x, y: Integer; const text: PChar; r, g, b: Integer); external 'hw.dll';
procedure DrawBox2D(x, y, w, h, r, g, b: Integer); external 'hw.dll';
function GetEntityByIndex(index: Integer): Pointer; external 'hw.dll';
function GetPlayerTeam(index: Integer): Integer; external 'hw.dll';
function GetPlayerName(index: Integer): PChar; external 'hw.dll';
function GetPlayerWeapon(index: Integer): PChar; external 'hw.dll';
function GetLocalPlayerOrigin: TVector3D; external 'hw.dll';

procedure DrawPlayerESP(iScreenWidth, iScreenHeight: Integer);
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
  i, iHeight, iWidth, iLeft, iTopY, iTeam: Integer;
  pEnt: PEntityData;
  vBottom, vTop, vLocalOrigin: TVector3D;
  sBottom, sTop: TVector2D;
  r, g, b: Integer;
  szDist: string;
begin
  vLocalOrigin := GetLocalPlayerOrigin;

  // Loop over 32 players (1..32)
  for i := 1 to 32 do
  begin
    pEnt := PEntityData(GetEntityByIndex(i));
    if (pEnt = nil) or (pEnt^.IsDead <> 0) then
      Continue;

    vBottom := pEnt^.CurrentOrigin;
    vTop := vBottom;
    vTop.Z := vTop.Z + 72.0; // Standard Half-Life player model height

    if not WorldToScreen(vBottom, sBottom) or not WorldToScreen(vTop, sTop) then
      Continue;

    // Frustum clip
    if (sBottom.X <= 0) or (sBottom.Y <= 0) or 
       (sBottom.X >= iScreenWidth) or (sBottom.Y >= iScreenHeight) then
      Continue;

    iHeight := Round(sBottom.Y - sTop.Y);
    iWidth  := iHeight div 2;
    iLeft   := Round(sTop.X - (iWidth div 2));
    iTopY   := Round(sTop.Y);

    iTeam := GetPlayerTeam(i);
    if iTeam = 1 then begin r := 255; g := 0; b := 0; end       // Terrorist: Red
    else if iTeam = 2 then begin r := 0; g := 0; b := 255; end  // CT: Blue
    else begin r := 255; g := 255; b := 255; end;

    // A. Box ESP (RVA 0x224D4)
    if g_Config.BoxESP > 0 then
      DrawBox2D(iLeft, iTopY, iWidth, iHeight, r, g, b);

    // B. Name ESP (RVA 0x22516)
    if g_Config.NameESP = 1 then
      DrawString(Round(sTop.X), iTopY - 12, GetPlayerName(i), 255, 255, 255);

    // C. Weapon ESP (RVA 0x22558)
    if g_Config.WeaponESP = 1 then
      DrawString(Round(sTop.X), Round(sBottom.Y) + 2, GetPlayerWeapon(i), 255, 255, 0);

    // D. Distance ESP (RVA 0x225A8)
    if g_Config.DistanceESP = 1 then
    begin
      szDist := Format('%.0f m', [VectorDistance(vLocalOrigin, vBottom) / 39.37]);
      DrawString(Round(sTop.X), Round(sBottom.Y) + 14, PChar(szDist), 0, 255, 0);
    end;
  end;
end;

end.
