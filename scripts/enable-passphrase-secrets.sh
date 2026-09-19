#!/usr/bin/env bash
set -euo pipefail

source_dir="$(chezmoi source-path)"
secret_file="$HOME/.config/zsh/secrets.zsh"
identity_dir="$HOME/.config/chezmoi"
identity_file="$identity_dir/key.txt"
encrypted_identity="$source_dir/key.txt.age"
config_template="$source_dir/.chezmoi.toml.tmpl"
ignore_file="$source_dir/.chezmoiignore"
decrypt_script="$source_dir/run_onchange_before_decrypt-private-key.sh.tmpl"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

command -v chezmoi >/dev/null 2>&1 || die 'chezmoi is not installed'
command -v age >/dev/null 2>&1 || die 'install age first: sudo apt install age'
[[ -f "$secret_file" ]] || die "secret file not found: $secret_file"
[[ ! -e "$encrypted_identity" ]] || die "$encrypted_identity already exists"
[[ ! -e "$identity_file" ]] || die "$identity_file already exists; refusing to replace it"

umask 077
mkdir -p "$identity_dir"

tmp_identity="$(mktemp)"
tmp_encrypted_identity="$(mktemp)"
cleanup() {
  rm -f -- "$tmp_identity" "$tmp_encrypted_identity"
}
trap cleanup EXIT

chezmoi age-keygen --output "$tmp_identity"
recipient="$(chezmoi age-keygen --convert "$tmp_identity")"
[[ "$recipient" == age1* ]] || die 'failed to derive age recipient'

printf 'Encrypting the age identity. You will be prompted for a passphrase.\n'
chezmoi age encrypt --passphrase --output "$tmp_encrypted_identity" "$tmp_identity"

install -m 600 "$tmp_identity" "$identity_file"
install -m 600 "$tmp_encrypted_identity" "$encrypted_identity"

if ! grep -qxF 'key.txt.age' "$ignore_file"; then
  printf 'key.txt.age\n' >> "$ignore_file"
fi

cat > "$config_template" <<EOF
umask = 0o022
encryption = "age"
useBuiltinAge = false

[age]
identity = "~/.config/chezmoi/key.txt"
recipient = "$recipient"
EOF

cat > "$decrypt_script" <<'EOF'
#!/bin/sh

set -eu

key="${HOME}/.config/chezmoi/key.txt"

if [ ! -f "$key" ]; then
    mkdir -p "${HOME}/.config/chezmoi"
    chezmoi age decrypt \
        --output "$key" \
        --passphrase \
        "{{ .chezmoi.sourceDir }}/key.txt.age"
    chmod 600 "$key"
fi
EOF
chmod 755 "$decrypt_script"

chezmoi init
chezmoi add --encrypt "$secret_file"

printf '%s\n' "Secrets configured for recipient: $recipient"
printf '%s\n' 'Review the staged changes, then run:'
printf '%s\n' '  dot-save "feat(secrets): enable passphrase bootstrap"'
