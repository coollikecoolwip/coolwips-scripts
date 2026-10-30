# Repository organization and stable-link policy

## Current layout

The 20 existing script/related files live at the **repository root**. That is intentional: raw GitHub URLs may be used by existing launchers/loaders. The root files are the current distribution entry points.

```text
coolwips-scripts/
├── <existing 20 script / related files>   # unchanged paths
├── README.md                             # main navigation
├── docs/                                 # index, credits, policies
├── original/                             # future maintainer-authored source
├── modified/                             # future attributed adaptations
├── third-party/                          # future externally authored source, if permitted
├── development/                          # future prototypes / experiments
├── archive/                              # future retired source / documentation
└── Junk/                                 # existing folder, unchanged
```

These broad **ownership/lifecycle folders** are deliberately separate from the *functional* categories in the [script index](SCRIPT_INDEX.md). A script can be both "automation" and "third-party" without copying it into two places.

## Which folder to use for future work

- **`original/`**: source you wrote; add a per-project README as needed.
- **`modified/`**: adaptations of outside work; include original author/source, license/permission, and changes.
- **`third-party/`**: unmodified externally authored files **only if redistribution is permitted**; keep explicit attribution.
- **`development/`**: temporary experiments and testing code.
- **`archive/`**: deprecated material, clearly labeled so it is not mistaken for the active version.
- **`docs/`**: indexes, credits, setup notes, screenshots, and maintenance documentation.

Do **not** relocate current scripts into these folders merely to fill them: the existing root paths are intentionally preserved.

## Compatibility rules

1. Do not rename, move, remove, or silently replace an existing root script without explicitly addressing downstream users.
2. Preserve case-sensitive filenames and extensions. For example, `Say.iy` is *not* silently renamed to `Say.lua`.
3. When refactoring a script into another directory, plan and test a backwards-compatible entry point at its **existing root path**. A new loader changes executable behavior, even if the URL is unchanged, and therefore requires code/security review.
4. New projects can live in a categorized folder. Only add a root entry point when a stable public URL is desired.
5. Keep the [script index](SCRIPT_INDEX.md) and [credits](CREDITS.md) current whenever files are added or their provenance is established.

**This documentation-only change does not alter the content of any existing script file.**

[Back to documentation](README.md)
