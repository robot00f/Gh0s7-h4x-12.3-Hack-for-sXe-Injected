unit Config;

{ ==============================================================================
  CONFIGURATION MODULE (TIniFile Parser & Memory Settings)
  All 40 Variables Mapped to Exact Binary Offsets (RVA 0x2E5D0..0x2E670)
  ============================================================================== }

interface

uses
  Windows, SysUtils, IniFiles;

type
  { Complete Configuration Record Mapped from Binary (RVA 0x2E5D0..0x2E680) }
  TCheatConfig = record
    // Visuals / OpenGL
    SimpleWall: Integer;    // RVA 0x2E5D0 (VA 0x04C7E5D0)
    AsusWallhack: Integer;  // RVA 0x2E5D4 (VA 0x04C7E5D4)
    Lambert: Integer;       // RVA 0x2E5D8 (VA 0x04C7E5D8)
    WhiteWalls: Integer;    // RVA 0x2E5DC (VA 0x04C7E5DC)
    Fullbright: Integer;    // RVA 0x2E5E0 (VA 0x04C7E5E0)
    LessSmoke: Integer;     // RVA 0x2E5E4 (VA 0x04C7E5E4)
    LessFlash: Integer;     // RVA 0x2E5E8 (VA 0x04C7E5E8)
    Niggers: Integer;       // RVA 0x2E5F0 (VA 0x04C7E5F0: Model Texture Shader)
    Nightmode: Integer;     // RVA 0x2E5F4 (VA 0x04C7E5F4)
    LocalGlow: Integer;     // RVA 0x2E618 (VA 0x04C7E618)
    PlayerGlow: Integer;    // RVA 0x2E63C (VA 0x04C7E63C)
    PlayerLight: Integer;   // RVA 0x2E640 (VA 0x04C7E640)

    // Aimbot / Weapon Control
    Aimbot: Integer;        // RVA 0x2E5FC (VA 0x04C7E5FC)
    AimSpot: Integer;       // RVA 0x2E600 (VA 0x04C7E600: 1=Head, 2=Chest, 3=All)
    AimSpeed: Integer;      // RVA 0x2E66C (VA 0x04C7E66C: Default 100)
    NoRecoil: Integer;      // RVA 0x2E61C (VA 0x04C7E61C: 0=Off, 1=Silent, 2=Lock)
    SilentAim: Integer;     // RVA 0x2E654 (VA 0x04C7E654)
    AimTeam: Integer;       // RVA 0x2E628 (VA 0x04C7E628: 1=Attack Enemies Only)
    AimKey: Integer;        // RVA 0x2E64C (VA 0x04C7E64C: 1=IN_ATTACK)
    AimFov: Integer;        // RVA 0x2E648 (VA 0x04C7E648: Default 450 = 45.0 deg)
    DrawAimFov: Integer;    // RVA 0x2E644 (VA 0x04C7E644)
    DrawAimSpot: Integer;   // RVA 0x2E65C (VA 0x04C7E65C)
    AimThruWall: Integer;   // RVA 0x2E638 (VA 0x04C7E638: Autowall)

    // ESP / Entities
    BoxESP: Integer;        // RVA 0x2E604 (VA 0x04C7E604)
    NameESP: Integer;       // RVA 0x2E608 (VA 0x04C7E608)
    DistanceESP: Integer;   // RVA 0x2E62C (VA 0x04C7E62C)
    WeaponESP: Integer;     // RVA 0x2E630 (VA 0x04C7E630)
    EntityESP: Integer;     // RVA 0x2E658 (VA 0x04C7E658: Weapons/C4/Hostages)
    GlowEnts: Integer;      // RVA 0x2E668 (VA 0x04C7E668)
    GlowNades: Integer;     // RVA 0x2E664 (VA 0x04C7E664)
    StepESP: Integer;       // RVA 0x2E5EC (VA 0x04C7E5EC: 1=Text, 2=Circle)
    Barrelhack: Integer;    // RVA 0x2E660 (VA 0x04C7E660: Forward Laser)

    // HUD / Movement / Camera
    Crosshair: Integer;     // RVA 0x2E5F8 (VA 0x04C7E5F8: 0=Off, 1=Dot, 2=Cross)
    Radar: Integer;         // RVA 0x2E624 (VA 0x04C7E624: 2D Radar Box)
    Bhop: Integer;          // RVA 0x2E60C (VA 0x04C7E60C: Bunnyhop)
    FastRun: Integer;       // RVA 0x2E610 (VA 0x04C7E610: Fast Run)
    Speedhack: Integer;     // RVA 0x2E634 (VA 0x04C7E634: Msec Multiplier)
    QuakeGuns: Integer;     // RVA 0x2E614 (VA 0x04C7E614: Centered Viewmodel)
    ChaseCam: Integer;      // RVA 0x2E620 (VA 0x04C7E620: Thirdperson Camera)

    // External Utilities
    AutoScreenShot: string; // RVA 0x2E670 (VA 0x04C7E670: Anti-ScreenShot cleaner)
  end;

