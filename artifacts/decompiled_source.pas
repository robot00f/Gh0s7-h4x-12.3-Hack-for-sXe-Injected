unit Gh0s7H4x_Payload_Core;
{ ==============================================================================
  FORENSIC RECONSTRUCTION & DECOMPILATION: Borland Delphi 6/7
  Original Binary: lolwut32.dll / gh0s7h4x11.dll
  Memory Dump Analyzed: payload_memory_dump.bin (Base: 0x04C50000)
  ============================================================================== }

interface

uses
  Windows, SysUtils, IniFiles;

type
  { 3D Vector Structure for Half-Life / GoldSrc Engine }
  TVector3D = packed record
    X: Single; // Pitch in angles, or X spatial axis
    Y: Single; // Yaw in angles, or Y spatial axis
    Z: Single; // Roll in angles, or Z spatial axis
  end;
  PVector3D = ^TVector3D;

  { User Command Structure (usercmd_s in HLSDK) }
  TUserCmd = packed record
    lerp_msec: SmallInt;
    msec: Byte;
    viewangles: TVector3D;
    forwardmove: Single;
    sidemove: Single;
    upmove: Single;
    lightlevel: Byte;
    buttons: Word;
    impulse: Byte;
    weaponselect: Byte;
    impact_index: Integer;
    impact_position: TVector3D;
  end;
  PUserCmd = ^TUserCmd;

  { Configuration Global Structure (Mapped from RVA 0x2E5D4..0x2E680) }
  TCheatConfig = record
    // Visuals / OpenGL
    AsusWallhack: Integer; // 0x04C7E5D4
    Lambert: Integer;      // 0x04C7E5D8
    PlayerGlow: Integer;   // 0x04C7E63C
    PlayerLight: Integer;  // 0x04C7E640
    WhiteWalls: Integer;   // 0x04C7E5DC
    Fullbright: Integer;   // 0x04C7E5E0
    Nightmode: Integer;    // 0x04C7E5F4
    LessSmoke: Integer;    // 0x04C7E5E4
    LessFlash: Integer;    // 0x04C7E5E8
    Crosshair: Integer;    // 0x04C7E5F8
    NoRecoil: Integer;     // 0x04C7E61C (Aim mode: 0=Off, 1=Silent, 2=Lock)

    // Aim / Aimbot
    Aimbot: Integer;       // 0x04C7E5FC
    AimSpeed: Integer;     // 0x04C7E66C (Default: 100)
    SilentAim: Integer;    // 0x04C7E654
    AimTeam: Integer;      // 0x04C7E628 (Default: 1)
    AimKey: Integer;       // 0x04C7E64C (Default: 1 = IN_ATTACK)
    AimSpot: Integer;      // 0x04C7E600 (Default: 1 = Head)
    DrawAimSpot: Integer;  // 0x04C7E65C
    AimFov: Integer;       // 0x04C7E648 (Default: 450 -> 45.0 degrees)
    DrawAimFov: Integer;   // 0x04C7E644
    AimThruWall: Integer;  // 0x04C7E638

    // ESP / Entities
    BoxESP: Integer;       // 0x04C7E604
    NameESP: Integer;      // 0x04C7E608
    WeaponESP: Integer;    // 0x04C7E630
    DistanceESP: Integer;  // 0x04C7E62C
    EntityESP: Integer;    // 0x04C7E658
    GlowEnts: Integer;     // 0x04C7E668
    GlowNades: Integer;    // 0x04C7E664
    StepESP: Integer;      // 0x04C7E5EC

    // Movement / Utility
    Speedhack: Integer;    // 0x04C7E634
    Barrelhack: Integer;   // 0x04C7E660
    Radar: Integer;        // 0x04C7E624
  end;

