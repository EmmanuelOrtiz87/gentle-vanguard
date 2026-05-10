# Editor Configuration

Universal and language-specific editor settings for consistent code formatting across all IDEs.

## Universal Settings (`.editorconfig`)

**This is the most important file.** It works with **all modern editors** automatically.

Add `.editorconfig` to your project root:

```bash
cp templates/editor/.editorconfig .
```

Supported editors (auto-detected):

- VSCode, IntelliJ, WebStorm, PyCharm, GoLand
- Vim, Neovim, Emacs, Sublime Text, Atom
- Brackets, Notepad++, Visual Studio

## VSCode Specific

If using VSCode, also copy the settings:

```bash
# Basic (recommended)
cp templates/editor/vscode/settings.json .vscode/

# Language-specific variants
cp templates/editor/vscode/settings.go.json .vscode/  # For Go projects
cp templates/editor/vscode/settings.python.json .vscode/  # For Python projects

# Extensions
cp templates/editor/vscode/extensions.json .vscode/
```

### Recommended Extensions

Install these in VSCode for the best experience:

| Extension      | Purpose                     |
| -------------- | --------------------------- |
| EditorConfig   | Reads `.editorconfig` files |
| Prettier       | Code formatting             |
| ESLint         | Linting                     |
| GitLens        | Git integration             |
| GitHub Copilot | AI assistance               |

## JetBrains IDEs

Import settings in `File > Settings > Editor > Code Style`:

### General Settings

```
Tab Size: 2
Indent: 2 spaces
Line Separator: Unix (LF)
Encoding: UTF-8
```

### Language-Specific

| Language              | Quote Style | Semicolons |
| --------------------- | ----------- | ---------- |
| JavaScript/TypeScript | Single      | Yes        |
| JSON                  | Double      | N/A        |
| HTML                  | Double      | N/A        |
| CSS                   | Single      | N/A        |
| Python                | Double      | N/A        |
| Go                    | None        | No         |

## Vim/Neovim

Add to your config:

```vim
" ~/.vimrc or ~/.config/nvim/init.vim
source ~/.editorconfig  " If using editorconfig-vim plugin
```

Or install [editorconfig-vim](https://github.com/editorconfig/editorconfig-vim).

## Quick Reference

| Setting                  | Value     |
| ------------------------ | --------- |
| Tab Size                 | 2 spaces  |
| Line Ending              | LF (Unix) |
| Charset                  | UTF-8     |
| Trim Trailing Whitespace | Yes       |
| Insert Final Newline     | Yes       |
| Max Line Length          | 100 chars |

## File Structure

```
templates/editor/
 .editorconfig                    # Universal (copy to project root)
 README.md                         # This file
 vscode/
    settings.json               # Default settings
    settings.go.json            # Go-specific
    settings.python.json        # Python-specific
    extensions.json             # Recommended extensions
 jetbrains/                       # JetBrains settings (IDEA format)
 vim/                            # Vim/Neovim config snippets
 emacs/                          # Emacs config snippets
 sublime/                        # Sublime Text settings
 atom/                          # Atom settings
```

## CI Integration

Add to your CI pipeline to enforce formatting:

```yaml
# GitHub Actions
- name: Check formatting
  run: |
    npx prettier --check .
    golangci-lint run
    pylint **/*.py
```
