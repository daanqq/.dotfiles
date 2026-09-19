# dotfiles

Shared configuration for Ubuntu machines, managed with
[chezmoi](https://www.chezmoi.io/).

Machine-specific work configuration is intentionally kept outside this
repository in `~/.zshrc.local`. Shell secrets live in
`~/.config/zsh/secrets.zsh` and must have mode `0600`.

## Install

```bash
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- \
  init --apply git@github.com:daanqq/.dotfiles.git
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

The first-stage setup keeps secrets in the local
`~/.config/zsh/secrets.zsh` file. Do not add that file as plaintext.

To store it encrypted later, install `age`, create and back up an identity
outside Git, configure chezmoi, and add the file with encryption:

```toml
# ~/.config/chezmoi/chezmoi.toml
encryption = "age"

[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age1..."
```

```bash
chezmoi add --encrypt ~/.config/zsh/secrets.zsh
```

Do not enable encryption until the private identity has a tested backup. The
identity itself must never be committed to this repository.
