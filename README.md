# Gh0s7 h4x 12.3 Hack for sXe-Injected (xZone-Reactor CS 1.6)

Reverse engineering, memory dump analysis, and clean-room source code reconstruction of Gh0s7 H4x v12.3 from xZone-Reactor for Counter-Strike 1.6 (GoldSrc).

---

## Overview

In the mid-2000s, Gh0s7 H4x (developed by the xZone-Reactor group) was one of the widely used private utilities for Counter-Strike 1.6. The original binary was protected with a multi-stage crypter/packer (Reactor / X-Protector) containing anti-debugging traps, VM instruction virtualization, and MSVC licensing checks wrapped around a Borland Delphi 6/7 core payload.

### Game Version and Anti-Cheat Compatibility
* **Target Version**: Designed specifically for Counter-Strike 1.6 Protocol 47 (v47 / Build 3266).
* **Anti-Cheat Lifecycle**: The developers maintained bypass updates up to sXe-Injected 16.2 before abandoning the utility, although sXe-Injected released up to version 17.2 before closing down.
* **Current Status**: Today this codebase is obsolete for actual gameplay. Modern server-side defenses (ReHLDS, WHBlocker, Reunion, AimDetector) immediately block these legacy memory hooks, though most cheats from that era shared this same underlying Delphi/C++ code.

This repository provides:
1. **Raw Memory Dumps & Unpacked Binaries**: Original decrypted process memory dump (`payload_memory_dump.bin`), original packed binary (`lolwut32.dll`), and standalone cleaned PE binary (`lolwut_clean.dll`).
2. **Disassembly & Decompilation**: Over 55,500 annotated instructions in `disassembly_delphi_code.asm`.
3. **Reconstructed Source Code**: Modular, compile-ready implementations in C++17 and Borland Delphi/Pascal without protector code.

---

## Video Demonstration

