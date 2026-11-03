# Forensic Memory Offsets & RVA Reference Manual
**Target Binary:** `payload_memory_dump.bin`  
**Image Base Address:** `0x04C50000`  
**Total Mapped Size:** 1,445,888 bytes (0x161000)  

---

## 1. Global Variable Memory Map (`DATA` / `BSS` Section)

| Configuration Key | Data Type | Relative Virtual Address (RVA) | Absolute Virtual Address (VA) | Purpose / Meaning in Code |
| :--- | :--- | :--- | :--- | :--- |
| `g_pEngineFuncs` | `cl_enginefuncs_s*` | `0x2E5C8` | `0x04C7E5C8` | Engine function table pointer |
| `simplewall` | `int32` | `0x2E5D0` | `0x04C7E5D0` | Depth range wallhack toggle |
| `asuswallhack` | `int32` | `0x2E5D4` | `0x04C7E5D4` | Semi-transparent wallhack (alpha 0.5f) |
| `lambert` | `int32` | `0x2E5D8` | `0x04C7E5D8` | Model bright lighting (GL modes 5 & 6) |
| `whitewalls` | `int32` | `0x2E5DC` | `0x04C7E5DC` | Texture decal white wall toggle |
| `fullbright` | `int32` | `0x2E5E0` | `0x04C7E5E0` | Gamma/lightmap suppression |
| `lesssmoke` | `int32` | `0x2E5E4` | `0x04C7E5E4` | Gas puff sprite filter toggle |
| `lessflash` | `int32` | `0x2E5E8` | `0x04C7E5E8` | Screenfade blindness suppressor |
| `stepesp` | `int32` | `0x2E5EC` | `0x04C7E5EC` | Footstep sound ESP (1=Text, 2=Circle) |
| `niggers` | `int32` | `0x2E5F0` | `0x04C7E5F0` | Player model unlit black silhouette |
| `nightmode` | `int32` | `0x2E5F4` | `0x04C7E5F4` | Inverted dark scene blend |
| `crosshair` | `int32` | `0x2E5F8` | `0x04C7E5F8` | Custom crosshair (0=Off, 1=Dot, 2=Cross) |
| `aimbot` | `int32` | `0x2E5FC` | `0x04C7E5FC` | Master aimbot switch |
| `aimspot` | `int32` | `0x2E600` | `0x04C7E600` | Bone target (1=Head, 2=Chest, 3=All) |
| `boxesp` | `int32` | `0x2E604` | `0x04C7E604` | 2D Bounding box ESP |
| `nameesp` | `int32` | `0x2E608` | `0x04C7E608` | Player nickname display |
| `bhop` | `int32` | `0x2E60C` | `0x04C7E60C` | Bunnyhop auto-jump on FL_ONGROUND |
| `fastrun` | `int32` | `0x2E610` | `0x04C7E610` | Fast run forward-strafe toggle |
| `quakeguns` | `int32` | `0x2E614` | `0x04C7E614` | Centered viewmodel coordinates |
| `localglow` | `int32` | `0x2E618` | `0x04C7E618` | First-person hands glow |
| `norecoil` | `int32` | `0x2E61C` | `0x04C7E61C` | Aim mode (0=Off, 1=Silent, 2=Lock) |
| `chasecam` | `int32` | `0x2E620` | `0x04C7E620` | Thirdperson camera offset |
| `radar` | `int32` | `0x2E624` | `0x04C7E624` | 2D HUD Radar display |
| `aimteam` | `int32` | `0x2E628` | `0x04C7E628` | Friendly fire targeting filter |
| `distanceesp` | `int32` | `0x2E62C` | `0x04C7E62C` | Enemy distance meter in ESP |
| `weaponesp` | `int32` | `0x2E630` | `0x04C7E630` | Active held weapon name |
| `speedhack` | `int32` | `0x2E634` | `0x04C7E634` | Command tickrate / msec multiplier |
| `aimthruwall` | `int32` | `0x2E638` | `0x04C7E638` | Autowall wall-penetration check |
| `playerglow` | `int32` | `0x2E63C` | `0x04C7E63C` | RenderFx glow shell on player models |
| `playerlight` | `int32` | `0x2E640` | `0x04C7E640` | Dynamic spot light (CL_AllocDlight) |
| `drawaimfov` | `int32` | `0x2E644` | `0x04C7E644` | FOV boundary circle visual |
| `aimfov` | `int32` | `0x2E648` | `0x04C7E648` | FOV radius threshold (pixels/degrees) |
| `aimkey` | `int32` | `0x2E64C` | `0x04C7E64C` | Activation key (Default 1 = IN_ATTACK) |
| `silentaim` | `int32` | `0x2E654` | `0x04C7E654` | Viewangle bypass in usercmd |
| `entityesp` | `int32` | `0x2E658` | `0x04C7E658` | Ground item ESP (Weapons, C4, Hostages)|
| `drawaimspot` | `int32` | `0x2E65C` | `0x04C7E65C` | Target bone indicator dot |
| `barrelhack` | `int32` | `0x2E660` | `0x04C7E660` | 3D forward barrel laser line |
| `glownades` | `int32` | `0x2E664` | `0x04C7E664` | Grenade projectile glow |
| `glowents` | `int32` | `0x2E668` | `0x04C7E668` | Ground weapon entity glow |
| `aimspeed` | `int32` | `0x2E66C` | `0x04C7E66C` | Smoothing factor speed scalar |
| `autoscreenshot`| `char[260]` | `0x2E670` | `0x04C7E670` | External anti-screenshot cleaner binary |
| `g_vTargetDelta`| `Vector3D` | `0x2E6B0` | `0x04C7E6B0` | Calculated target angular delta (Pitch/Yaw)|
| `g_pfnGetAsyncKeyState` | `FARPROC` | `0x2E724` | `0x04C7E724` | Dynamic pointer to user32!GetAsyncKeyState |