var
  g_Config: TCheatConfig;
  g_szIniPath: string;

procedure LoadConfig(const FilePath: string);
procedure SaveConfig(const FilePath: string);

implementation

procedure LoadConfig(const FilePath: string);
var
  Ini: TIniFile;
  Section: string;
begin
  g_szIniPath := FilePath;
  Ini := TIniFile.Create(FilePath);
  Section := 'SETTINGS';
  try
    with g_Config do
    begin
      // Visuals / OpenGL
      SimpleWall     := Ini.ReadInteger(Section, 'simplewall', 0);
      AsusWallhack   := Ini.ReadInteger(Section, 'asuswallhack', 0);
      Lambert        := Ini.ReadInteger(Section, 'lambert', 0);
      WhiteWalls     := Ini.ReadInteger(Section, 'whitewalls', 0);
      Fullbright     := Ini.ReadInteger(Section, 'fullbright', 0);
      LessSmoke      := Ini.ReadInteger(Section, 'lesssmoke', 0);
      LessFlash      := Ini.ReadInteger(Section, 'lessflash', 0);
      Niggers        := Ini.ReadInteger(Section, 'niggers', 0);
      Nightmode      := Ini.ReadInteger(Section, 'nightmode', 0);
      LocalGlow      := Ini.ReadInteger(Section, 'localglow', 0);
      PlayerGlow     := Ini.ReadInteger(Section, 'playerglow', 0);
      PlayerLight    := Ini.ReadInteger(Section, 'playerlight', 0);

      // Aimbot / Weapon Control
      Aimbot         := Ini.ReadInteger(Section, 'aimbot', 0);
      AimSpot        := Ini.ReadInteger(Section, 'aimspot', 1);
      AimSpeed       := Ini.ReadInteger(Section, 'aimspeed', 100);
      NoRecoil       := Ini.ReadInteger(Section, 'norecoil', 0);
      SilentAim      := Ini.ReadInteger(Section, 'silentaim', 0);
      AimTeam        := Ini.ReadInteger(Section, 'aimteam', 1);
      AimKey         := Ini.ReadInteger(Section, 'aimkey', 1);
      AimFov         := Ini.ReadInteger(Section, 'aimfov', 450);
      DrawAimFov     := Ini.ReadInteger(Section, 'drawaimfov', 0);
      DrawAimSpot    := Ini.ReadInteger(Section, 'drawaimspot', 0);
      AimThruWall    := Ini.ReadInteger(Section, 'aimthruwall', 0);

      // ESP / Entities
      BoxESP         := Ini.ReadInteger(Section, 'boxesp', 0);
      NameESP        := Ini.ReadInteger(Section, 'nameesp', 0);
      DistanceESP    := Ini.ReadInteger(Section, 'distanceesp', 0);
      WeaponESP      := Ini.ReadInteger(Section, 'weaponesp', 0);
      EntityESP      := Ini.ReadInteger(Section, 'entityesp', 0);
      GlowEnts       := Ini.ReadInteger(Section, 'glowents', 0);
      GlowNades      := Ini.ReadInteger(Section, 'glownades', 0);
      StepESP        := Ini.ReadInteger(Section, 'stepesp', 0);
      Barrelhack     := Ini.ReadInteger(Section, 'barrelhack', 0);

      // HUD / Movement / Camera
      Crosshair      := Ini.ReadInteger(Section, 'crosshair', 0);
      Radar          := Ini.ReadInteger(Section, 'radar', 0);
      Bhop           := Ini.ReadInteger(Section, 'bhop', 0);
      FastRun        := Ini.ReadInteger(Section, 'fastrun', 0);
      Speedhack      := Ini.ReadInteger(Section, 'speedhack', 0);
      QuakeGuns      := Ini.ReadInteger(Section, 'quakeguns', 0);
      ChaseCam       := Ini.ReadInteger(Section, 'chasecam', 0);

      // Utilities
      AutoScreenShot := Ini.ReadString(Section, 'AutoScreenShot', 'AutoScreenShot.exe');
    end;
  finally
    Ini.Free;
  end;