[![Gh0s7 h4x v12.3 - sXe Injected v15.1](https://i.ytimg.com/vi/R5j96yzvRZA/hqdefault.jpg)](https://www.youtube.com/watch?v=R5j96yzvRZA)

Video link: https://www.youtube.com/watch?v=R5j96yzvRZA

---

## Repository Structure

```text
├── CMakeLists.txt              # CMake build script for C++
├── LICENSE                     # MIT License
├── README.md
├── .gitignore
│
├── artifacts/                  # Forensic binaries, dumps and disassembly
│   ├── lolwut32.dll            # Original packed binary from leak (1.27 MB)
│   ├── lolwut_clean.dll        # Patched & unpacked PE binary for Windows 10/11 (1.57 MB)
│   ├── payload_memory_dump.bin # Raw process memory dump (Base 0x04C50000, 1.44 MB)
│   ├── iat_resolved.txt        # Resolved IAT imports table
│   ├── relocs_v5.bin           # Serialized base relocation table
│   ├── disassembly_delphi_code.asm # Full x86 disassembly (55,534 instructions)
│   ├── decompiled_source.cpp   # Base decompiled C++ core unit
│   └── decompiled_source.pas   # Base decompiled Delphi Pascal core unit
│
├── config/
│   └── gh0s7h4x12.ini          # Configuration file (40 parameters)
│
├── docs/
│   └── OFFSETS.md              # Memory map, RVAs, and struct offsets
│
├── tools/
│   ├── build_perfect_clean.py  # Unpacker & standalone clean PE reconstructor
│   ├── symbols_map.py          # Symbol mapping generator
│   ├── apply_symbols_ida.idc   # IDA Pro symbol script
│   └── apply_symbols_ghidra.py # Ghidra symbol script
│
└── src/
    ├── cpp/                    # Modular C++17 implementation
    │   ├── SDK.hpp             # Shared GoldSrc & Half-Life structures
    │   ├── Aimbot.cpp          # Angle decay smoothing choke point
    │   ├── AimbotTarget.cpp    # 2D screen FOV and bone targeting
    │   ├── BarrelHack.cpp      # 3D forward projection laser beam
    │   ├── ESP.cpp             # Box, Name, Weapon, and Distance ESP
    │   ├── GlowLight.cpp       # Local glow, player glow, and dynamic lights
    │   ├── Movement.cpp        # Auto-bhop, fast run strafe, speedhack
    │   ├── RadarCrosshair.cpp  # 2D Radar HUD, custom dot/cross crosshairs
    │   ├── RemovalsView.cpp    # LessSmoke, LessFlash, ChaseCam, QuakeGuns
    │   ├── StepESP.cpp         # Circular step sound buffer and visuals
    │   ├── VisualsOpenGL.cpp   # AsusWallhack, Lambert, WhiteWalls, NightMode
    │   └── WallhackExtra.cpp   # SimpleWall, Unlit shader, EntityESP, Autowall
    │
    └── delphi/                 # Borland Delphi 6/7 Pascal implementation
        ├── Gh0s7H4x.dpr        # Master Delphi DLL project & worker thread
        ├── Types.pas           # Vectors, usercmd_s, and entity definitions
        ├── Config.pas          # 40-key INI parser and serializer
        ├── Math3D.pas          # FPU x87 vector math library & normalization
        ├── Hooks.pas           # CL_CreateMove, HUD_Redraw, HUD_Key_Event
        ├── Aimbot.pas
        ├── AimbotTarget.pas
        ├── BarrelHack.pas
        ├── ESP.pas
        ├── GlowLight.pas
        ├── Movement.pas
        ├── RadarCrosshair.pas
        ├── RemovalsView.pas
        ├── StepESP.pas
        ├── VisualsOpenGL.pas
        └── WallhackExtra.pas
```

---

## Architecture and Offsets

| Setting / Feature | Module | Original RVA / Offset | Description |
| :--- | :--- | :--- | :--- |
| `aimbot`, `norecoil`, `silentaim` | `Aimbot` | RVA `0x2090C` (`0x04C7090C`) | Exponential decay angle smoothing choke point |
| `aimspot`, `aimfov`, `aimteam` | `AimbotTarget` | RVA `0x24CE0` (`0x04C74CE0`) | 2D screen FOV bounding box & bone targeting |
| `stepesp` | `StepESP` | RVA `0x21190` & `0x22108` | Sound hook on `pfnPlaySoundByName`, circular step buffer |
| `boxesp`, `nameesp`, `weaponesp`| `ESP` | RVA `0x224D0` (`0x04C724D0`) | 32-player client loop, WorldToScreen projection |
| `asuswallhack`, `lambert`, `whitewalls` | `VisualsOpenGL` | RVA `0x25490` (`0x04C75490`) | Intercepts `glBegin`, depth buffer manipulation |
| `barrelhack` | `BarrelHack` | RVA `0x217B0` (`0x04C717B0`) | Forward viewangle projection via `R_BeamPoints` |
| `localglow`, `playerglow`, `playerlight` | `GlowLight` | RVA `0x22313` / `0x2236C` | `kRenderFxGlowShell` (19) and `CL_AllocDlight` |
| `radar`, `crosshair`, `drawaimfov` | `RadarCrosshair` | RVA `0x1FE0B`, `0x219C3` | 2D HUD Radar with local player yaw transformation |
| `lesssmoke`, `lessflash`, `quakeguns` | `RemovalsView` | RVA `0x2565B`, `0x25100` | Smoke sprite quad filter, flash screenfade suppressor |
| `simplewall`, `niggers`, `entityesp` | `WallhackExtra` | RVA `0x1F27D`, `0x1FB50` | Depth range override, unlit silhouette model shader |
| `bhop`, `fastrun`, `speedhack` | `Movement` | RVA `0x252BF`, `0x25131` | Auto-jump on `FL_ONGROUND`, sidemove oscillation |
| `CL_CreateMove`, `HUD_Redraw` | `Hooks` | RVA `0x2530D`, `0x24DA0` | Command modification & frame render dispatchers |

For the complete technical breakdown of all 40 variables and struct alignments, see `docs/OFFSETS.md`.

---

## Modern Windows (Win10 / Win11) Patches in lolwut_clean.dll

The binary in `artifacts/lolwut_clean.dll` has been repaired and patched for modern Windows:

1. **OpenGL Driver Compatibility**: Neutralized destructive Windows XP-era `glTexEnvf` hook skips at RVA `0x2655E..0x2658C`, preventing crashes on modern NVIDIA, AMD, and Intel graphics drivers.
2. **Safe GetProcAddress Hook Guard**: Parameter validation guard at RVA `0x257C4` to prevent `0xC0000005` Access Violation crashes when modern Windows components or overlays pass ordinals or non-user memory pointers.
3. **Dynamic IAT & Relocations**: Standard 148-entry IAT and 9,000 base relocations for compatibility with ASLR.
4. **Protector VM Neutralization**: Original Delphi `DllMain` entry point at RVA `0x26FA9` is patched to jump directly to `0x27091`, bypassing the Reactor VM stub.
5. **Dynamic Path Isolation**: Runtime resolution via `GetModuleFileNameA`, automatically reading `gh0s7h4x12.ini` relative to the DLL location without fixed paths.

---

## Building

### Borland Delphi
1. Open Borland Delphi 6, Delphi 7, or Embarcadero RAD Studio.
2. Open `src/delphi/Gh0s7H4x.dpr`.
3. Select Release and compile (`Ctrl + F9`).
4. Output: `gh0s7h4x.dll`.

### C++ (CMake)
```bash
cmake -B build -A Win32
cmake --build build --config Release
```
Output: `build/Release/gh0s7h4x.dll`.

---

## Disassembly & Symbol Tools

* **IDA Pro:** Load binary at base `0x04C50000` -> `File` -> `Script file...` -> select `tools/apply_symbols_ida.idc`.
* **Ghidra:** In CodeBrowser -> `Script Manager` -> select `tools/apply_symbols_ghidra.py`.

---

## Methodology & Tooling Credits

* **OpenCode**: Autonomous reverse engineering environment and binary analysis harness used for memory dumping, unpacker prototyping, and forensic discovery. Models utilized during the RE sessions:
  * GLM-5.3 Uncensored
  * MiniMax M3.1 Flash (Reasoning)
  * DeepSeek V4.1 Flash
  * GLM-5.3 Flash
* **Gemini 3.8 Flash High**: Binary reasoning, disassembly interpretation, x87 FPU-to-IEEE 754 vector math algebraic reconstruction, and clean modular source generation across both modern C++17 and Borland Delphi 7.
* **Ghidra & IDA Pro**: Interactive disassembly, control-flow graph validation, and RVA symbol mapping.

---

## Disclaimer

This repository contains reverse engineering and software reconstruction conducted strictly for educational purposes, forensic analysis, game engine architecture research, and video game software preservation.
