# dotfiles

Shared configuration for Ubuntu machines, managed with
[chezmoi](https://www.chezmoi.io/).

Machine-specific work configuration is intentionally kept outside this
repository in `~/.zshrc.local`. Shell secrets live in
`~/.config/zsh/secrets.zsh` and must have mode `0600`.

## Install

```bash
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- \
  init --apply https://github.com/daanqq/.dotfiles.git
```

The shell configuration degrades gracefully when optional tools are missing.
Install the tools you want to use separately, then make Zsh your login shell
if needed:

```bash
chsh -s "$(command -v zsh)"
```

## Daily use

Add a new file once:

```bash
dot-add ~/.config/tool/config.toml
```

Copy changes from all managed files, commit, and push:

```bash
dot-save
dot-save "chore(dotfiles): update shell aliases"
```

Inspect changes or update a machine:

```bash
chezmoi diff
chezmoi update
chezmoi managed
```

`dot-save` aborts on common private-key, npm-token, and API-key patterns. This
is a safety net, not a substitute for reviewing `chezmoi diff` before pushing.

## Local configuration

Use `~/.zshrc.local` for work commands, internal hosts, per-machine paths, and
tools that are not useful on every machine. It is sourced after the shared
configuration and is not managed by chezmoi.

Git identity and machine-specific Git settings belong in
`~/.config/git/local.inc`, for example:

```gitconfig
[user]
    name = Your Name
    email = you@example.com
```

## Secrets

The local `~/.config/zsh/secrets.zsh` file is not managed as plaintext. To
enable passphrase-protected secrets, run the one-time helper from the chezmoi
source directory:

```bash
cd "$(chezmoi source-path)"
./scripts/enable-passphrase-secrets.sh
```

The helper generates an age identity, asks for a passphrase, stores the
passphrase-encrypted identity as `key.txt.age`, and adds the current secrets
file with chezmoi encryption. The private identity is also installed locally
at `~/.config/chezmoi/key.txt` with mode `0600`.

Before pushing, save the passphrase and the original identity in a password
manager or another secure backup. The passphrase is not recoverable from Git.

After the helper finishes:

```bash
dot-save "feat(secrets): enable passphrase bootstrap"
```

The repository then contains only encrypted secret material. On a new Ubuntu
machine, use two commands:

```bash
sudo apt install age
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- \
  init --apply https://github.com/daanqq/.dotfiles.git
```

The second command asks for the passphrase once, restores the local age
identity, and applies encrypted files. The identity file itself is ignored by
chezmoi and is never copied into the home directory from Git.

Do not add `~/.config/chezmoi/key.txt` to the repository.