end;

procedure SaveConfig(const FilePath: string);
var
  Ini: TIniFile;
  Section: string;
begin
  Ini := TIniFile.Create(FilePath);
  Section := 'SETTINGS';
  try
    with g_Config do
    begin
      Ini.WriteInteger(Section, 'simplewall', SimpleWall);
      Ini.WriteInteger(Section, 'asuswallhack', AsusWallhack);
      Ini.WriteInteger(Section, 'lambert', Lambert);
      Ini.WriteInteger(Section, 'whitewalls', WhiteWalls);
      Ini.WriteInteger(Section, 'fullbright', Fullbright);
      Ini.WriteInteger(Section, 'lesssmoke', LessSmoke);
      Ini.WriteInteger(Section, 'lessflash', LessFlash);
      Ini.WriteInteger(Section, 'niggers', Niggers);
      Ini.WriteInteger(Section, 'nightmode', Nightmode);
      Ini.WriteInteger(Section, 'localglow', LocalGlow);
      Ini.WriteInteger(Section, 'playerglow', PlayerGlow);
      Ini.WriteInteger(Section, 'playerlight', PlayerLight);

      Ini.WriteInteger(Section, 'aimbot', Aimbot);
      Ini.WriteInteger(Section, 'aimspot', AimSpot);
      Ini.WriteInteger(Section, 'aimspeed', AimSpeed);
      Ini.WriteInteger(Section, 'norecoil', NoRecoil);
      Ini.WriteInteger(Section, 'silentaim', SilentAim);
      Ini.WriteInteger(Section, 'aimteam', AimTeam);
      Ini.WriteInteger(Section, 'aimkey', AimKey);
      Ini.WriteInteger(Section, 'aimfov', AimFov);
      Ini.WriteInteger(Section, 'drawaimfov', DrawAimFov);
      Ini.WriteInteger(Section, 'drawaimspot', DrawAimSpot);
      Ini.WriteInteger(Section, 'aimthruwall', AimThruWall);

      Ini.WriteInteger(Section, 'boxesp', BoxESP);
      Ini.WriteInteger(Section, 'nameesp', NameESP);
      Ini.WriteInteger(Section, 'distanceesp', DistanceESP);
      Ini.WriteInteger(Section, 'weaponesp', WeaponESP);
      Ini.WriteInteger(Section, 'entityesp', EntityESP);
      Ini.WriteInteger(Section, 'glowents', GlowEnts);
      Ini.WriteInteger(Section, 'glownades', GlowNades);
      Ini.WriteInteger(Section, 'stepesp', StepESP);
      Ini.WriteInteger(Section, 'barrelhack', Barrelhack);

      Ini.WriteInteger(Section, 'crosshair', Crosshair);
      Ini.WriteInteger(Section, 'radar', Radar);
      Ini.WriteInteger(Section, 'bhop', Bhop);
      Ini.WriteInteger(Section, 'fastrun', FastRun);
      Ini.WriteInteger(Section, 'speedhack', Speedhack);
      Ini.WriteInteger(Section, 'quakeguns', QuakeGuns);
      Ini.WriteInteger(Section, 'chasecam', ChaseCam);

      Ini.WriteString(Section, 'AutoScreenShot', AutoScreenShot);
    end;
  finally
    Ini.Free;
  end;
end;

end.
