# Dotfiles architecture

This repository separates portable configuration, machine-local state, and
encrypted secrets.

## Managed configuration

Chezmoi stores its source state in `~/.local/share/chezmoi` and applies it to
normal paths under `$HOME`. Source filenames use chezmoi attributes such as
`dot_`, `private_`, and `encrypted_`.

The repository currently manages shared Zsh, Git, tmux, Starship, btop,
micro, VS Code keybindings, and MCP configuration. Optional shell tools are
initialized only when available, so the configuration remains usable during
incremental setup of a new machine.

`~/.config/chezmoi/chezmoi.toml` is generated from `.chezmoi.toml.tmpl`. The
template sets a stable umask and configures age encryption.

## Local-only configuration

Files that contain work-specific settings or machine identity remain outside
chezmoi:

- `~/.zshrc.local` contains work commands, internal hosts, and machine paths.
- `~/.config/git/local.inc` contains Git identity and machine-specific Git
  settings.
- `.npmrc`, SSH configuration, kubeconfig, histories, caches, and application
  state are not managed.

The shared `.zshrc` sources `~/.zshrc.local` when it exists. The shared
`.gitconfig` includes `~/.config/git/local.inc` when it exists.

## Secret storage

Shell secrets are edited as plaintext only in
`~/.config/zsh/secrets.zsh`, which must have mode `0600`. Chezmoi stores this
file in the repository as age ciphertext. Use `chezmoi source-path` to inspect
the exact source path instead of relying on its encoded filename.

The age identity has two forms:

- `~/.config/chezmoi/key.txt` is the local plaintext identity with mode
  `0600`. It is never committed.
- `key.txt.age` is the passphrase-encrypted copy stored in Git. It is excluded
  from application as a normal home file by `.chezmoiignore`.

`.chezmoiscripts/run_onchange_before_decrypt-private-key.sh.tmpl` runs before
encrypted files are applied. If the local identity does not exist, it prompts
for the passphrase and decrypts `key.txt.age`. Subsequent updates do not prompt
while the local identity remains available.

The passphrase must be stored outside this repository. Keep a tested backup
of both the passphrase and the plaintext age identity. Losing both makes the
encrypted repository state unrecoverable.

Passphrase encryption protects secrets in Git and during transfer. It does
not protect an unlocked machine, where `secrets.zsh` and `key.txt` necessarily
exist as plaintext files with restricted permissions.

## Safety checks

`dot-save` runs `chezmoi re-add`, stages the source state, checks the diff, and
pushes only after a successful commit. It rejects a plaintext source path for
`secrets.zsh` and several common token or private-key patterns.

These checks reduce accidental disclosure but do not replace reviewing
`chezmoi diff`. If a secret reaches Git as plaintext, rotate it immediately;
removing it in a later commit does not remove it from Git history.

## Initial encryption setup

The one-time helper is kept in
`scripts/enable-passphrase-secrets.sh`. It generated the current age identity,
the encrypted identity, the before script, and the encrypted managed secrets.
The helper is retained for documentation and recovery work but must not be
run again on an already configured repository.
