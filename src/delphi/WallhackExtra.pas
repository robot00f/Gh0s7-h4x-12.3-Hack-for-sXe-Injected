unit WallhackExtra;

{ ==============================================================================
  SEPARATE MODULE: ADVANCED WALLHACK & ENTITY ESP
  (SimpleWall, Niggers/BlackModels, EntityESP, AimThruWall)
  Original RVAs in Dump:
    - SimpleWall:  RVA 0x1F27D (0x04C6F27D) -> 0x04C7E5D0
    - Niggers:     RVA 0x1F3EC (0x04C6F3EC) -> 0x04C7E5F0 (Silhouette Models)
    - EntityESP:   RVA 0x1FB50 (0x04C6FB50) -> 0x04C7E658
    - AimThruWall: RVA 0x20084 (0x04C70084) -> 0x04C7E638
  ============================================================================== }

interface

uses
  Windows, SysUtils, Types, Config;

const
  GL_DEPTH_TEST = $0B71;
  GL_TEXTURE_2D = $0DE1;

procedure BeginSimpleWallhack(isPlayerModel: Boolean);
procedure EndSimpleWallhack(isPlayerModel: Boolean);
procedure ApplyModelShader(isPlayerModel: Boolean);
procedure RestoreModelShader(isPlayerModel: Boolean);
procedure DrawEntityESP(iScreenWidth, iScreenHeight: Integer);
function CanPenetrateWall(const vStart, vTarget: TVector3D; pLocalEnt, pTargetEnt: Pointer): Boolean;

implementation

{ OpenGL Functions }
procedure glDepthRange(zNear, zFar: Double); stdcall; external 'opengl32.dll';
procedure glEnable(cap: Cardinal); stdcall; external 'opengl32.dll';
procedure glDisable(cap: Cardinal); stdcall; external 'opengl32.dll';
procedure glColor3ub(red, green, blue: Byte); stdcall; external 'opengl32.dll';

{ Engine / Client Helpers }
function WorldToScreen(const WorldPos: TVector3D; var ScreenPos: TVector2D): Boolean; external 'hw.dll';
procedure DrawBox2D(x, y, w, h, r, g, b: Integer); external 'hw.dll';
procedure DrawString(x, y: Integer; text: PAnsiChar; r, g, b: Integer); external 'hw.dll';

type
  PEntity = ^TEntity;
  TEntity = packed record
    Index: Integer;
    Player: Integer;
    BaselineOrigin: TVector3D;
    CurrentOrigin: TVector3D;
    Angles: TVector3D;
    ModelName: PAnsiChar;
  end;

  PTrace = ^TTrace;
  TTrace = packed record
    AllSolid: Integer;
    StartSolid: Integer;
    InOpen: Integer;
    InWater: Integer;
    Fraction: Single;
    EndPos: TVector3D;
    PlaneNormal: array[0..2] of Single;
    PlaneDist: Single;
    HitGroup: Integer;
    Ent: Pointer;
  end;

function GetEntityByIndex(index: Integer): PEntity; external 'hw.dll';
procedure EngineTraceLine(const start, endpos: TVector3D; flags: Integer; skipEnt: Pointer; tr: PTrace); external 'hw.dll';

{ -----------------------------------------------------------------------------
  1. SIMPLE WALLHACK (Depth Range Modification @ RVA 0x1F27D)
  ----------------------------------------------------------------------------- }
procedure BeginSimpleWallhack(isPlayerModel: Boolean);
begin
  if (g_Config.SimpleWall = 1) and isPlayerModel then
  begin
    glDepthRange(0.0, 0.45);
    glDisable(GL_DEPTH_TEST);
  end;
end;

procedure EndSimpleWallhack(isPlayerModel: Boolean);
begin
  if (g_Config.SimpleWall = 1) and isPlayerModel then
  begin
    glDepthRange(0.0, 1.0);
    glEnable(GL_DEPTH_TEST);
  end;
end;

{ -----------------------------------------------------------------------------
  2. UNLIT SILHOUETTE MODELS (RVA 0x1F3EC)
  ----------------------------------------------------------------------------- }