---

## 2. Engine Function & Subroutine Offsets (`CODE` Section)

| Subroutine / Routine Name | RVA | VA @ 0x04C50000 | Calling Convention | Description |
| :--- | :--- | :--- | :--- | :--- |
| `VectorLength_3D` | `0x13728` | `0x04C63728` | Delphi register (EAX) | Computes sqrt(x^2 + y^2 + z^2) via FPU x87 |
| `VectorSubtract_3D` | `0x13764` | `0x04C63764` | Delphi register | Vector difference: C = A - B |
| `VectorScale_3D` | `0x138E0` | `0x04C638E0` | Delphi register | Scalar multiplication: Out = In * Factor |
| `Hooked_SimpleWall` | `0x1F27D` | `0x04C6F27D` | `__stdcall` | Intercepts model depth buffer function |
| `Hooked_ModelShader_Niggers`| `0x1F3EC` | `0x04C6F3EC` | `__stdcall` | Disables texture 2D, forces black color |
| `Hooked_EntityESP` | `0x1FB50` | `0x04C6FB50` | `__cdecl` | Non-player entities loop (indices 33..255) |
| `Hooked_Radar` | `0x1FE0B` | `0x04C6FE0B` | `__cdecl` | 2D Radar bounding box & player dot matrix |
| `Hooked_AimThruWall` | `0x20084` | `0x04C70084` | `__fastcall` | Autowall bidirectional TraceLine check |
| `Hooked_DrawAimFov` | `0x200A7` | `0x04C700A7` | `__cdecl` | Renders FOV boundary circle |
| `ComputeAngleDifference` | `0x20890` | `0x04C70890` | `__fastcall` | Calculates angular delta between eye & target |
| `ApplyAngles` (Aimbot) | `0x2090C` | `0x04C7090C` | `__fastcall` | **Nuclear choke point**: Angle decay & smoothing |
| `Hooked_HUD_Key_Event` | `0x21133` | `0x04C71133` | `__cdecl` | INSERT ($2D/$93) & F12 ($92) menu interceptor |
| `Hooked_PlaySoundByName` | `0x21190` | `0x04C71190` | `__cdecl` | StepESP sound buffer capture (`"step"`, `"dirt"`)|
| `Hooked_ChaseCam` | `0x212CC` | `0x04C712CC` | `__cdecl` | Thirdperson camera offset manipulation |
| `Hooked_BarrelHack` | `0x217B0` | `0x04C717B0` | `__cdecl` | Forward laser projection via R_BeamPoints |
| `Hooked_CustomCrosshair`| `0x219C3` | `0x04C719C3` | `__cdecl` | 2D HUD Red Dot & Classic Cross crosshairs |
| `Hooked_DrawStepESP` | `0x22108` | `0x04C72108` | `__cdecl` | Circular pulse & text step rendering |
| `Hooked_LocalGlow` | `0x22313` | `0x04C72313` | `__fastcall` | Applies glowshell to viewmodel / local player |
| `Hooked_PlayerGlow` | `0x2236C` | `0x04C7236C` | `__fastcall` | Sets renderamt 5, rendercolor RGB, renderfx 19 |
| `Hooked_PlayerESP` | `0x224D0` | `0x04C724D0` | `__cdecl` | Master ESP loop across all 32 player entities |
| `Hooked_DrawAimSpot` | `0x23C20` | `0x04C73C20` | `__cdecl` | Renders target bone indicator marker |
| `Hooked_QuakeGuns` | `0x2457B` | `0x04C7457B` | `__cdecl` | Sets viewmodel lateral shift to screen center |
| `Hooked_Speedhack` | `0x24754` | `0x04C74754` | `__fastcall` | Modifies usercmd msec tick duration |
| `Hooked_FindBestTarget`| `0x24CE0` | `0x04C74CE0` | `__fastcall` | 2D bounding box FOV target search |
| `Hooked_HUD_Redraw` | `0x24DA0` | `0x04C74DA0` | `__cdecl` | Frame drawing dispatcher for visual overlays |
| `Hooked_LessFlash` | `0x25100` | `0x04C75100` | `__cdecl` | Clamps screenfade fadealpha to 0 or 50 |
| `Hooked_FastRun` | `0x25131` | `0x04C75131` | `__fastcall` | Alternates sidemove +/-250 on ground forward |
| `Hooked_Bhop` | `0x252BF` | `0x04C752BF` | `__fastcall` | Filters IN_JUMP when FL_ONGROUND is 0 |
| `Hooked_CL_CreateMove` | `0x2530D` | `0x04C7530D` | `__cdecl` | Movement packets hook (SilentAim & Recoil) |
| `Hooked_glBegin` | `0x25490` | `0x04C75490` | `__stdcall` | Visuals: Asus (GL_POLYGON), Lambert, WhiteWalls |
| `Hooked_LessSmoke` | `0x2565B` | `0x04C7565B` | `__stdcall` | Filters gas_puff.spr / smokepuff.spr quads |
| `LoadSettingsFromIni` | `0x26120` | `0x04C76120` | Delphi register | Reads gh0s7h4x11.ini / gh0s7h4x12.ini |
| `Handle_AutoScreenShot` | `0x264BA` | `0x04C764BA` | Delphi register | Launches AutoScreenShot.exe cleaner process |
| `Install_EngineHooks` | `0x2689A` | `0x04C7689A` | Delphi register | Resolves hw.dll / sw.dll and installs tables |
| `Original_DllMain_OEP` | `0x26FA9` | `0x04C76FA9` | `__stdcall` | Entry point bootstrap of original Delphi DLL |

