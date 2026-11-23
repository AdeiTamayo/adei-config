# VS Code configuration

Exported copy of the VS Code user profiles. Each folder under `profiles/`
contains the files VS Code keeps in `%APPDATA%\Code\User` (default profile) or
`%APPDATA%\Code\User\profiles\<hash>` (named profile):

| Folder     | VS Code profile name | Notes |
| ---------- | -------------------- | ----- |
| `default/` | *Default*            | Personal styling + keybindings, to be turned into its own profile. |
| `minimal/` | `AdeiTamayoProfile`  | Minimalistic UI: no tabs, hidden activity bar/status bar, no line numbers, flat theme. |
| `latex-jupyter/` | `Latex`        | LaTeX documents and Jupyter notebooks (dark theme, LaTeX Workshop, Python/Jupyter extensions). |
| `angular-python/` | `Adei-arima-profile` | Angular and Python with Pylance, Ruff and Prettier; macOS keybindings. |

`profiles.json` records the mapping to the original VS Code profile names and
location hashes.

## Files per profile

- `settings.json` – user settings (JSONC, comments preserved).
- `keybindings.json` – custom keybindings (JSONC, comments preserved).
- `extensions.txt` – installed extensions as `publisher.id@version`.

The `default` profile of VS Code does not store an `extensions.json`; its list
was derived from the globally installed extensions in `~/.vscode/extensions`.

## Restoring

### Automatically (Windows)

The PowerShell scripts use `%APPDATA%` and `%USERPROFILE%` on Windows.

```powershell
# Restore settings + keybindings into the default profile (backups are kept)
./vscode/restore.ps1 -Profile default

# Restore into the named profile "AdeiTamayoProfile" (minimal/)
./vscode/restore.ps1 -Profile minimal

# Restore and (re)install the extensions listed in extensions.txt
./vscode/restore.ps1 -Profile latex-jupyter -Extensions

# Restore the Angular/Python profile
./vscode/restore.ps1 -Profile angular-python -Extensions
```

The script resolves the named profile through
`globalStorage/storage.json`, so it works even if the location hash differs.
Create the profile in VS Code first if it does not exist yet.

### Manually

Copy the profile folder contents to the matching VS Code location:

- Default profile: `%APPDATA%\Code\User\`
- Named profile: `%APPDATA%\Code\User\profiles\<hash>\`
  (find `<hash>` in `globalStorage/storage.json` → `userDataProfiles`)

Extensions can be installed with:

```powershell
Get-Content ./vscode/profiles/minimal/extensions.txt |
  ForEach-Object { code --install-extension ($_ -replace '@.*$', '') }
```

Add `--profile "<name>"` to install into a specific profile.

### Angular/Python on macOS

The `angular-python` export was captured from `Adei-arima-profile` on 2026-11-23.
Create an empty profile with that name and switch to it. Use **Preferences: Open
User Settings (JSON)** and **Preferences: Open Keyboard Shortcuts (JSON)** to
replace their contents with the corresponding exported files.

From the repository root, install the recorded extension versions:

```sh
while IFS= read -r extension; do
  code --profile "Adei-arima-profile" --install-extension "$extension"
done < vscode/profiles/angular-python/extensions.txt
```

The profile export omits local PostgreSQL server groups and connections. Review
settings after re-exporting before committing, because `export.ps1` copies them
verbatim.

## Re-exporting after changes

Copy the live files back into this repo (stop VS Code first so it flushes the
files to disk, or close the Settings/Keybindings editors):

```powershell
./vscode/export.ps1
```

`export.ps1` backs up the current repo copies into `vscode/.backup/` before
overwriting them.

## Not included

These live outside the profile folders and are machine/account specific, so they
are intentionally left out:

- `globalStorage/state.vscdb` (UI state, chat history, extension storage)
- `workspaceStorage/` and `History/`
- `globalStorage/storage.json` (telemetry ids, recent workspaces, profile map)
- `globalStorage/agent-host-config.json` (Copilot agent config: permissions,
  auto-approve patterns, sandbox settings)
- `snippets/` (currently empty)
- `mcp.json`, `tasks.json`, `prompts/` (not present)
