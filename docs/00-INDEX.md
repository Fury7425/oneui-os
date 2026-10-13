# Samsung PC Software Suite — Reverse-Engineered Engineering & Design Docs

Host analysed: Samsung Galaxy Book (model string `NT940XGQ-A71AG`, BIOS `P13VAG.810.251121.04`), Windows 11 Pro 10.0.26300, analysed 2026-10-12.
Method: static analysis of shipped artifacts (REA managed-artifact / native-boundary passes, PE import/export/string triage, .NET metadata dumps), package manifests, INF files, registry and on-disk state, and the apps' own logs. No target code was executed and no IPC endpoint was exercised.

## Per-app documents

Each document covers: purpose, packaging & deployment, architecture (process / trust boundaries), component engineering, IPC & integration contracts, data & state, network endpoints, UI/UX design, key runtime flows, security & privacy observations, evidence and open unknowns.

| # | Document | Product(s) covered | Primary package / location |
|---|----------|--------------------|----------------------------|
| 01 | [Samsung Settings](01-Samsung-Settings.md) | Samsung Settings 1.5, Settings Runtime, System Support Engine/Service/OSD, SCAI driver | `SamsungSettings1.5_8.0.13.0`, `SamsungSettingsRuntime_7.0.6.0`, DriverStore `sfourswcomp15` |
| 02 | [Quick Share](02-Quick-Share.md) | Quick Share, Private Share, Google Quick Share interop | `SamsungQuickShare_2.3.22.0` |
| 03 | [Camera Share](03-Camera-Share.md) | Camera Share (phone-as-webcam + mic) | `16297BCCB59BC_2.3.12.0` |
| 04 | [Device Care](04-Device-Care.md) | Samsung Device Care (cleaner, storage, recovery, live update, maintenance mode) | `SamsungPCCleaner_4.0.80.0` + `C:\Program Files\Samsung\SamsungDeviceCare` |
| 05 | [Galaxy Connect / Continuity](05-Galaxy-Connect-Continuity.md) | Galaxy Connect, MCF Core, Storage Share, Continue Apps, Clipboard, Auto Hotspot, Wi-Fi share, Family MDE, Multi Control helpers | `SamsungContinuityService_4.6.1217.0` |
| 06 | [Samsung Account](06-Samsung-Account.md) | Samsung Account client + SSO hub | `SamsungAccount_1.26.6021.0` |
| 07 | [Samsung Update](07-Samsung-Update.md) (design overview) | Samsung Update (SU3) | `C:\Program Files\Samsung\SamsungUpdate` |
| 08 | [Galaxy Book Experience](08-Galaxy-Book-Experience.md) | Samsung Welcome / Galaxy Book Experience + GBExperience service | `SamsungWelcome_3.9.4.0` |
| 09 | [Samsung Cloud Platform Manager](09-Samsung-Cloud-Platform-Manager.md) | Samsung Cloud (SCPM), Sync Viewer, MDE viewer | `SamsungCloudPlatformManag_2.2.5.0` |
| 10 | [Knox Matrix](10-Knox-Matrix.md) | Knox Matrix for Windows | `KnoxMatrixforWindows_2.1.1.0` |
| 11 | [PC Diagnostics](11-PC-Diagnostics.md) | Samsung PC Diagnostics | `PCDiagnostics_1.0.24.0` |
| 12 | [Color Engine & Display Profile](12-Color-Engine-Display-Profile.md) | Samsung ColorEngine service, ColorMode data, DisplayProfileRegister | `C:\Program Files\Samsung\ColorEngine`, `C:\ProgramData\ColorMode` |
| 13 | [Platform Engine, Drivers & Connectivity](13-Platform-Engine-Drivers.md) | SystemPlatformEngine, SamsungEventController.sys, Wi-Fi UHB service, USB drivers / ss_conn, Galaxy driver extensions | DriverStore + `C:\Program Files\Samsung\USB Drivers` |

## Install footprint discovered

User-given roots: `C:\ProgramData\ColorMode`, `C:\ProgramData\Samsung`, `C:\Program Files\Samsung`.
Additional roots found:

