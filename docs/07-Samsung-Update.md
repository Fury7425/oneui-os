# 07 — Samsung Update (SU3) — design overview

Scope of this doc: component roles, data layout, configuration and update-pipeline design. It deliberately stays at architecture level.

## 1. Purpose

Delivers drivers, BIOS, patches and Samsung software for the specific model, region and OS, and supports offline "media" installs. On this host Device Care's Live Update (doc 04) provides the main UI; the SU3 service, engine and user-mode worker remain installed and running.

## 2. Packaging

| Item | Value |
|---|---|
| Location | `C:\Program Files\Samsung\SamsungUpdate\` (Win32 install) |
| Version | 3.0.110.0 (`SU.dll`, `SUEngine.exe`, .NET Framework 4.8.1) |
| Service | `SamsungUpdateService` → `SUService.exe` (native C++, auto, LocalSystem) |
| Engine | `SUEngine.exe` (headless WPF host) |
| User-mode worker | `SUUserModeWorker.exe`, started by scheduled task `\Samsung\SamsungUpdate\UserModeWorker` (observed running) |
| Media installer | `MediaInstaller\MediaInstaller.exe`, with copies staged under `C:\ProgramData\Samsung\SamsungUpdate3\<date>\<guid>\MediaInstaller\` |
| Libraries | `SU.dll` (core), `CommonInterface.dll`, `IPCInterface.dll`, `Platform.dll`, `Wrapper.dll` (C++/CLI), `SUReSupport.dll`, `SupportCPP.dll` (native), `QHsm.dll` (hierarchical state machine), `SharmIpc.dll`, SQLite, Serilog, App Center analytics |

The native service is built on the same `secsc` service framework used by the Galaxy Book Experience service and the Platform Engine (docs 08, 13).

## 3. Architecture

Three cooperating processes with a clear privilege split:

- **Service (SYSTEM)**: lifecycle and event loop (`SUServiceMgr`), power and device notifications, service config (`SU3Service.cfg`: log level, start-up type, delay, retry). Keeps the engine alive.
- **Engine (admin context)**: the work queue. `EngineScenarioWorker` handles client requests (single download, bulk download, set test settings, initialise client info, service messages), updates the scheduled-task start time, and can launch the client by URI.
- **User-mode worker (user session)**: toasts and notifications, client start and restart, remote calls from the engine.

Engine and clients talk over `SharmIpc` (shared-memory / named-pipe RPC), the same library Device Care uses.

## 4. Data layout (`C:\ProgramData\Samsung\SamsungUpdate3\`)

| Path | Content |
|---|---|
| `config\SU3Engine.cfg` | JSON: last update / notify / auto-update times, catalogue revisions (HDM, AddSW, Patch, Policy, ClientPolicy, UWA), model name, download path, `CheckServerPeriod` and `AutoUpdatePeriod` (both 1440 min), EULA flag |
| `config\SU3Service.cfg`, `SU3Media.cfg` | service and media-mode settings |
| `metadata\*.CACHE` | catalogue snapshots keyed by revision hash |
| `metadata\ItemInfo.db`, `PolicyInfo.db`, `SysMon.db`, `InstallCount.db`, `ConfigInfo.db`, `Statistics.dat` | item catalogue, policy, system-monitor samples, install counters |
| `data\`, `history\`, `log\` | working data, install history, logs |
| `<yyyymmdd>\<guid>\` | staged media-installer copies with image-package manifests |

## 5. Update pipeline (design)

1. **Refresh**: engine fetches a model-specific catalogue (revision hashes in config decide what changed) and a policy set; results are cached in `metadata\`.
2. **Filter**: `Filtering` drops duplicates, wrong item types, items blocked by device or policy rules (including ROL rules).
3. **Plan**: each item has an identity (CIS code or BIOS version, hashed), category (BIOS, driver, patch, AddSW), install command type and verification type.
4. **Download and verify**: single or bulk download to the configured path; signature or digest verification before install.
5. **Install**: tracked in `InstallStatusDB` records `{Id, CIS, Rev, Stage, Status, CmdSeq, Silent}` so interrupted installs resume; BIOS items are gated on AC power and battery level.
6. **Report**: install history and statistics are sent back (`sendHistory`) and counted locally.

A server-interface layer (`ServerInterface`) covers model revision, model lookup by name or serial, supported OS per model, download lists, BIOS update items, file size and CRC checks.

## 6. Network surface

Catalogue and file downloads go to Samsung's `orcaservice.samsungmobile.com` (HTTPS on port 10443, and HTTP variants), BIOS items from `appmanager.samsungmobile.com` (HTTP). Because some paths are plain HTTP, integrity depends on the client-side signature and digest checks. Store-app availability is also queried from the Microsoft Store.

## 7. Observations

- Debug symbols (`*.pdb`, including a 9.8 MB `SUService.pdb`) are shipped in the install folder.
- Config and catalogue data in ProgramData include the machine model name; the serial number is kept out of `SU3Engine.cfg` (null on this host).
- The updater overlaps with Device Care Live Update (doc 04); two update stacks coexist.

## 8. Evidence and unknowns

REA: `SU.dll` `ev_06cfb714c2faade6ed0c8b803017a556cbc5e7b3190432a1d82e4fda11bf48f6`, `SUEngine.exe` `ev_ea7053ca5dd050cb9870cb5a774574dd6edd0b737b3d79fbb1a793ae801a040d` (see `recon/rea_evidence_index.txt`); `SUService.exe` sha256 `b38b13df…d275f2`. Dumps: `recon/md/Samsung/{SU,SUEngine,SUUserModeWorker,MediaInstaller,Platform,CommonInterface}*.txt`.

Unknown: catalogue request/response schema, exact verification policy per item type, IPC channel names and access control.