var
  // Reconstructed Global Variables
  g_Config: TCheatConfig;
  g_vTargetDelta: TVector3D;   // RVA 0x2E6B0 (0x04C7E6B0)
  g_iAimMode: Integer;         // RVA 0x2E61C (0x04C7E61C: 1=Silent, 2=Continuous)
  g_pEngine: Pointer;          // RVA 0x2E5C8 (0x04C7E5C8: cl_enginefuncs_s)
  g_bMenuVisible: Boolean;

{ Reconstructed Function Prototypes }
function VectorLength(const V: TVector3D): Single;
procedure VectorSubtract(const A, B: TVector3D; var OutV: TVector3D);
procedure VectorScale(const InV: TVector3D; Scale: Single; var OutV: TVector3D);
procedure ApplyAngles(const TargetAngles: TVector3D; var ViewAngles: TVector3D; FrameTime: Single);
procedure LoadSettings(const IniPath: string);
function Hooked_HUD_Key_Event(eventcode: Integer; keynum: Integer; const pszCurrentBinding: PChar): Integer;
procedure Hooked_CL_CreateMove(frametime: Single; cmd: PUserCmd; active: Integer);

implementation

{ RVA 0x13728 (0x04C63728): 3D Vector Magnitude Calculation }
function VectorLength(const V: TVector3D): Single;
begin
  Result := Sqrt((V.X * V.X) + (V.Y * V.Y) + (V.Z * V.Z));
end;

{ RVA 0x13764 (0x04C63764): Vector Subtraction }
procedure VectorSubtract(const A, B: TVector3D; var OutV: TVector3D);
begin
  OutV.X := A.X - B.X;
  OutV.Y := A.Y - B.Y;
  OutV.Z := A.Z - B.Z;
end;

{ RVA 0x138E0 (0x04C638E0): Vector Scaling }
procedure VectorScale(const InV: TVector3D; Scale: Single; var OutV: TVector3D);
begin
  OutV.X := InV.X * Scale;
  OutV.Y := InV.Y * Scale;
  OutV.Z := InV.Z * Scale;
end;

{ RVA 0x2090C (0x04C7090C): Aimbot Angle Smoothing Choke Point }
procedure ApplyAngles(const TargetAngles: TVector3D; var ViewAngles: TVector3D; FrameTime: Single);
const
  k_flHalf: Single = 0.5;   // Constant at RVA 0x20998
  k_flBase: Single = 10.0;  // Constant at RVA 0x2099C
  k_flZero: Single = 0.0;   // Constant at RVA 0x209A0
var
  vDelta: TVector3D;
  flSmoothFactor: Single;
  flDecay: Single;
  vScaled: TVector3D;
begin
  vDelta := TargetAngles;

  // Exponential decay smoothing step
  flSmoothFactor := vDelta.X;
  flDecay := (flSmoothFactor * k_flHalf + k_flBase) * FrameTime;
  flSmoothFactor := flSmoothFactor - flDecay;

  // Clamp against 0.0 to prevent oscillation
  if flSmoothFactor < k_flZero then
    flSmoothFactor := k_flZero;

  VectorScale(vDelta, flSmoothFactor, vScaled);

  // Inject into command view angles (Pitch and Yaw)
  ViewAngles.X := ViewAngles.X - (vScaled.X * 2.0);
  ViewAngles.Y := ViewAngles.Y - (vScaled.Y * 2.0);
end;