procedure ApplyModelShader(isPlayerModel: Boolean);
begin
  if (g_Config.Niggers = 1) and isPlayerModel then
  begin
    glDisable(GL_TEXTURE_2D);
    glColor3ub(0, 0, 0);
  end;
end;

procedure RestoreModelShader(isPlayerModel: Boolean);
begin
  if (g_Config.Niggers = 1) and isPlayerModel then
  begin
    glEnable(GL_TEXTURE_2D);
    glColor3ub(255, 255, 255);
  end;
end;

{ -----------------------------------------------------------------------------
  3. GROUND ENTITY ESP (Weapons, C4, Hostages @ RVA 0x1FB50)
  ----------------------------------------------------------------------------- }
procedure DrawEntityESP(iScreenWidth, iScreenHeight: Integer);
var
  i: Integer;
  ent: PEntity;
  sName: AnsiString;
  sLabel: AnsiString;
  r, g, b: Integer;
  sPos: TVector2D;
begin
  if g_Config.EntityESP = 0 then
    Exit;

  // Non-player entities occupy indices 33 to 256 in GoldSrc
  for i := 33 to 255 do
  begin
    ent := GetEntityByIndex(i);
    if (ent = nil) or (ent^.ModelName = nil) or (ent^.ModelName^ = #0) then
      Continue;

    sName := AnsiString(ent^.ModelName);
    sLabel := '';
    r := 255; g := 255; b := 255;

    // Identify dropped C4 Bomb
    if Pos('w_c4', sName) > 0 then
    begin
      sLabel := '[C4 BOMB]';
      r := 255; g := 50; b := 50;
    end
    // Identify Hostages
    else if Pos('hostage', sName) > 0 then
    begin
      sLabel := '[HOSTAGE]';
      r := 50; g := 255; b := 50;
    end
    // Identify Dropped Weapons
    else if Pos('models/w_', sName) > 0 then
    begin
      sLabel := Copy(sName, 10, Length(sName)); // Strip prefix
      r := 255; g := 215; b := 0; // Gold
    end;

    if sLabel <> '' then
    begin
      if WorldToScreen(ent^.CurrentOrigin, sPos) then
      begin
        if (sPos.X > 0) and (sPos.Y > 0) and (sPos.X < iScreenWidth) and (sPos.Y < iScreenHeight) then
        begin
          DrawBox2D(Round(sPos.X) - 2, Round(sPos.Y) - 2, 4, 4, r, g, b);
          DrawString(Round(sPos.X) + 4, Round(sPos.Y) - 4, PAnsiChar(sLabel), r, g, b);
        end;
      end;
    end;
  end;
end;

{ -----------------------------------------------------------------------------
  4. AUTOWALL PENETRATION CHECK (RVA 0x20084)
  ----------------------------------------------------------------------------- }
function CanPenetrateWall(const vStart, vTarget: TVector3D; pLocalEnt, pTargetEnt: Pointer): Boolean;
var
  tr, trReverse: TTrace;
  vWallEntry, vWallExit: TVector3D;
  dx, dy, dz, flWallThickness: Single;
begin
  EngineTraceLine(vStart, vTarget, 0, pLocalEnt, @tr);

  // Direct line of sight: no wall in between
  if (tr.Fraction >= 1.0) or (tr.Ent = pTargetEnt) then
  begin
    Result := True;
    Exit;
  end;

  // If Autowall is disabled, wall blocks aimbot
  if g_Config.AimThruWall = 0 then
  begin
    Result := False;
    Exit;
  end;

  vWallEntry := tr.EndPos;
  EngineTraceLine(vTarget, vStart, 0, pTargetEnt, @trReverse);
  vWallExit := trReverse.EndPos;

  dx := vWallExit.X - vWallEntry.X;
  dy := vWallExit.Y - vWallEntry.Y;
  dz := vWallExit.Z - vWallEntry.Z;
  flWallThickness := Sqrt(dx * dx + dy * dy + dz * dz);

  // Standard penetration limit: max 18 units of wall penetration
  Result := (flWallThickness <= 18.0);
end;

end.
