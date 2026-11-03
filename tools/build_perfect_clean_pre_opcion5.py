import pefile
import struct
import os
import capstone

class Assembler:
    def __init__(self):
        self.items = []
        self.labels = {}

    def b(self, data):
        self.items.append(('bytes', data))

    def label(self, name):
        self.items.append(('label', name))

    def jmp(self, target):
        self.items.append(('rel8', b'\xEB', target))

    def jmp32(self, target):
        self.items.append(('rel32', b'\xE9', target))

    def jmp32_rva(self, target_rva):
        self.items.append(('rel32_rva', b'\xE9', target_rva))

    def je(self, target):
        self.items.append(('rel8', b'\x74', target))

    def jz(self, target):
        self.items.append(('rel8', b'\x74', target))

    def jle(self, target):
        self.items.append(('rel8', b'\x7E', target))

    def jne(self, target):
        self.items.append(('rel8', b'\x75', target))

    def jne32(self, target):
        self.items.append(('rel32', b'\x0F\x85', target))

    def je32(self, target):
        self.items.append(('rel32', b'\x0F\x84', target))

    def js(self, target):
        self.items.append(('rel8', b'\x78', target))

    def jb(self, target):
        self.items.append(('rel8', b'\x72', target))

    def jae(self, target):
        self.items.append(('rel8', b'\x73', target))

    def call(self, target):
        self.items.append(('rel32', b'\xE8', target))

    def mov_eax_ebx_plus_label(self, label_name):
        self.items.append(('eax_ebx_plus_label', label_name))

    def mov_ebx_image_base(self):
        self.items.append(('ebx_image_base',))

    def build(self, org=0):
        offset = org
        for item in self.items:
            t = item[0]
            if t == 'label':
                self.labels[item[1]] = offset
            elif t == 'bytes':
                offset += len(item[1])
            elif t == 'rel8':
                offset += 2
            elif t in ('rel32', 'rel32_rva'):
                offset += len(item[1]) + 4
            elif t == 'eax_ebx_plus_label':
                offset += 7
            elif t == 'ebx_image_base':
                offset += 12

        out = bytearray()
        offset = org
        for item in self.items:
            t = item[0]
            if t == 'label':
                pass
            elif t == 'bytes':
                out += item[1]
                offset += len(item[1])
            elif t == 'rel8':
                target = self.labels[item[2]]
                rel = target - (offset + 2)
                assert -128 <= rel <= 127, f'rel8 out of range: {rel} for {item[2]}'
                out += item[1] + (rel & 0xFF).to_bytes(1, 'little')
                offset += 2
            elif t == 'rel32':
                target = self.labels[item[2]]
                rel = target - (offset + len(item[1]) + 4)
                out += item[1] + struct.pack('<i', rel)
                offset += len(item[1]) + 4
            elif t == 'rel32_rva':
                target = item[2]
                rel = target - (offset + len(item[1]) + 4)
                out += item[1] + struct.pack('<i', rel)
                offset += len(item[1]) + 4
            elif t == 'eax_ebx_plus_label':
                target_rva = self.labels[item[1]]
                out += b'\x89\xD8\x05' + (target_rva).to_bytes(4, 'little')
                offset += 7
            elif t == 'ebx_image_base':
                pop_lbl_rva = offset + 5
                out += b'\xE8\x00\x00\x00\x00\x5B\x81\xEB' + (pop_lbl_rva).to_bytes(4, 'little')
                offset += 12
        return bytes(out)

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    artifacts_dir = os.path.join(script_dir, '..', 'artifacts')
    base_dir = artifacts_dir if os.path.exists(os.path.join(artifacts_dir, 'payload_memory_dump.bin')) else script_dir

    dump_path = os.path.join(base_dir, 'payload_memory_dump.bin')
    out_path = os.path.join(base_dir, 'lolwut_clean.dll')
    iat_txt = os.path.join(base_dir, 'iat_resolved.txt')
    relocs_bin = os.path.join(base_dir, 'relocs_v5.bin')

    with open(dump_path, 'rb') as f:
        buf = bytearray(f.read())

    print(f'Original dump size: {len(buf)} bytes')

    # Read IAT
    iat_entries = []
    with open(iat_txt, 'r') as f:
        for line in f:
            parts = line.strip().split(' -> ')
            if len(parts) == 2:
                rva = int(parts[0].split()[1], 16)
                mod, fn = parts[1].split('!')
                if fn and not fn.startswith('+') and rva < 0x2F350:
                    iat_entries.append((rva, mod, fn))

    # Add the two Reactor-hooked slots: GetVersion and GetVersionExA
    iat_entries.append((0x2F12C, 'kernel32.dll', 'GetVersion'))
    iat_entries.append((0x2F270, 'kernel32.dll', 'GetVersionExA'))
    iat_entries.append((0x2F348, 'opengl32.dll', 'glGetBooleanv'))
    # OpenGL function pointers in DATA (used by wrappers and Whitewalls/Nightmode/etc.)
    iat_entries.append((0x2B0DC, 'opengl32.dll', 'glGetFloatv'))
    iat_entries.append((0x2B0FC, 'opengl32.dll', 'glDisable'))
    iat_entries.append((0x2B0E0, 'opengl32.dll', 'glColor4f'))
    iat_entries.append((0x2B0F0, 'opengl32.dll', 'glEnd'))
    iat_entries.append((0x2B100, 'opengl32.dll', 'glEnable'))
    iat_entries.append((0x2B0F8, 'opengl32.dll', 'glTexEnvi')) # Whitewalls!
    iat_entries.append((0x2B0E8, 'opengl32.dll', 'glClearColor'))
    iat_entries.append((0x2B0EC, 'opengl32.dll', 'glClear'))
    iat_entries.append((0x2B0E4, 'opengl32.dll', 'glBlendFunc'))
    iat_entries.append((0x2B0F4, 'opengl32.dll', 'glDepthRange'))
    iat_entries.append((0x2B104, 'opengl32.dll', 'glDepthFunc'))
    iat_entries.append((0x2B108, 'user32.dll', 'GetAsyncKeyState'))
    iat_entries.sort(key=lambda x: x[0])

    print(f'Total IAT entries (including GetVersion and GetVersionExA): {len(iat_entries)}')

    # Nullify separators in .idata
    separators = [0x2F19C, 0x2F1B0, 0x2F1C0, 0x2F1D0, 0x2F1EC, 0x2F204, 0x2F2E4, 0x2F318, 0x2F320]
    for sep in separators:
        buf[sep : sep + 4] = b'\x00\x00\x00\x00'

    # Identify and zero out dirty runtime global heap pointers in DATA (from memory dump)
    tbl_rva = 0xBD50
    cnt = struct.unpack_from('<I', buf, tbl_rva)[0]
    dirty_vars = [struct.unpack_from('<I', buf, tbl_rva + 4 + i*8)[0] - 0x04C50000 for i in range(cnt)]
    dirty_vars += [0x2803C, 0x28144] # 0x2B0CC and 0x2B0D0 are engine time pointers for speedhack!
    for dvar in dirty_vars:
        buf[dvar : dvar + 4] = b'\x00\x00\x00\x00'
    print(f'Zeroed out {len(dirty_vars)} dirty runtime heap variables in DATA')

    # Read relocations and exclude BSS (0x2C000..0x2F000), separators, dirty heap variables
    # and any addresses inside the neutralized hook regions
    with open(relocs_bin, 'rb') as f:
        relocs_raw = f.read()
    all_relocs = []
    for i in range(0, len(relocs_raw), 4):
        off = struct.unpack_from('<I', relocs_raw, i)[0]
        if not (0x2C000 <= off < 0x2F000) and off not in separators and off not in dirty_vars and off != 0x26FAA:
            if not (0x2655E <= off < 0x2658C) and not (0x25718 <= off < 0x25734) and not (0x265EA <= off < 0x265F4) and not (0x2683A <= off < 0x2689A):
                all_relocs.append(off)
    if 0x2601C not in all_relocs:
        all_relocs.append(0x2601C)

    if 0x21141 in all_relocs:

        all_relocs.remove(0x21141)

    if 0x21148 in all_relocs:

        all_relocs.remove(0x21148)

    if 0x21146 not in all_relocs:

        all_relocs.append(0x21146)
    if 0x23288 in all_relocs: all_relocs.remove(0x23288)
    if 0x23295 in all_relocs: all_relocs.remove(0x23295)
    if 0x2513D in all_relocs: all_relocs.remove(0x2513D)
    if 0x252E7 in all_relocs: all_relocs.remove(0x252E7)
    if 0x260F5 in all_relocs: all_relocs.remove(0x260F5) # Replaced with NOPs in INI patch
    all_relocs.append(0x260EA) # Address operand of mov ecx, base_addr + inipath_str_rva

    # Add genuine RTTI descriptors in .text and packed struct field tables in .data
    # (Excludes code section false positives like 0x9DC1 which corrupted SysUtils.InitDateUtils opcodes)
    genuine_rtti_text = [
        0x106D, 0x10D1, 0x10D5, 0x10D9, 0x10F1,
        0x6186,
        0x6B35, 0x6B3D, 0x6B59, 0x6B61,
        0xA603,
        0xCA76, 0xCA7A, 0xCA7E, 0xCA96,
        0xEDD5,
        0xF849, 0xF84D, 0xF875, 0xF96E, 0xF98E, 0xF992, 0xF9BD, 0xFACD,
        0x1311E, 0x13126, 0x13A8A,
        0x13D4F, 0x13D53, 0x13D5B,
        0x13E07, 0x13E0B, 0x13E13,
        0x13EBF, 0x13EC3, 0x13ECB,
        0x13F77, 0x13F7B, 0x13F83,
        0x1574A,
        0x1EFFB
    ]
    existing_set = set(all_relocs)
    new_found = 0
    for off in genuine_rtti_text:
        if off not in existing_set:
            all_relocs.append(off)
            existing_set.add(off)
            new_found += 1

    for i in range(0x28000, 0x2B33C - 4):
        val = struct.unpack_from('<I', buf, i)[0]
        if 0x04C50000 <= val < 0x04C80000:
            target_rva = val - 0x04C50000
            if (0x1000 <= target_rva < 0x2713C) or (0x28000 <= target_rva < 0x2E800):
                if i not in existing_set and i not in dirty_vars:
                    all_relocs.append(i)
                    existing_set.add(i)
                    new_found += 1
    all_relocs.sort()

    print(f'Using {len(all_relocs)} relocations (added {new_found} verified RTTI and DATA table relocations)')

    base_addr = 0x04C50000

    # 1. Zero out BSS section (0x2C000..0x2F000) so Delphi Memory Manager starts fresh!
    buf[0x2C000 : 0x2F000] = b'\x00' * 0x3000
    print('Zeroed out BSS section (0x2C000..0x2F000)')

    # 2. Patch RVA 0x26FA9 (Delphi OEP hook) to jump cleanly to 0x27091
    buf[0x26FA9 : 0x26FA9 + 10] = b'\xE9\xE3\x00\x00\x00\x90\x90\x90\x90\x90'
    print('Patched Delphi DllMain entry point at 0x26FA9 to jump cleanly to 0x27091')

    # 3. Completely neutralize glTexEnvf hook installation in the background thread (RVA 0x2655E..0x2658C)
    buf[0x2655E : 0x2658C] = b'\x90' * (0x2658C - 0x2655E)
    print('Neutralized glTexEnvf hooks at RVA 0x2655E..0x2658C (opengl32.dll stays 100% original)')

    # Bypass broken Reactor VM stub at 0x265EA by jumping directly to 0x26768 (StudioInterface hooks)
    buf[0x265EA : 0x265F4] = b'\xE9\x79\x01\x00\x00\x90\x90\x90\x90\x90'
    print('Bypassed Reactor VM stub at RVA 0x265EA -> jmp 0x26768')

    # Bypass broken Reactor VM stub at 0x2683A by jumping directly to 0x2689A (Client command hooks)
    buf[0x2683A : 0x26844] = b'\xE9\x5B\x00\x00\x00\x90\x90\x90\x90\x90'
    print('Bypassed Reactor VM stub at RVA 0x2683A -> jmp 0x2689A')

    # Neutralize 0x25718..0x25734 as clean ret
    buf[0x25718 : 0x25734] = b'\xC3' + b'\x90' * (0x25734 - 0x25718 - 1)



    # Patch HUD_Key_Event at RVA 0x21133 (25 bytes) to toggle menu on INSERT (0x93 / 0x2D) as well as F12 (0x92)

    key_patch = bytes.fromhex('83fb01751489f03c2d7406d1e83c4975088035b0b0c7040190')

    assert len(key_patch) == 25

    buf[0x21133 : 0x21133 + 25] = key_patch

    print('Patched HUD_Key_Event at RVA 0x21133 to accept INSERT (0x93 / 0x2D) and F12 (0x92)')
    # Default menu to open (1) and cheat enabled (1)
    buf[0x2B0B0] = 1
    buf[0x2B0B4] = 1
    # Neutralize blocking checks at 0x23286..0x232A0 so menu is never suppressed
    buf[0x23286 : 0x232A0] = b'\x90' * 26
    print('Neutralized blocking checks at 0x23286..0x232A0 so menu renders directly')

    # 4. Fix OpenGL / GetAsyncKeyState hook bypasses from Windows XP era (RVA 0x259F6..0x25AEF and wrappers 0x1F024..0x1F0DF)
    # The original cheat added 5, 6, or 7 bytes to GetProcAddress pointers to jump into internal Windows XP opcodes,
    # causing an instant Access Violation crash on modern Windows in opengl32.dll when rendering Studio models.
    add_eax_offsets = [
        0x259F6, 0x25A0C, 0x25A22, 0x25A38,
        0x25A4E, 0x25A64, 0x25A7A, 0x25A90,
        0x25AA6, 0x25ABC, 0x25AD2, 0x25AEF
    ]
    for off in add_eax_offsets:
        buf[off : off + 3] = b'\x90\x90\x90'
    print(f'NOPed out {len(add_eax_offsets)} obsolete Windows XP GetProcAddress + N byte-skips (OpenGL & GetAsyncKeyState)')

    # Convert the 11 OpenGL wrappers (0x1F024..0x1F0C4) from "mov reg, fs:[18]; push [ptr]; ret" to clean "jmp [ptr]"
    gl_wrappers = [
        0x1F024, 0x1F034, 0x1F044, 0x1F054,
        0x1F064, 0x1F074, 0x1F084, 0x1F094,
        0x1F0A4, 0x1F0B4, 0x1F0C4
    ]
    for w in gl_wrappers:
        buf[w : w + 7] = b'\x90' * 7
        buf[w + 7] = 0xFF
        buf[w + 8] = 0x25
        buf[w + 13] = 0x90
    # Wrapper 12 (GetAsyncKeyState at 0x1F0D4)
    buf[0x1F0D4 : 0x1F0D9] = b'\x90' * 5
    buf[0x1F0DF] = 0x90
    print('Converted all 12 OpenGL and user32 wrappers to clean, direct jmp [ptr] thunks')

    # Pre-populate all 12 wrapper pointers in .data so they are NEVER NULL even before worker thread runs!
    wrapper_map = {
        0x2E6EC: 0x1F024, # glGetFloatv
        0x2E6D8: 0x1F0A4, # glDisable
        0x2E6F0: 0x1F034, # glColor4f
        0x2E700: 0x1F074, # glEnd
        0x2E6DC: 0x1F0B4, # glEnable
        0x2E6E4: 0x1F094, # glTexEnvi (Whitewalls!)
        0x2E6F8: 0x1F054, # glClearColor
        0x2E6FC: 0x1F064, # glClear
        0x2E6F4: 0x1F044, # glBlendFunc
        0x2E6E8: 0x1F084, # glDepthRange
        0x2E6E0: 0x1F0C4, # glDepthFunc
        0x2E724: 0x1F0D4, # GetAsyncKeyState
    }
    for ptr_rva, target_rva in wrapper_map.items():
        struct.pack_into('<I', buf, ptr_rva, base_addr + target_rva)
        if ptr_rva not in all_relocs:
            all_relocs.append(ptr_rva)
    all_relocs.sort()
    print('Pre-populated all 12 wrapper pointers in .data and registered in relocations')

    # In worker thread (0x259E0): change GetModuleHandleA('opengl32.dll') to LoadLibraryA('opengl32.dll') (call 0x4C55C80)
    # rel32 = 0x04C55C80 - (0x04C759E0 + 5) = -0x1FD65 = 0xFFFE029B
    buf[0x259E0 : 0x259E5] = b'\xE8\x9B\x02\xFE\xFF'
    print('Patched worker thread at 0x259E0 to use LoadLibraryA("opengl32.dll")')


    clean_rva = 0x161000
    clean_size = 0x20000 # 128 KB
    clean_buf = bytearray(clean_size)

    # Strings in .clean (placed at 0x800 so bootstrap code at offset 0 never collides!)
    str_user32_rva = clean_rva + 0x800
    clean_buf[0x800 : 0x800 + 11] = b'user32.dll\x00'

    str_ntdll_rva = clean_rva + 0x820
    clean_buf[0x820 : 0x820 + 10] = b'ntdll.dll\x00'

    str_NtQIT_rva = clean_rva + 0x840
    clean_buf[0x840 : 0x840 + 25] = b'NtQueryInformationThread\x00'

    # Configuration & Logging paths (placed in clean_rva + 0x11000..0x12000)
    raw_dll_path_rva = clean_rva + 0x11000
    str_ininame_rva  = clean_rva + 0x11200
    str_logname_rva  = clean_rva + 0x11220
    inipath_str_rva  = clean_rva + 0x11300
    logpath_str_rva  = clean_rva + 0x11500

    default_inipath = b'gh0s7h4x12.ini'
    default_logpath = b'debug.log'

    clean_buf[0x11200 : 0x11200 + 16] = b'gh0s7h4x12.ini\x00\x00'
    clean_buf[0x11220 : 0x11220 + 10] = b'debug.log\x00'

    # Delphi AnsiString header for inipath_str: refcount = -1 (constant), length = len(default_inipath)
    clean_buf[0x112F8 : 0x112FC] = b'\xFF\xFF\xFF\xFF'
    clean_buf[0x112FC : 0x11300] = struct.pack('<I', len(default_inipath))
    clean_buf[0x11300 : 0x11300 + len(default_inipath) + 1] = default_inipath + b'\x00'

    # debug.log path pre-populated (ONLY saved in DLL folder)
    clean_buf[0x11500 : 0x11500 + len(default_logpath) + 1] = default_logpath + b'\x00'

    log_messages = {
        'msg_attach': b'[BOOTSTRAP] Injected lolwut_clean.dll into process (DLL_PROCESS_ATTACH)\r\n',
        'msg_ini': b'[CONFIG] Config & logging isolated to DLL folder (gh0s7h4x12.ini & debug.log)\r\n',
        'msg_protect': b'[BOOTSTRAP] Memory page protection set to PAGE_EXECUTE_READWRITE\r\n',
        'msg_reloc': b'[BOOTSTRAP] Base relocations applied successfully (8987 relocations)\r\n',
        'msg_iat': f'[BOOTSTRAP] Dynamic IAT resolved successfully ({len(iat_entries)} functions)\r\n'.encode(),
        'msg_teb': b'[BOOTSTRAP] Universal TEB Finder: Main thread TEB located\r\n',
        'msg_thread': b'[BOOTSTRAP] Spawning cheat worker thread...\r\n',
        'msg_dllmain': b'[BOOTSTRAP] Calling Delphi RTL DllMain initialization...\r\n',
        'msg_dllmain_done': b'[BOOTSTRAP] Delphi RTL DllMain completed successfully!\r\n',
        'msg_success': b'[BOOTSTRAP] DllMain returning TRUE (1) to game/loader\r\n',
        'msg_veh': b'[BOOTSTRAP] Vectored Exception Handler (VEH) registered successfully\r\n',
        'msg_worker_start': b'[WORKER] Cheat worker thread running, waiting for hw.dll...\r\n',
        'msg_worker_done': b'[WORKER] Engine hooks installed successfully! Press INSERT or F12 in-game (in map).\r\n',
    }

    msg_rvas = {}
    curr_msg_off = 0x900
    for name, msg in log_messages.items():
        clean_buf[curr_msg_off : curr_msg_off + len(msg)] = msg
        msg_rvas[name] = (clean_rva + curr_msg_off, len(msg))
        curr_msg_off += len(msg) + 1
        if curr_msg_off % 4 != 0:
            curr_msg_off += (4 - (curr_msg_off % 4))
    print(f'Log messages end at clean_buf offset 0x{curr_msg_off:X}')

    # Patch RVA 0x25ADF: push user32.dll
    buf[0x25ADF : 0x25ADF + 5] = b'\x68' + struct.pack('<I', base_addr + str_user32_rva)

    # Patch RVA 0x2601B: push user32.dll (SetWindowLongA resolution)
    buf[0x2601B : 0x2601B + 5] = b'\x68' + struct.pack('<I', base_addr + str_user32_rva)

    # Patch Delphi INI instantiation at RVA 0x260E9 (24 bytes)
    # Replaces GetCurrentDir + '\gh0s7h4x11.ini' with direct reference to inipath_str_rva
    buf[0x260E9 : 0x260E9 + 5] = b'\xB9' + struct.pack('<I', base_addr + inipath_str_rva)
    buf[0x260EE : 0x260EE + 19] = b'\x90' * 19
    print('Patched Delphi INI creation at 0x260E9 to load DLL directory path into ecx')

    # Patch ini filename string at RVA 0x26A64
    buf[0x26A64 : 0x26A64 + 16] = b'\\gh0s7h4x12.ini\x00'
    print('Patched ini filename string at 0x26A64 -> \\gh0s7h4x12.ini')

    # IAT resolution table at clean_rva + 0x1000
    table_rva = clean_rva + 0x1000
    table_offset = 0x1000
    for rva, mod, fn in iat_entries:
        entry_data = struct.pack('<I', rva) + mod.encode().ljust(16, b'\x00') + fn.encode().ljust(64, b'\x00')
        clean_buf[table_offset : table_offset + len(entry_data)] = entry_data
        table_offset += len(entry_data)
    clean_buf[table_offset : table_offset + 4] = b'\x00\x00\x00\x00'
    print(f'IAT resolution table ends at offset 0x{table_offset:X}')

    # Crash reporting buffers in .clean (offsets 0x10000, 0x10200, 0x10400)
    crash_buffer_rva = clean_rva + 0x10000
    crash_template_rva = clean_rva + 0x10200
    crash_logged_flag_rva = clean_rva + 0x10400
    gl_in_hook_rva = clean_rva + 0x10410

    crash_template = (
        b'\r\n==================== [CRASH DETECTED] ====================\r\n'
        b'Exception Code: 0x{CODE__}\r\n'
        b'Exception Addr: 0x{ADDR__} (Offset in lolwut: 0x{ROFF__})\r\n'
        b'Fault Address:  0x{FLT___}\r\n'
        b'Registers:\r\n'
        b'  EIP: 0x{EIP___}  ESP: 0x{ESP___}  EBP: 0x{EBP___}\r\n'
        b'  EAX: 0x{EAX___}  EBX: 0x{EBX___}  ECX: 0x{ECX___}  EDX: 0x{EDX___}\r\n'
        b'  ESI: 0x{ESI___}  EDI: 0x{EDI___}  EFL: 0x{EFL___}\r\n'
        b'==========================================================\r\n'
    )
    clean_buf[0x10200 : 0x10200 + len(crash_template)] = crash_template
    clean_buf[0x10400 : 0x10404] = b'\x00\x00\x00\x00'
    clean_buf[0x10410 : 0x10414] = b'\x00\x00\x00\x00'

    # Relocation table at clean_rva + 0x5000 (0x1000..0x4FFF reserved for IAT table: NO OVERLAP!)
    reloc_table_rva = clean_rva + 0x5000

    # PE Import Directory for .clean at clean_rva + 0x1A000
    imp_dir_rva = clean_rva + 0x1A000
    iat_k32_rva = clean_rva + 0x1A100
    ilt_k32_rva = clean_rva + 0x1A160
    names_rva   = clean_rva + 0x1A200

    names = [
        b'LoadLibraryA',             # [edi + 0]
        b'GetProcAddress',            # [edi + 4]
        b'CreateThread',              # [edi + 8]
        b'VirtualProtect',            # [edi + 12]
        b'GetCurrentProcessId',       # [edi + 16]
        b'CreateToolhelp32Snapshot',  # [edi + 20]
        b'Thread32First',             # [edi + 24]
        b'Thread32Next',              # [edi + 28]
        b'OpenThread',                # [edi + 32]
        b'CloseHandle',               # [edi + 36]
        b'CreateFileA',               # [edi + 40]
        b'WriteFile',                 # [edi + 44]
        b'SetFilePointer',            # [edi + 48]
        b'OutputDebugStringA',        # [edi + 52]
        b'FlushFileBuffers',          # [edi + 56]
        b'AddVectoredExceptionHandler', # [edi + 60]
        b'GetModuleFileNameA',        # [edi + 64]
    ]
    name_rvas = []
    curr_name_off = 0x1A200
    for n in names:
        clean_buf[curr_name_off : curr_name_off + 2] = b'\x00\x00'
        clean_buf[curr_name_off + 2 : curr_name_off + 2 + len(n) + 1] = n + b'\x00'
        name_rvas.append(clean_rva + curr_name_off)
        curr_name_off += 2 + len(n) + 1
        if curr_name_off % 2 == 1: curr_name_off += 1

    clean_buf[curr_name_off : curr_name_off + 13] = b'kernel32.dll\x00'
    k32_dll_name_rva = clean_rva + curr_name_off

    for idx, nrva in enumerate(name_rvas):
        clean_buf[0x1A100 + idx*4 : 0x1A100 + idx*4 + 4] = struct.pack('<I', nrva)
        clean_buf[0x1A160 + idx*4 : 0x1A160 + idx*4 + 4] = struct.pack('<I', nrva)
    clean_buf[0x1A100 + len(names)*4 : 0x1A100 + len(names)*4 + 4] = b'\x00\x00\x00\x00'
    clean_buf[0x1A160 + len(names)*4 : 0x1A160 + len(names)*4 + 4] = b'\x00\x00\x00\x00'

    desc = struct.pack('<IIIII', ilt_k32_rva, 0, 0, k32_dll_name_rva, iat_k32_rva)
    clean_buf[0x1A000 : 0x1A000 + 20] = desc
    clean_buf[0x1A014 : 0x1A014 + 20] = b'\x00' * 20

    # Build Assembler bootstrap
    a = Assembler()

    def emit_log(msg_name):
        mrva, mlen = msg_rvas[msg_name]
        a.b(b'\x68' + struct.pack('<I', mlen))       # push mlen
        a.b(b'\x89\xD8\x05' + struct.pack('<I', mrva)) # mov eax, ebx; add eax, mrva
        a.b(b'\x50')                                 # push eax
        a.call('log_subroutine')

    # Prologue: push ebp; mov ebp, esp; sub esp, 0x60; push ebx; push esi; push edi
    a.b(b'\x55\x89\xE5\x83\xEC\x60\x53\x56\x57')

    # Check if DLL_PROCESS_ATTACH (1)
    a.b(b'\x83\x7D\x0C\x01')
    a.jne32('exit_success')

    # ebx = hinstDLL
    a.b(b'\x8B\x5D\x08')
    # edi = IAT base (hinstDLL + iat_k32_rva)
    a.b(b'\x89\xDF\x81\xC7' + struct.pack('<I', iat_k32_rva))

    # Log DLL attach
    emit_log('msg_attach')

    # 1. VirtualProtect(hinstDLL, 0x181000, PAGE_EXECUTE_READWRITE, &oldProtect)
    a.b(b'\x8D\x45\xFC\x50')     # lea eax, [ebp - 4]; push eax
    a.b(b'\x6A\x40')             # push 0x40
    a.b(b'\x68\x00\x10\x18\x00') # push 0x181000 (SizeOfImage)
    a.b(b'\x53')                 # push ebx
    a.b(b'\xFF\x57\x0C')         # call [edi + 12] (VirtualProtect)

    emit_log('msg_protect')

    # Dynamic Path Resolution via GetModuleFileNameA
    # Detects where lolwut_clean.dll is loaded from and configures inipath_str and logpath_str
    a.b(b'\x68\x04\x01\x00\x00') # push 260
    a.b(b'\x8D\x83' + struct.pack('<I', raw_dll_path_rva)) # lea eax, [ebx + raw_dll_path_rva]
    a.b(b'\x50')                 # push eax
    a.b(b'\x53')                 # push ebx
    a.b(b'\xFF\x57\x40')         # call [edi + 64] (GetModuleFileNameA)
    a.b(b'\x85\xC0')             # test eax, eax
    a.je('skip_dyn_paths')       # if 0, keep pre-populated paths

    # edx = end of string = ebx + raw_dll_path_rva + eax
    a.b(b'\x8D\x94\x03' + struct.pack('<I', raw_dll_path_rva)) # lea edx, [ebx + eax + raw_dll_path_rva]
    # esi = start of string = ebx + raw_dll_path_rva
    a.b(b'\x8D\xB3' + struct.pack('<I', raw_dll_path_rva)) # lea esi, [ebx + raw_dll_path_rva]

    a.label('scan_slash')
    a.b(b'\x4A')                 # dec edx
    a.b(b'\x39\xF2')             # cmp edx, esi
    a.jb('skip_dyn_paths')       # if edx < esi, no slash found
    a.b(b'\x80\x3A\x5C')         # cmp byte ptr [edx], '\\'
    a.je('found_slash')
    a.b(b'\x80\x3A\x2F')         # cmp byte ptr [edx], '/'
    a.je('found_slash')
    a.jmp('scan_slash')

    a.label('found_slash')
    a.b(b'\x42')                 # inc edx (points right after slash)
    # ecx = dir_len = edx - esi
    a.b(b'\x89\xD1\x29\xF1')     # mov ecx, edx; sub ecx, esi

    # Save edi (IAT base)
    a.b(b'\x57')                 # push edi

    # 1. Copy directory to inipath_str (clean_rva + 0x11300)
    a.b(b'\x8D\xBB' + struct.pack('<I', inipath_str_rva)) # lea edi, [ebx + inipath_str_rva]
    a.b(b'\x56\x51')             # push esi; push ecx
    a.b(b'\xF3\xA4')             # rep movsb
    # Append "gh0s7h4x12.ini\0" (16 bytes)
    a.b(b'\x8D\xB3' + struct.pack('<I', str_ininame_rva)) # lea esi, [ebx + str_ininame_rva]
    a.b(b'\xB9\x10\x00\x00\x00') # mov ecx, 16
    a.b(b'\xF3\xA4')             # rep movsb
    # Update length: eax = (edi - 1) - (ebx + inipath_str_rva)
    a.b(b'\x89\xF8\x48')         # mov eax, edi; dec eax
    a.b(b'\x2D' + struct.pack('<I', inipath_str_rva)) # sub eax, inipath_str_rva
    a.b(b'\x29\xD8')             # sub eax, ebx
    a.b(b'\x89\x83' + struct.pack('<I', inipath_str_rva - 4)) # mov [ebx + inipath_str_rva - 4], eax (length)
    a.b(b'\xC7\x83' + struct.pack('<I', inipath_str_rva - 8) + b'\xFF\xFF\xFF\xFF') # mov [ebx + inipath_str_rva - 8], -1 (refcount)
    a.b(b'\x59\x5E')             # pop ecx; pop esi

    # 2. Copy directory to logpath_str (clean_rva + 0x11500)
    a.b(b'\x8D\xBB' + struct.pack('<I', logpath_str_rva)) # lea edi, [ebx + logpath_str_rva]
    a.b(b'\x56\x51')             # push esi; push ecx
    a.b(b'\xF3\xA4')             # rep movsb
    # Append "debug.log\0" (10 bytes)
    a.b(b'\x8D\xB3' + struct.pack('<I', str_logname_rva)) # lea esi, [ebx + str_logname_rva]
    a.b(b'\xB9\x0A\x00\x00\x00') # mov ecx, 10
    a.b(b'\xF3\xA4')             # rep movsb
    a.b(b'\x59\x5E')             # pop ecx; pop esi

    a.b(b'\x5F')                 # pop edi (restore IAT base)

    a.label('skip_dyn_paths')
    emit_log('msg_ini')

    # Register VEH handler: AddVectoredExceptionHandler(1, veh_handler)
    a.mov_eax_ebx_plus_label('veh_handler')
    a.b(b'\x50')                 # push eax (Handler)
    a.b(b'\x6A\x01')             # push 1   (First = 1)
    a.b(b'\xFF\x57\x3C')         # call [edi + 60] (AddVectoredExceptionHandler)
    emit_log('msg_veh')

    # 2. Check delta = hinstDLL - 0x04C50000
    a.b(b'\x89\xDA')             # mov edx, ebx
    a.b(b'\x81\xEA' + struct.pack('<I', base_addr)) # sub edx, base_addr
    a.je('skip_reloc')           # if delta == 0, skip!

    # Relocation loop:
    a.b(b'\x89\xDE\x81\xC6' + struct.pack('<I', reloc_table_rva)) # mov esi, ebx; add esi, reloc_table_rva
    a.label('reloc_loop')
    a.b(b'\xAD')                 # lodsd
    a.b(b'\x85\xC0')             # test eax, eax
    a.je('skip_reloc')
    a.b(b'\x01\xD8')             # add eax, ebx
    a.b(b'\x01\x10')             # add dword ptr [eax], edx
    a.jmp('reloc_loop')

    a.label('skip_reloc')
    emit_log('msg_reloc')

    # 3. IAT resolution loop:
    a.b(b'\x89\xDE\x81\xC6' + struct.pack('<I', table_rva)) # mov esi, ebx; add esi, table_rva
    a.label('iat_loop')
    a.b(b'\x83\x3E\x00')         # cmp dword ptr [esi], 0
    a.je('done_iat')

    a.b(b'\x8D\x46\x04\x50')     # lea eax, [esi + 4]; push eax
    a.b(b'\xFF\x17')             # call [edi] (LoadLibraryA)
    a.b(b'\x85\xC0')             # test eax, eax
    a.je('iat_next')

    a.b(b'\x8D\x4E\x14\x51\x50') # lea ecx, [esi + 20]; push ecx; push eax
    a.b(b'\xFF\x57\x04')         # call [edi + 4] (GetProcAddress)
    a.b(b'\x85\xC0')             # test eax, eax
    a.je('iat_next')

    a.b(b'\x8B\x0E\x01\xD9')     # mov ecx, [esi]; add ecx, ebx
    a.b(b'\x89\x01')             # mov [ecx], eax

    a.label('iat_next')
    a.b(b'\x83\xC6\x54')         # add esi, 84
    a.jmp('iat_loop')

    a.label('done_iat')
    emit_log('msg_iat')

    # 4. Universal TEB Finder
    a.b(b'\x31\xC0\x89\x45\xFC\x89\x45\xF8')
    a.b(b'\xFF\x57\x10\x89\x45\xFC')
    a.b(b'\x6A\x00\x6A\x04\xFF\x57\x14')
    a.b(b'\x89\xC6\x83\xF8\xFF')
    a.je32('done_teb')
    a.b(b'\x85\xC0')
    a.je32('done_teb')

    a.b(b'\xC7\x45\xD8\x1C\x00\x00\x00')
    a.b(b'\x8D\x45\xD8\x50\x56\xFF\x57\x18')
    a.b(b'\x85\xC0')
    a.je('close_snap')

    a.label('te_loop')
    a.b(b'\x8B\x45\xE4\x3B\x45\xFC')
    a.jne('te_next')

    a.b(b'\x8B\x45\xE0\x89\x45\xF8')
    a.jmp('close_snap')

    a.label('te_next')
    a.b(b'\x8D\x45\xD8\x50\x56\xFF\x57\x1C')
    a.b(b'\x85\xC0')
    a.jne('te_loop')

    a.label('close_snap')
    a.b(b'\x56\xFF\x57\x24')

    a.b(b'\x83\x7D\xF8\x00')
    a.je32('done_teb')

    a.b(b'\xFF\x75\xF8\x6A\x00\x6A\x40\xFF\x57\x20')
    a.b(b'\x85\xC0')
    a.je32('done_teb')
    a.b(b'\x89\xC6')

    a.b(b'\x8D\x83' + struct.pack('<I', str_ntdll_rva) + b'\x50\xFF\x17')
    a.b(b'\x85\xC0')
    a.je('close_th')

    a.b(b'\x8D\x8B' + struct.pack('<I', str_NtQIT_rva) + b'\x51\x50\xFF\x57\x04')
    a.b(b'\x85\xC0')
    a.je('close_th')

    a.b(b'\x6A\x00\x6A\x1C\x8D\x4D\xB8\x51\x6A\x00\x56\xFF\xD0')
    a.b(b'\x85\xC0')
    a.js('close_th')

    a.b(b'\x8B\x45\xBC\x89\x83\x0C\xB1\x02\x00')
    a.b(b'\xC7\x83\x10\xB1\x02\x00\x01\x00\x00\x00')

    a.label('close_th')
    a.b(b'\x56\xFF\x57\x24')

    a.label('done_teb')
    emit_log('msg_teb')

    # 5. CreateThread: spawns cheat_thread_wrapper with ebx (hinstDLL) as lpParameter!
    emit_log('msg_thread')
    a.b(b'\x6A\x00\x6A\x00')     # lpThreadId (NULL), dwCreationFlags (0)
    a.b(b'\x53')                 # push ebx (lpParameter = hinstDLL)
    a.mov_eax_ebx_plus_label('cheat_thread_wrapper')
    a.b(b'\x50')                 # push eax (lpStartAddress)
    a.b(b'\x6A\x00\x6A\x00')     # dwStackSize (0), lpThreadAttributes (NULL)
    a.b(b'\xFF\x57\x08')         # call [edi + 8] (CreateThread)

    # 6. Delphi DllMain: (hinstDLL + 0x26F80)(hinstDLL, fdwReason, lpvReserved)
    emit_log('msg_dllmain')
    a.b(b'\xFF\x75\x10\xFF\x75\x0C\xFF\x75\x08')
    a.b(b'\x89\xD8\x05\x80\x6F\x02\x00')     # mov eax, ebx; add eax, 0x26F80
    a.b(b'\xFF\xD0')                         # call eax
    emit_log('msg_dllmain_done')

    emit_log('msg_success')

    a.label('exit_success')
    a.b(b'\xB8\x01\x00\x00\x00')             # mov eax, 1
    a.b(b'\x5F\x5E\x5B\x89\xEC\x5D\xC2\x0C\x00') # pop edi; pop esi; pop ebx; mov esp, ebp; pop ebp; ret 12

    # Now define cheat_thread_wrapper, log_subroutine, append_to_file
    a.label('cheat_thread_wrapper')
    a.b(b'\x55\x89\xE5\x53\x56\x57')         # push ebp; mov ebp, esp; push ebx; push esi; push edi
    a.b(b'\x8B\x5D\x08')                     # mov ebx, [ebp + 8] (hinstDLL)
    a.b(b'\x89\xDF\x81\xC7' + struct.pack('<I', iat_k32_rva)) # edi = IAT base
    emit_log('msg_worker_start')
    a.b(b'\x6A\x00')                         # push 0 (dummy arg)
    a.b(b'\x89\xD8\x05\x9C\x59\x02\x00') # mov eax, ebx; add eax, 0x2599C
    a.b(b'\xFF\xD0')                         # call eax (original cheat thread)
    a.b(b'\x83\xC4\x04')                     # add esp, 4
    emit_log('msg_worker_done')
    a.b(b'\x5F\x5E\x5B\x89\xEC\x5D\xC2\x04\x00') # pop edi; pop esi; pop ebx; mov esp, ebp; pop ebp; ret 4

    a.label('log_subroutine')
    a.b(b'\x55\x89\xE5\x53\x56\x57')         # push ebp; mov ebp, esp; push ebx; push esi; push edi
    a.b(b'\xFF\x75\x08')                     # push [ebp + 8] (msg)
    a.b(b'\xFF\x57\x34')                     # call [edi + 52] (OutputDebugStringA)
    # Log ONLY to DLL directory (logpath_str_rva)
    a.b(b'\xFF\x75\x0C')                     # push [ebp + 12] (len)
    a.b(b'\xFF\x75\x08')                     # push [ebp + 8]  (msg)
    a.b(b'\x89\xD8\x05' + struct.pack('<I', logpath_str_rva)) # mov eax, ebx; add eax, logpath_str_rva
    a.b(b'\x50')                             # push eax
    a.call('append_to_file')
    a.b(b'\x5F\x5E\x5B\x89\xEC\x5D\xC2\x08\x00') # pop edi; pop esi; pop ebx; mov esp, ebp; pop ebp; ret 8

    a.label('append_to_file')
    a.b(b'\x55\x89\xE5\x83\xEC\x08\x53\x56\x57') # push ebp; mov ebp, esp; sub esp, 8; push ebx; push esi; push edi
    # CreateFileA(path, 0x40000000, 3, 0, 4, 0x80, 0)
    a.b(b'\x6A\x00')                         # push 0
    a.b(b'\x68\x80\x00\x00\x00')             # push 0x80 (FILE_ATTRIBUTE_NORMAL)
    a.b(b'\x6A\x04')                         # push 4    (OPEN_ALWAYS)
    a.b(b'\x6A\x00')                         # push 0
    a.b(b'\x6A\x03')                         # push 3    (FILE_SHARE_READ | FILE_SHARE_WRITE)
    a.b(b'\x68\x00\x00\x00\x40')             # push 0x40000000 (GENERIC_WRITE)
    a.b(b'\xFF\x75\x08')                     # push [ebp + 8] (path)
    a.b(b'\xFF\x57\x28')                     # call [edi + 40] (CreateFileA)
    a.b(b'\x83\xF8\xFF')                     # cmp eax, -1
    a.je('app_done')
    a.b(b'\x85\xC0')                         # test eax, eax
    a.je('app_done')
    a.b(b'\x89\xC6')                         # mov esi, eax (hFile)
    # SetFilePointer(hFile, 0, NULL, 2)
    a.b(b'\x6A\x02')                         # push 2 (FILE_END)
    a.b(b'\x6A\x00')                         # push 0
    a.b(b'\x6A\x00')                         # push 0
    a.b(b'\x56')                             # push esi
    a.b(b'\xFF\x57\x30')                     # call [edi + 48] (SetFilePointer)
    # WriteFile(hFile, msg, len, &written, 0)
    a.b(b'\x6A\x00')                         # push 0
    a.b(b'\x8D\x4D\xFC\x51')                 # lea ecx, [ebp - 4]; push ecx
    a.b(b'\xFF\x75\x10')                     # push [ebp + 16] (len)
    a.b(b'\xFF\x75\x0C')                     # push [ebp + 12] (msg)
    a.b(b'\x56')                             # push esi
    a.b(b'\xFF\x57\x2C')                     # call [edi + 44] (WriteFile)
    # FlushFileBuffers(hFile)
    a.b(b'\x56\xFF\x57\x38') # push esi; call [edi + 56]
    # CloseHandle(hFile)
    a.b(b'\x56')                             # push esi
    a.b(b'\xFF\x57\x24')                     # call [edi + 36] (CloseHandle)
    a.label('app_done')
    a.b(b'\x5F\x5E\x5B\x89\xEC\x5D\xC2\x0C\x00') # pop edi; pop esi; pop ebx; mov esp, ebp; pop ebp; ret 12

    # Vectored Exception Handler (VEH)
    a.label('veh_handler')
    # stdcall: [esp + 4] = PEXCEPTION_POINTERS
    a.b(b'\x55\x89\xE5\x83\xEC\x20\x53\x56\x57') # push ebp; mov ebp, esp; sub esp, 0x20; push ebx; push esi; push edi

    # Recover ImageBase in ebx:
    a.mov_ebx_image_base()
    # edi = IAT base (ebx + iat_k32_rva)
    a.b(b'\x89\xDF\x81\xC7' + struct.pack('<I', iat_k32_rva))

    # esi = pExcInfo = [ebp + 8]
    a.b(b'\x8B\x75\x08')
    a.b(b'\x85\xF6')
    a.je32('veh_exit')

    # eax = pExceptionRecord = [esi]
    a.b(b'\x8B\x06')
    a.b(b'\x85\xC0')
    a.je32('veh_exit')

    # edx = ExceptionCode = [eax]
    a.b(b'\x8B\x10')

    # Filter out benign/internal exceptions:
    # 0x406D1388 (Thread Name)
    a.b(b'\x81\xFA\x88\x13\x6D\x40')
    a.je32('veh_exit')
    # 0x0EEDFADE (Delphi internal)
    a.b(b'\x81\xFA\xDE\xFA\xED\x0E')
    a.je32('veh_exit')
    # 0xE06D7363 (VC++ internal)
    a.b(b'\x81\xFA\x63\x73\x6D\xE0')
    a.je32('veh_exit')
    # 0x80000003 (Breakpoint)
    a.b(b'\x81\xFA\x03\x00\x00\x80')
    a.je32('veh_exit')
    # 0x80000004 (Single Step)
    a.b(b'\x81\xFA\x04\x00\x00\x80')
    a.je32('veh_exit')
    # test edx, 0x80000000 (must be error or warning)
    a.b(b'\xF7\xC2\x00\x00\x00\x80')
    a.je32('veh_exit')

    # Check crash_logged_flag at ebx + crash_logged_flag_rva
    a.b(b'\x80\xBB' + struct.pack('<I', crash_logged_flag_rva) + b'\x00')
    a.jne32('veh_exit')
    a.b(b'\xC6\x83' + struct.pack('<I', crash_logged_flag_rva) + b'\x01') # set to 1!

    # Save pExceptionRecord in [ebp - 4], pContextRecord in [ebp - 8], iat_k32 in [ebp - 12]
    a.b(b'\x89\x45\xFC')                         # mov [ebp - 4], eax (pExceptionRecord)
    a.b(b'\x8B\x4E\x04\x89\x4D\xF8')             # mov ecx, [esi + 4]; mov [ebp - 8], ecx (pContextRecord)
    a.b(b'\x89\x7D\xF4')                         # mov [ebp - 12], edi (iat_k32)

    # Copy template to crash_buffer:
    # esi = ebx + crash_template_rva
    # edi = ebx + crash_buffer_rva
    # ecx = 425
    # rep movsb
    a.b(b'\x8D\xB3' + struct.pack('<I', crash_template_rva))
    a.b(b'\x8D\xBB' + struct.pack('<I', crash_buffer_rva))
    a.b(b'\xB9\xA9\x01\x00\x00')                 # mov ecx, 425
    a.b(b'\xF3\xA4')                             # rep movsb

    # 1. ExceptionCode: [pExceptionRecord + 0] -> tag offset 80 (0x50)
    a.b(b'\x8B\x45\xFC\x8B\x00')                 # mov eax, [ebp - 4]; mov eax, [eax]
    a.b(b'\x8D\xBB' + struct.pack('<I', crash_buffer_rva + 80)) # lea edi, [ebx + crash_buffer_rva + 80]
    a.call('format_hex_dw')

    # 2. ExceptionAddress: [pExceptionRecord + 12] -> tag offset 108 (0x6C)
    a.b(b'\x8B\x45\xFC\x8B\x40\x0C')             # mov eax, [ebp - 4]; mov eax, [eax + 12]
    a.b(b'\x89\x45\xF0')                         # mov [ebp - 16], eax (save ExceptionAddress)
    a.b(b'\x8D\xBB' + struct.pack('<I', crash_buffer_rva + 108)) # lea edi, [ebx + crash_buffer_rva + 108]
    a.call('format_hex_dw')

    # 3. Offset in lolwut: ExceptionAddress - ImageBase -> tag offset 138 (0x8A)
    a.b(b'\x8B\x45\xF0\x29\xD8')                 # mov eax, [ebp - 16]; sub eax, ebx
    a.b(b'\x8D\xBB' + struct.pack('<I', crash_buffer_rva + 138)) # lea edi, [ebx + crash_buffer_rva + 138]
    a.call('format_hex_dw')

    # 4. FaultAddress: [pExceptionRecord + 24] -> tag offset 167 (0xA7)
    a.b(b'\x8B\x45\xFC\x8B\x40\x18')             # mov eax, [ebp - 4]; mov eax, [eax + 24] (ExceptionInformation[1])
    a.b(b'\x8D\xBB' + struct.pack('<I', crash_buffer_rva + 167)) # lea edi, [ebx + crash_buffer_rva + 167]
    a.call('format_hex_dw')

    # 5. Registers from ContextRecord ([ebp - 8]):
    reg_fields = [
        (0xB8, 198), # EIP
        (0xC4, 215), # ESP
        (0xB4, 232), # EBP
        (0xB0, 251), # EAX
        (0xA4, 268), # EBX
        (0xAC, 285), # ECX
        (0xA8, 302), # EDX
        (0xA0, 321), # ESI
        (0x9C, 338), # EDI
        (0xC0, 355), # EFLAGS
    ]
    for ctx_off, tag_pos in reg_fields:
        a.b(b'\x8B\x4D\xF8\x8B\x81' + struct.pack('<I', ctx_off)) # mov ecx, [ebp - 8]; mov eax, [ecx + ctx_off]
        a.b(b'\x8D\xBB' + struct.pack('<I', crash_buffer_rva + tag_pos)) # lea edi, [ebx + crash_buffer_rva + tag_pos]
        a.call('format_hex_dw')

    # Restore edi = iat_k32 from [ebp - 12]
    a.b(b'\x8B\x7D\xF4')

    # Output crash_buffer via log_subroutine: push 425; push crash_buffer; call log_subroutine
    a.b(b'\x68\xA9\x01\x00\x00')                 # push 425
    a.b(b'\x8D\x83' + struct.pack('<I', crash_buffer_rva) + b'\x50') # lea eax, [ebx + crash_buffer_rva]; push eax
    a.call('log_subroutine')

    a.label('veh_exit')
    a.b(b'\x31\xC0')                             # xor eax, eax (EXCEPTION_CONTINUE_SEARCH = 0)
    a.b(b'\x5F\x5E\x5B\x89\xEC\x5D\xC2\x04\x00') # pop edi; pop esi; pop ebx; mov esp, ebp; pop ebp; ret 4

    # format_hex_dw subroutine: eax = val, edi = dest
    a.label('format_hex_dw')
    a.b(b'\x50\x51\x52\x57')                     # push eax; push ecx; push edx; push edi
    a.b(b'\xB9\x08\x00\x00\x00')                 # mov ecx, 8
    a.label('hex_loop')
    a.b(b'\xC1\xC0\x04')                         # rol eax, 4
    a.b(b'\x88\xC2\x80\xE2\x0F\x80\xC2\x30')     # mov dl, al; and dl, 0xF; add dl, '0'
    a.b(b'\x80\xFA\x39\x7E\x03\x80\xC2\x07')     # cmp dl, '9'; jle +3; add dl, 7
    a.b(b'\x88\x17\x47')                         # mov [edi], dl; inc edi
    a.b(b'\xE2\xE8')                             # loop hex_loop
    a.b(b'\x5F\x5A\x59\x58\xC3')                 # pop edi; pop edx; pop ecx; pop eax; ret

    # Safe Asuswallhack Check 1 (detour for RVA 0x2513C)
    a.label('safe_asus_check1')
    a.b(b'\xA1\x98\xE6\xC7\x04') # mov eax, [0x04C7E698]
    a.b(b'\x85\xC0')             # test eax, eax
    a.jz('asus_skip1')           # if NULL, skip!
    a.b(b'\xF7\x80\xB8\x00\x00\x00\x00\x02\x00\x00') # test dword ptr [eax + 0xb8], 0x200
    a.jle('asus_skip1')          # if not set, skip!
    a.jmp32_rva(0x25151)         # proceed with Asuswallhack
    a.label('asus_skip1')
    a.jmp32_rva(0x252BD)         # skip Asuswallhack

    # Safe Wallhack Check 2 (detour for RVA 0x252E6)
    a.label('safe_asus_check2')
    a.b(b'\xA1\x98\xE6\xC7\x04') # mov eax, [0x04C7E698]
    a.b(b'\x85\xC0')             # test eax, eax
    a.jz('asus_skip2')           # if NULL, skip!
    a.b(b'\xF6\x80\xB9\x00\x00\x00\x02') # test byte ptr [eax + 0xb9], 2
    a.jne('asus_skip2')          # if bit 1 set, skip!
    a.b(b'\x66\x83\x63\x1E\xFD') # and word ptr [ebx + 0x1e], 0xfffd
    a.label('asus_skip2')
    a.jmp32_rva(0x252F9)         # resume

    # Safe GetProcAddress Hook Guard (detour for RVA 0x257C4)
    # Prevents Access Violation (0xC0000005) when called with ordinals or non-user pointers (e.g. 0xD4900495)
    a.label('safe_getproc')
    a.b(b'\x8B\x44\x24\x04')     # mov eax, dword ptr [esp + 4] (lpProcName)
    a.b(b'\x3D\x00\x00\x01\x00') # cmp eax, 0x10000
    a.jb('getproc_ret_zero')     # if ordinal (< 0x10000), return 0
    a.b(b'\x3D\x00\x00\xFE\x7F') # cmp eax, 0x7FFE0000
    a.jae('getproc_ret_zero')    # if kernel/invalid (>= 0x7FFE0000), return 0
    # Valid user pointer: execute replaced original 5 bytes and jump to 0x257C9
    a.b(b'\x55\x89\xE5\x31\xC9') # push ebp; mov ebp, esp; xor ecx, ecx
    a.jmp32_rva(0x257C9)
    a.label('getproc_ret_zero')
    a.b(b'\x31\xC0\xC2\x04\x00') # xor eax, eax; ret 4

    # Reentrancy Guard for glBegin (detour for RVA 0x25410 & 0x25706)
    # Prevents infinite recursion Stack Overflow (0xC00000FD) when glClear or OpenGL driver re-enters glBegin
    a.label('safe_glbegin')
    # cmp byte ptr [base_addr + gl_in_hook_rva], 0
    a.b(b'\x80\x3D' + struct.pack('<I', base_addr + gl_in_hook_rva) + b'\x00')
    a.jne('glbegin_reentrant')
    # Set reentrancy flag: mov byte ptr [base_addr + gl_in_hook_rva], 1
    a.label('safe_glbegin_set_flag')
    a.b(b'\xC6\x05' + struct.pack('<I', base_addr + gl_in_hook_rva) + b'\x01')
    # Execute replaced original prologue of 0x25410 (10 bytes):
    # push ebp; mov ebp, esp; add esp, -0x14; push ebx; mov ebx, dword ptr [ebp + 8]
    a.b(b'\x55\x89\xE5\x83\xEC\x14\x53\x8B\x5D\x08')
    a.jmp32_rva(0x2541A)

    a.label('glbegin_reentrant')
    # Direct passthrough to original glBegin: mov eax, [base_addr + 0x2E72C]
    a.b(b'\xA1' + struct.pack('<I', base_addr + 0x2E72C))
    a.b(b'\x85\xC0')             # test eax, eax
    a.jz('glbegin_reentrant_ret')
    a.b(b'\xFF\xE0')             # jmp eax (tail call to original glBegin, transparently preserving stack)
    a.label('glbegin_reentrant_ret')
    a.b(b'\xC2\x04\x00')         # ret 4

    a.label('safe_glbegin_exit')
    # Clear reentrancy flag: mov byte ptr [base_addr + gl_in_hook_rva], 0
    a.b(b'\xC6\x05' + struct.pack('<I', base_addr + gl_in_hook_rva) + b'\x00')
    # Execute original exit sequence of 0x25706 (7 bytes):
    # pop ebx; mov esp, ebp; pop ebp; ret 4
    a.b(b'\x5B\x89\xEC\x5D\xC2\x04\x00')

    code = a.build(clean_rva)
    clean_buf[0 : len(code)] = code
    print(f'Wrote Position-Independent Bootstrap with Debug Logging ({len(code)} bytes) at RVA 0x{clean_rva:X}')

    # Detour RVA 0x2513C (21 bytes) -> safe_asus_check1
    asus1_target = a.labels['safe_asus_check1']
    rel1 = asus1_target - (0x2513C + 5)
    buf[0x2513C : 0x2513C + 21] = b'\xE9' + struct.pack('<i', rel1) + b'\x90' * 16

    # Detour RVA 0x252E6 (19 bytes) -> safe_asus_check2
    asus2_target = a.labels['safe_asus_check2']
    rel2 = asus2_target - (0x252E6 + 5)
    buf[0x252E6 : 0x252E6 + 19] = b'\xE9' + struct.pack('<i', rel2) + b'\x90' * 14

    # Detour RVA 0x257C4 (5 bytes) -> safe_getproc
    gp_target = a.labels['safe_getproc']
    rel_gp = gp_target - (0x257C4 + 5)
    buf[0x257C4 : 0x257C4 + 5] = b'\xE9' + struct.pack('<i', rel_gp)

    # Detour RVA 0x25410 (10 bytes) -> safe_glbegin
    gb_target = a.labels['safe_glbegin']
    rel_gb = gb_target - (0x25410 + 5)
    buf[0x25410 : 0x25410 + 10] = b'\xE9' + struct.pack('<i', rel_gb) + b'\x90' * 5

    # Detour RVA 0x25706 (7 bytes) -> safe_glbegin_exit
    gbe_target = a.labels['safe_glbegin_exit']
    rel_gbe = gbe_target - (0x25706 + 5)
    buf[0x25706 : 0x25706 + 7] = b'\xE9' + struct.pack('<i', rel_gbe) + b'\x90\x90'

    # Add the new relocations for the pointers in .clean
    all_relocs.append(a.labels['safe_asus_check1'] + 1)
    all_relocs.append(a.labels['safe_asus_check2'] + 1)
    all_relocs.append(a.labels['safe_glbegin'] + 2)
    all_relocs.append(a.labels['safe_glbegin_set_flag'] + 2)
    all_relocs.append(a.labels['glbegin_reentrant'] + 1)
    all_relocs.append(a.labels['safe_glbegin_exit'] + 2)
    all_relocs.sort()

    # Write relocation table at clean_rva + 0x5000
    reloc_offset = 0x5000
    for off in all_relocs:
        clean_buf[reloc_offset : reloc_offset + 4] = struct.pack('<I', off)
        reloc_offset += 4
    clean_buf[reloc_offset : reloc_offset + 4] = b'\x00\x00\x00\x00'
    print(f'Relocation table ({len(all_relocs)} relocations) serialized at offset 0x{reloc_offset:X}')

    full_image = buf + clean_buf

    # Update PE Headers
    e_lfanew = struct.unpack_from('<I', full_image, 0x3C)[0]
    opt_hdr = e_lfanew + 4 + 20

    # 1. NumberOfSections = 9
    num_sections = struct.unpack_from('<H', full_image, e_lfanew + 4 + 2)[0]
    struct.pack_into('<H', full_image, e_lfanew + 4 + 2, num_sections + 1)

    # 2. AddressOfEntryPoint = clean_rva
    struct.pack_into('<I', full_image, opt_hdr + 16, clean_rva)

    # 3. ImageBase = base_addr
    struct.pack_into('<I', full_image, opt_hdr + 28, base_addr)

    # 4. SectionAlignment = 0x1000, FileAlignment = 0x1000
    struct.pack_into('<I', full_image, opt_hdr + 32, 0x1000)
    struct.pack_into('<I', full_image, opt_hdr + 36, 0x1000)

    # 5. SizeOfImage = len(full_image)
    struct.pack_into('<I', full_image, opt_hdr + 56, len(full_image))

    # 6. DllCharacteristics = 0
    struct.pack_into('<H', full_image, opt_hdr + 70, 0)

    # 7. DataDirectory imports
    data_dir_off = opt_hdr + 96
    struct.pack_into('<II', full_image, data_dir_off + 8, imp_dir_rva, 40)
    struct.pack_into('<II', full_image, data_dir_off + 96, iat_k32_rva, (len(names) + 1) * 4)

    # 8. Update existing 8 sections
    sec_hdr_start = opt_hdr + struct.unpack_from('<H', full_image, e_lfanew + 4 + 16)[0]
    for i in range(num_sections):
        s_off = sec_hdr_start + i * 40
        s_name = full_image[s_off : s_off + 8].decode('latin1').strip('\x00')
        va = struct.unpack_from('<I', full_image, s_off + 12)[0]
        vsize = struct.unpack_from('<I', full_image, s_off + 8)[0]
        raw_size = (vsize + 0xFFF) & ~0xFFF
        struct.pack_into('<I', full_image, s_off + 16, raw_size)
        struct.pack_into('<I', full_image, s_off + 20, va)
        struct.pack_into('<I', full_image, s_off + 36, 0xE0000060)

    # 9. Add 9th section .clean
    clean_sec_off = sec_hdr_start + num_sections * 40
    clean_sec_hdr = bytearray(40)
    clean_sec_hdr[0:6] = b'.clean'
    struct.pack_into('<I', clean_sec_hdr, 8, clean_size)
    struct.pack_into('<I', clean_sec_hdr, 12, clean_rva)
    struct.pack_into('<I', clean_sec_hdr, 16, clean_size)
    struct.pack_into('<I', clean_sec_hdr, 20, clean_rva)
    struct.pack_into('<I', clean_sec_hdr, 36, 0xE0000060)
    full_image[clean_sec_off : clean_sec_off + 40] = clean_sec_hdr

    with open(out_path, 'wb') as f:
        f.write(full_image)

    print(f'Successfully built {out_path} ({len(full_image)} bytes)!')

if __name__ == '__main__':
    main()
