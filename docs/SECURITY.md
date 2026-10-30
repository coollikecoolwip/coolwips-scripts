# Security and compatibility guidance

These scripts and their execution environments have **not been independently audited or certified safe**. No guarantee is made that a file works with a specific game, Roblox version, or executor.

## Review before executing

- Read the complete source (or ask for a code review) and verify the original author/source, particularly for third-party scripts.
- Look for network requests, dynamic script loading (`loadstring`, `HttpGet`), requests for secrets, unexpected file/network access, and code that downloads additional payloads.
- A script can behave differently later if it downloads code from an external URL. **For example, `VisionHub.lua` currently includes a remote `HttpGet` / `loadstring` call near its beginning.** That alone is not proof of malware, but its fetched content also needs review.
- Never paste passwords, Roblox session cookies, passkeys, API keys, or authentication tokens into scripts.
- Do not disable malware protection to force a script to execute. Review unexpected connections and antivirus alerts rather than bypassing them.
- Treat executors and third-party dependencies as separate software with their own risks.
- Do not assume a file is compatible just because it is listed in the [index](SCRIPT_INDEX.md).

## Report a problem

Create a [GitHub issue](https://github.com/coollikecoolwip/coolwips-scripts/issues) with the script name, suspicious behavior/error, reproduction steps, and the relevant URL or code line. **Do not post credentials, tokens, or private account information** in issues.

Scripts that bypass a game's intended mechanics or rely on unauthorized executors may violate Roblox or individual game rules and lead to restrictions.

[Back to documentation](README.md)
