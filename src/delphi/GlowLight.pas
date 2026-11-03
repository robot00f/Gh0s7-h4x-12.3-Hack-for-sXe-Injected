unit GlowLight;

{ ==============================================================================
  SEPARATE MODULE: GLOW & DYNAMIC LIGHTS
  (LocalGlow, PlayerGlow, PlayerLight, GlowEnts, GlowNades)
  Original RVAs in Dump:
    - LocalGlow:  RVA 0x22313 (0x04C72313)
    - PlayerGlow: RVA 0x2236C (0x04C7236C)
  ============================================================================== }

interface

uses
  Windows, Types, Config;

const
  kRenderFxGlowShell = 19; // $13 in dump at RVA 0x2231C

procedure ApplyEntityGlow(pEnt: Pointer; isLocalPlayer: Boolean);
procedure ApplyDynamicLight(key: Integer; const Origin: TVector3D; r, g, b: Integer; radius: Single);

implementation

function GetPlayerTeam(index: Integer): Integer; external 'hw.dll';

type
  PEntityGlow = ^TEntityGlow;
  TEntityGlow = packed record
    Index: Integer;
    Player: Integer;
    BaselineOrigin: TVector3D;
    CurrentOrigin: TVector3D;
    Angles: TVector3D;
    Padding: array[0..$2FC - SizeOf(TVector3D)*3 - 9] of Byte;
    RenderAmt: Integer;            // Offset $2FC: 5
    RenderColor: array[0..2] of Byte; // Offset $300: RGB ($32, $32, $FF)
    RenderFx: Byte;                // Offset $304: 19
  end;

  PDLight = ^TDLight;
  TDLight = packed record
    Origin: TVector3D;
    Radius: Single;
    Color: array[0..2] of Byte;
    Die: Single;
    Decay: Single;
    MinLight: Single;
    Key: Integer;
    Dark: Boolean;
  end;

function CL_AllocDlight(key: Integer): PDLight; cdecl; external 'hw.dll';

procedure ApplyEntityGlow(pEnt: Pointer; isLocalPlayer: Boolean);
var
  ent: PEntityGlow;
  bShouldGlow: Boolean;
  iTeam: Integer;
begin
  if pEnt = nil then
    Exit;

  ent := PEntityGlow(pEnt);
  bShouldGlow := (isLocalPlayer and (g_Config.LocalGlow = 1)) or
                 (not isLocalPlayer and (g_Config.PlayerGlow = 1));

  if bShouldGlow then
  begin
    ent^.RenderFx  := kRenderFxGlowShell;
    ent^.RenderAmt := 5;

    iTeam := GetPlayerTeam(ent^.Index);
    if iTeam = 1 then
    begin
      ent^.RenderColor[0] := 255;
      ent^.RenderColor[1] := 50;
      ent^.RenderColor[2] := 50;
    end
    else
    begin
      ent^.RenderColor[0] := 50;
      ent^.RenderColor[1] := 50;
      ent^.RenderColor[2] := 255;
    end;
  end;
end;

procedure ApplyDynamicLight(key: Integer; const Origin: TVector3D; r, g, b: Integer; radius: Single);
var
  dl: PDLight;
begin
  dl := CL_AllocDlight(key);
  if dl <> nil then
  begin
    dl^.Origin := Origin;
    dl^.Radius := radius;
    dl^.Color[0] := Byte(r);
    dl^.Color[1] := Byte(g);
    dl^.Color[2] := Byte(b);
    dl^.Die := 0.05;
    dl^.Decay := 300.0;
  end;
end;

end.
