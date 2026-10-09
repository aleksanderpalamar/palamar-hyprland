#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${PALAMAR_HYPRLAND_URL:-https://github.com/aleksanderpalamar/palamar-hyprland.git}"
REPO_DIR="${PALAMAR_HYPRLAND_DIR:-$HOME/Projetos/palamar-hyprland}"
OMZ_DIR="$HOME/.oh-my-zsh"

DRY_RUN=0
[[ ${1:-} == "--dry-run" ]] && DRY_RUN=1

step() { printf '\n\033[1;34m==>\033[0m %s\n' "$1"; }
skip() { printf '    \033[2m%s\033[0m\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

run() {
    if (( DRY_RUN )); then
        printf '    [dry-run] %s\n' "$*"
        return 0
    fi
    "$@"
}

ensure_base() {
    step "Pacotes de base"
    run sudo pacman -S --needed --noconfirm git rust base-devel
}

ensure_repo() {
    step "Repositório em $REPO_DIR"
    if [[ -d $REPO_DIR/.git ]]; then
        skip "já existe"
        return
    fi
    run git clone "$REPO_URL" "$REPO_DIR"
}

ensure_yay() {
    step "yay (necessário para os pacotes do AUR)"
    if have yay; then
        skip "já instalado"
        return
    fi
    local tmp
    tmp=$(mktemp -d)
    run git clone https://aur.archlinux.org/yay.git "$tmp/yay"
    run bash -c "cd '$tmp/yay' && makepkg -si --noconfirm"
    run rm -rf "$tmp"
}

build_cli() {
    step "Compilando a CLI"
    run bash -c "cd '$REPO_DIR' && cargo build --release"
}

cli() {
    if (( DRY_RUN )); then
        printf '    [dry-run] palamar-hyprland %s\n' "$*"
        return 0
    fi
    "$REPO_DIR/target/release/palamar-hyprland" --repo "$REPO_DIR" "$@"
}

install_packages() {
    step "Pacotes do ambiente"
    cli packages install
}

link_user_configs() {
    step "Configurações do usuário"
    cli apply
}

clone_into() {
    local url=$1 dir=$2
    [[ -d $dir ]] && return 0
    run git clone --depth=1 "$url" "$dir"
}

ensure_shell() {
    step "Shell (zsh, oh-my-zsh, powerlevel10k)"
    clone_into https://github.com/ohmyzsh/ohmyzsh.git "$OMZ_DIR"
    clone_into https://github.com/romkatv/powerlevel10k.git "$OMZ_DIR/custom/themes/powerlevel10k"
    clone_into https://github.com/zsh-users/zsh-autosuggestions "$OMZ_DIR/custom/plugins/zsh-autosuggestions"
    clone_into https://github.com/zsh-users/zsh-syntax-highlighting.git "$OMZ_DIR/custom/plugins/zsh-syntax-highlighting"

    if [[ $SHELL == */zsh ]]; then
        skip "zsh já é o shell de login"
        return
    fi
    run sudo chsh -s /usr/bin/zsh "$USER"
}

refresh_fonts() {
    step "Fontes"
    run fc-cache -f
}

ensure_theme() {
    step "Tema atual"
    run "$HOME/.local/bin/hypr-theme" refresh
}

link_system_configs() {
    step "Configurações de sistema (cópia)"
    if (( DRY_RUN )); then
        printf '    [dry-run] sudo palamar-hyprland apply --scope system\n'
        return 0
    fi
    sudo --preserve-env=HOME "$REPO_DIR/target/release/palamar-hyprland" \
        --repo "$REPO_DIR" apply --scope system
}

enable_sddm() {
    step "Login gráfico"
    if systemctl is-enabled sddm >/dev/null 2>&1; then
        skip "sddm já habilitado"
        return
    fi
    run sudo systemctl enable sddm
}

finish() {
    step "Pronto"
    cat <<'EOF'
    Falta apenas o que não cabe no repositório:
      - ~/Imagens/wallpapers: sua coleção pessoal (ver wallpapers.txt).
        O papel de parede em uso vem dos temas e já está aplicado.

    Saia da sessão e entre pelo Hyprland.
EOF
}

main() {
    (( DRY_RUN )) && printf '\033[1;33mModo dry-run: nada será alterado.\033[0m\n'
    ensure_base
    ensure_repo
    ensure_yay
    build_cli
    install_packages
    ensure_shell
    link_user_configs
    refresh_fonts
    ensure_theme
    link_system_configs
    enable_sddm
    finish
}

main "$@"
