# CoolWip Scripts

A curated collection of Roblox-related scripts maintained by [coollikecoolwip](https://github.com/coollikecoolwip). This repository may include original, modified, and third-party code. **Hosting a script here does not mean the maintainer wrote the original code.**

## Current scripts

All current scripts remain at their **original root-level paths**, preserving the existing raw GitHub URLs.

| Script | Purpose |
| --- | --- |
| [`Aimbot.lua`](Aimbot.lua) | Aiming utility |
| [`AntiAFK.lua`](AntiAFK.lua) | AFK-related utility |
| [`AntiFling.lua`](AntiFling.lua) | Fling protection |
| [`BetaTest.lua`](BetaTest.lua) | Development/test file |
| [`BetterESP.lua`](BetterESP.lua) | ESP/visual utility |
| [`CoolwipHub.lua`](CoolwipHub.lua) | Hub script |
| [`CoolwipHubAutoFarm.lua`](CoolwipHubAutoFarm.lua) | Hub automation |
| [`FNAF-Coop.lua`](FNAF-Coop.lua) | FNAF Co-op specific script |
| [`FakeLag.lua`](FakeLag.lua) | Lag simulation |
| [`FlingAll.lua`](FlingAll.lua) | Fling utility |
| [`Follow.lua`](Follow.lua) | Player following |
| [`MM2ESP.lua`](MM2ESP.lua) | MM2 ESP |
| [`MiniMap.lua`](MiniMap.lua) | Minimap |
| [`PromptPrecision.lua`](PromptPrecision.lua) | Prompt interaction utility |
| [`RivalsAimbot.lua`](RivalsAimbot.lua) | Rivals aiming utility |
| [`Say.iy`](Say.iy) | Chat-related file (nonstandard extension) |
| [`Say.lua`](Say.lua) | Chat utility |
| [`Spectate.lua`](Spectate.lua) | Spectating tool |
| [`VisionHub.lua`](VisionHub.lua) | Vision Hub (third-party) |
| [`VisionHubAutoFarm.lua`](VisionHubAutoFarm.lua) | Vision Hub automation (third-party-derived) |

## Previous versions

**105 historical snapshots** are available in the **[versions archive](versions/README.md)**. These were recovered from actual Git history and named by commit date and abbreviated commit SHA. They are historical records, not tested releases.

## Folder structure

```text
coolwips-scripts/
├── *.lua / Say.iy     # current scripts (original URLs preserved)
├── README.md          # repository overview
└── versions/          # historical snapshots, archive index, legacy placeholder
```

Existing script paths are intentionally kept stable. The `versions/` folder is the **only directory at the repository root**.

## Authorship and credits

The maintainer has confirmed that `VisionHub.lua` and `VisionHubAutoFarm.lua` are **not their original creations**. Original authors and source/licensing details still need verification. The authorship of other files is not independently established by this index; a commit or filename does not prove ownership. Respect upstream licensing and add attribution when verified.

## Security, compatibility, and reports

These scripts have not been independently reviewed for safety or compatibility. Review all source and remote dependencies before running anything, including scripts downloaded by `HttpGet`/`loadstring`. Never expose passwords, session cookies, authentication tokens, or passkeys. Do not disable antivirus to run a script. Unauthorized executors or game modifications may violate Roblox or individual game rules.

To report a bug or correct credit, [open an issue](https://github.com/coollikecoolwip/coolwips-scripts/issues) with the affected filename, relevant game and executor environment, errors, and original source/author link when known. Do not post credentials.
