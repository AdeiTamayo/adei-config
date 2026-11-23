# adei-config

Centralized, version-controlled copy of my machine configuration, so it can be
restored on a fresh setup.

## Contents

| Path      | What it holds |
| --------- | ------------- |
| `vscode/` | VS Code user profiles (settings, keybindings, extension lists). See [`vscode/README.md`](vscode/README.md). |

Planned: terminal configuration, shell/PowerShell profile, and agent skills.

## VS Code profiles

| Folder               | VS Code profile     | Purpose |
| -------------------- | ------------------- | ------- |
| `vscode/profiles/default` | *Default* | Current default profile — personal styling and keybindings. |
| `vscode/profiles/minimal` | `AdeiTamayoProfile` | Minimalistic UI profile. |
| `vscode/profiles/latex`   | `Latex` | LaTeX writing profile. |
| `vscode/profiles/angular-python` | `Adei-arima-profile` | Angular and Python development. |

## Usage

```powershell
# Push live VS Code files into the repo (backups in vscode/.backup/)
./vscode/export.ps1

# Apply a profile from the repo back into VS Code
./vscode/restore.ps1 -Profile minimal
```

Machine-specific state (UI state DBs, chat history, telemetry ids, workspace
storage) is intentionally not tracked.