{ RVA 0x26120 (0x04C76120): INI Settings Reader }
procedure LoadSettings(const IniPath: string);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(IniPath);
  try
    with g_Config do
    begin
      AsusWallhack := Ini.ReadInteger('SETTINGS', 'asuswallhack', 0);
      Lambert      := Ini.ReadInteger('SETTINGS', 'lambert', 0);
      PlayerGlow   := Ini.ReadInteger('SETTINGS', 'playerglow', 0);
      PlayerLight  := Ini.ReadInteger('SETTINGS', 'playerlight', 0);
      WhiteWalls   := Ini.ReadInteger('SETTINGS', 'whitewalls', 0);
      Fullbright   := Ini.ReadInteger('SETTINGS', 'fullbright', 0);
      Nightmode    := Ini.ReadInteger('SETTINGS', 'nightmode', 0);
      LessSmoke    := Ini.ReadInteger('SETTINGS', 'lesssmoke', 0);
      LessFlash    := Ini.ReadInteger('SETTINGS', 'lessflash', 0);
      Crosshair    := Ini.ReadInteger('SETTINGS', 'crosshair', 0);
      NoRecoil     := Ini.ReadInteger('SETTINGS', 'norecoil', 0);

      Aimbot       := Ini.ReadInteger('SETTINGS', 'aimbot', 0);
      AimSpeed     := Ini.ReadInteger('SETTINGS', 'aimspeed', 100);
      SilentAim    := Ini.ReadInteger('SETTINGS', 'silentaim', 0);
      AimTeam      := Ini.ReadInteger('SETTINGS', 'aimteam', 1);
      AimKey       := Ini.ReadInteger('SETTINGS', 'aimkey', 1);
      AimSpot      := Ini.ReadInteger('SETTINGS', 'aimspot', 1);
      DrawAimSpot  := Ini.ReadInteger('SETTINGS', 'drawaimspot', 0);
      AimFov       := Ini.ReadInteger('SETTINGS', 'aimfov', 450);
      DrawAimFov   := Ini.ReadInteger('SETTINGS', 'drawaimfov', 0);
      AimThruWall  := Ini.ReadInteger('SETTINGS', 'aimthruwall', 0);

      Speedhack    := Ini.ReadInteger('SETTINGS', 'speedhack', 0);
      Barrelhack   := Ini.ReadInteger('SETTINGS', 'barrelhack', 0);
      Radar        := Ini.ReadInteger('SETTINGS', 'radar', 0);
      StepESP      := Ini.ReadInteger('SETTINGS', 'stepesp', 0);
      BoxESP       := Ini.ReadInteger('SETTINGS', 'boxesp', 0);
      NameESP      := Ini.ReadInteger('SETTINGS', 'nameesp', 0);
      WeaponESP    := Ini.ReadInteger('SETTINGS', 'weaponesp', 0);
      DistanceESP  := Ini.ReadInteger('SETTINGS', 'distanceesp', 0);
      EntityESP    := Ini.ReadInteger('SETTINGS', 'entityesp', 0);
      GlowEnts     := Ini.ReadInteger('SETTINGS', 'glowents', 0);
      GlowNades    := Ini.ReadInteger('SETTINGS', 'glownades', 0);
    end;

    g_iAimMode := g_Config.NoRecoil;
  finally
    Ini.Free;
  end;
end;

{ RVA 0x21133: Keyboard Hook for Menu Toggle (INSERT / F12) }
function Hooked_HUD_Key_Event(eventcode: Integer; keynum: Integer; const pszCurrentBinding: PChar): Integer;
begin
  // Key F12 ($92 / 146) or Key INSERT ($2D / 45 / $93 in GoldSrc engine)
  if (eventcode = 1) and ((keynum = $92) or (keynum = $2D) or (keynum = $93)) then
  begin
    g_bMenuVisible := not g_bMenuVisible;
    Result := 0; // Block key event from game
    Exit;
  end;

  Result := 1; // Pass key event to game
end;

{ RVA 0x2530D: CL_CreateMove Hook for Silent Aim }
procedure Hooked_CL_CreateMove(frametime: Single; cmd: PUserCmd; active: Integer);
begin
  if (cmd = nil) or (active = 0) then
    Exit;

  // If Silent Aim is enabled (g_iAimMode = 1)
  if g_iAimMode = 1 then
  begin
    if (g_vTargetDelta.X <> 0.0) or (g_vTargetDelta.Y <> 0.0) then
    begin
      ApplyAngles(g_vTargetDelta, cmd^.viewangles, frametime);
    end;
  end;
end;

end.
