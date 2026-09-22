# dotfiles

Shared Ubuntu configuration managed with
[chezmoi](https://www.chezmoi.io/).

## Set up a new machine

Install the required tools:

```bash
sudo apt update
sudo apt install -y age curl git zsh
```

Initialize and apply the dotfiles:

```bash
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- \
  init https://github.com/daanqq/.dotfiles.git
~/.local/bin/chezmoi apply
```

Enter the dotfiles passphrase when prompted. Chezmoi will restore the local
age identity and decrypt the managed secrets.

Make Zsh the login shell and start it:

```bash
chsh -s "$(command -v zsh)"
exec zsh
```

Create the machine-specific Git identity:

```bash
mkdir -p ~/.config/git
$EDITOR ~/.config/git/local.inc
```

For example:

```gitconfig
[user]
    name = Your Name
    email = you@example.com
```

## Update managed files

Edit files in their normal locations under `$HOME`, then inspect and save the
changes:

```bash
$EDITOR ~/.zshrc
chezmoi diff
dot-save "chore(zsh): update shell configuration"
```

Add a new file to chezmoi once, then save it:

```bash
dot-add ~/.config/tool/config.toml
chezmoi diff
dot-save "feat(tool): add tool configuration"
```

List all managed files:

```bash
chezmoi managed
```

Repository-only files such as `README.md` and `docs/` are edited directly in
the source state:

```bash
cd "$(chezmoi source-path)"
$EDITOR README.md
dot-save "docs: update usage guide"
```

## Update secrets

Secrets belong in `~/.config/zsh/secrets.zsh`, not in `.zshrc`:

```bash
$EDITOR ~/.config/zsh/secrets.zsh
chmod 600 ~/.config/zsh/secrets.zsh
source ~/.config/zsh/secrets.zsh
```

Save the encrypted update:

```bash
dot-save "feat(secrets): update shell credentials"
```

Verify that chezmoi still manages the encrypted source file:

```bash
chezmoi source-path ~/.config/zsh/secrets.zsh
```

The returned path must contain `encrypted_` and end with `.age`. Never add
`~/.config/zsh/secrets.zsh` as plaintext.

## Push updates

`dot-save` copies changes from all managed files, checks the staged diff,
creates a commit, and pushes it:

```bash
chezmoi diff
dot-save "chore(dotfiles): describe the change"
```

Use a [Conventional Commit](https://www.conventionalcommits.org/) message.
Without an argument, `dot-save` uses `chore(dotfiles): sync`.

## Pull updates on another machine

Preview and apply the latest remote state:

```bash
chezmoi git -- pull --ff-only
chezmoi diff
chezmoi apply
```

For the short path, use:

```bash
chezmoi update
```

See [`docs/architecture.md`](docs/architecture.md) for repository structure,
local-only configuration, and the encryption design.