---

## 3. GoldSrc Engine Data Structure Offsets

### `cl_entity_s` (Client Entity Struct)
- `+0x000`: `index` (`int32`, 1..32 for players, 33..255 for ground entities)
- `+0x004`: `player` (`int32`, boolean flag)
- `+0x008`: `baseline_origin` (`Vector3D`, 12 bytes)
- `+0x014`: `current_origin` (`Vector3D`, 12 bytes)
- `+0x020`: `angles` (`Vector3D`, 12 bytes)
- `+0x2FC`: `renderamt` (`int32`, glow shell thickness: 5)
- `+0x300`: `rendercolor` (`uint8[3]`, RGB color values: $32, $32, $FF)
- `+0x304`: `renderfx` (`uint8`, glow shell mode: 19 = `kRenderFxGlowShell`)
- `+0x360`: `is_dead` (`int32`, checked at RVA `0x24D8B`: `0` = Alive, `!= 0` = Dead)

### `usercmd_s` (Client Network Movement Command)
- `+0x000`: `lerp_msec` (`int16`)
- `+0x002`: `msec` (`uint8`, multiplied by `speedhack`)
- `+0x004`: `viewangles` (`Vector3D`, modified by `ApplyAngles` / `SilentAim`)
- `+0x010`: `forwardmove` (`float32`, modified by `FastRun`)
- `+0x014`: `sidemove` (`float32`, modified by `FastRun` +/- 250.0f)
- `+0x018`: `upmove` (`float32`)
- `+0x01D`: `buttons` (`uint16`, bitmask: `IN_ATTACK` = $01, `IN_JUMP` = $02, etc.)

---

## 4. Hardcoded Forensic Constants

| Address (VA) | Value | Data Type | Usage |
| :--- | :--- | :--- | :--- |
| `0x04C70998` | `0.5f` | IEEE 754 float | `k_flHalfDecay` for exponential aim smoothing |
| `0x04C7099C` | `10.0f` | IEEE 754 float | `k_flBaseDecay` base smoothing speed |
| `0x04C709A0` | `0.0f` | IEEE 754 float | `k_flMinClamp` prevent negative overshoot |
| `0x04C7231C` | `19` (`0x13`)| byte | `kRenderFxGlowShell` OpenGL glow mode |
| `0x04C72321` | `5` | int32 | Glowshell shell thickness (`renderamt`) |