- `C:\Program Files\WindowsApps\SAMSUNGELECTRONICSCO.LTD.*` and `SAMSUNGELECTRONICSCoLtd.*` — 12 MSIX packages (two publisher IDs: `3c1yjt4zspk6g` and `wyx1vj98g3asy`).
- `C:\Windows\System32\DriverStore\FileRepository\` — DCHU software components: `sfourswext0428v15` / `sfourswcomp15` (Settings backend), `systemplatformengineext` / `systemplatformenginecomp`, `samsungwifiextension` / `samsungwificomponent`, `samsungeventcontroller` (KMDF), audio/mic extension INFs.
- `C:\Windows\System32\drivers\SamsungEventController.sys`, `ssudbus2.sys`, `ssudmdm.sys`, `ss_conn_usb_driver2.sys`.
- Registry: `HKLM\SOFTWARE\Samsung\{SamsungSettings, SamsungSettingsEvent, ColorEngine, SamsungAccount, SamsungContinuityService, StorageShare, Camera, USB_DRIVER, …}`, `HKCU\SOFTWARE\Samsung\SamsungSettingsExtension`.
- Certificate store: `LocalMachine\Root` contains `CN=Samsung Electronics SCAI Verifier CA` (valid 2023-05-30 → 2099-12-31).

### Services (all `LocalSystem`)

| Service | Binary | Start | Owner doc |
|---|---|---|---|
| SamsungSystemSupportService | DriverStore `sfourswcomp15\SamsungSystemSupportService.exe` | Auto | 01 |
| SamsungPlatformEngine | DriverStore `systemplatformenginecomp\SystemPlatformEngine.exe` | Auto | 13 |
| SamsungQuickShareService | `QuickShareService\QuickShareService.exe` (MSIX packaged service) | Auto | 02 |
| SamsungCameraShareService | `CameraShareService\SamsungCameraShareService.exe` (packaged service) | Auto | 03 |
| Samsung Device Care Service | `C:\Program Files\Samsung\SamsungDeviceCare\iveService\iveService.exe` | Auto | 04 |
| SamsungContinuityWindowsService ("Galaxy Connect") | packaged service | Auto | 05 |
| SamsungAccountService | `SAService\SAService.exe` (packaged) | Manual | 06 |
| SamsungUpdateService | `C:\Program Files\Samsung\SamsungUpdate\SUService.exe` | Auto | 07 |
| GBExperience | `WindowsService\GBExperience.exe` (packaged) | Auto | 08 |
| Samsung ColorEngine Service | `C:\Program Files\Samsung\ColorEngine\SamsungColorEngineService.exe` | Auto | 12 |
| Samsung WiFi UHB Setting Service | DriverStore `samsungwificomponent\SamsungWiFi_UHB_Setting_Service.exe` | Auto | 13 |
| ss_conn_service / ss_conn_service2 | `USB Drivers\27_ssconn`, `28_ssconn2` | Auto | 13 |
| SamsungEventController (kernel) | `drivers\SamsungEventController.sys` | Demand | 01 / 13 |

## Shared platform patterns (apply across docs)

1. **Packaged full-trust + SYSTEM service split.** Nearly every product is an MSIX package with `runFullTrust`, a `desktop6:Service` running as LocalSystem, and a per-user UI process. The service does privileged work (drivers, shared memory in `Global\`, firewall/SMB, user-token process launch); the UI talks to it over named pipes whose server checks the caller's code signature (`VerifySamsungSign`, `SamsungProcessValidationHelper`, `GetNamedPipeClientProcessId`).
2. **`com.samsung.sso` AppService.** Settings, Settings Runtime, Quick Share, Camera Share, Continuity, Knox Matrix, Cloud, Gallery and Welcome all declare an AppService named `com.samsung.sso`. Samsung Account (`SAClient`) is the provider of sign-in state and tokens; the others register the same name to receive sign-in/sign-out broadcasts. See doc 06.
3. **Shared Samsung libraries:** `Samsung.OneUI.WinUI` / `Samsung.OneUI.WPF` (One UI design system controls), `SamsungAnalyticsSDK*` (telemetry, consent-gated), `SASDK_WinUI` (Samsung Account SDK), `McfSdkLib` (MCF client SDK used by Camera Share and others), `CommonLoggerSDK`, `SharmIpc` (shared-memory/named-pipe RPC used by Device Care and Update).
4. **Mixed runtimes.** .NET Native UWP (Quick Share UI, Settings Runtime, Account client), .NET 8/9/10 WinUI 3 (Settings host, Device Care client, Galaxy Connect UI, Diagnostics, Cloud), .NET Framework 4.7.2/4.8 WPF/services (Camera Share, MCF Core, Continuity service, Samsung Update), .NET NativeAOT (Quick Share service, Knox Matrix service), IKVM-translated Java (Quick Share), native C++/MFC (Settings engine, Platform Engine, Device Care service, Color Engine), KMDF/UMDF/PortCls drivers.
5. **BIOS/EC access** goes through the ACPI device `SAM0428/0429/0430` ("SCAI"), driven by `SamsungEventController.sys`; user-mode callers use SABI/SCAI command buffers over `DeviceIoControl` (docs 01, 11, 13).

## Cross-suite security & privacy observations (details in each doc)

| ID | Finding | Confidence | Doc |
|---|---|---|---|
| S-2 | `SystemPlatformEngine` can install `CN=Samsung Electronics SCAI Verifier CA` into the machine Root store via `certutil -addstore root`; the CA is present on this host, valid to 2099. | Observed (strings + store + log "TaskInstallPC") | 13 |
| S-3 | Settings engine (`SamsungSystemSupportEngine`) embeds SDDL `D:NO_ACCESS_CONTROL` adjacent to its pipe-name template `\\.\pipe\{9187E7E8-…}_<name>`; if used for the pipe it would be a NULL DACL. Not verified live. | Inferred | 01 |
| S-4 | Storage Share (Continuity service) creates local Windows user accounts + a group, sets NTFS ACLs, an SMB share, `subst` drives and enables the "File and Printer Sharing" firewall group. | Observed (types/strings) | 05 |
| S-5 | Continuity service grants AppContainer loopback exemptions (`NetworkIsolationSetAppContainerConfig`) and launches agents with the active user's token. | Observed | 05 |
| S-6 | MCF Core installs global low-level keyboard & mouse hooks (`SetWindowsHookEx`) for activity detection / Multi Control. | Observed | 05 |
| S-7 | Quick Share service installs Intel PIE Wi-Fi driver packages via a bundled `pnputil.exe` and wipes NLA network-profile registry keys on logoff (`NwRegistryCleanManager`). | Observed (log + strings) | 02 |
| S-8 | Several update/download URLs are plain HTTP (`http://orcaservice.samsungmobile.com/filedownloader.aspx`, `http://appmanager.samsungmobile.com/BIOSUpdateItem/`); integrity then depends on signature checks (`wintrust`, `VerifySamsungSign`) — present but not traced end-to-end. | Observed / inferred | 04, 07 |
| S-9 | Device Care inventories installed applications and caches their icons under `C:\ProgramData\Samsung\SamsungDeviceCare\Applications\` (machine-wide readable location). | Observed | 04 |

## Evidence files (local, in `recon/`)

- `recon/manifest_*.txt` — parsed AppxManifest summaries.
- `recon/binaries.csv` — 1,931 binaries with managed/native classification and version info.
- `recon/md/<package>/<assembly>.txt` — .NET metadata dumps (types, methods, P/Invokes, user strings).
- `recon/native/<binary>.txt` — PE imports/exports and strings for native binaries.
- `recon/rea/*.json` + `recon/rea_evidence_index.txt` — REA Evidence records (`inspect_managed_artifact`, `inspect_managed_native_boundaries`) with Evidence IDs and SHA-256.
- `recon/native_sha256.txt` — SHA-256 of cited native binaries.
- `recon/tools/` — the two analysis helpers built for this work (`mddump`: System.Reflection.Metadata dumper; `pestr`: PE import/string extractor).

## Method limits

- REA's native decompiler providers (Ghidra / IDA) were not configured, so native code is described from imports, exports, embedded symbol/source-path strings and logs, not decompiled control flow.
- REA's managed-member pass exceeded its 64 MiB metadata budget on large assemblies (e.g. `SamsungSettings.dll`); member inventories for those come from the local `mddump` tool.
- .NET Native UWP binaries (`QuickShare.dll`, `SAClient.dll`, `SamsungSettingsRuntime.dll`) carry no CLI metadata; they are described from strings and manifests only.
- Nothing was executed; behaviour statements marked *observed* come from shipped bytes, registry/disk state or the apps' own logs, *inferred* statements are analyst conclusions.
