#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${PALAMAR_HYPRLAND_URL:-https://github.com/aleksanderpalamar/palamar-hyprland.git}"
REPO_DIR="${PALAMAR_HYPRLAND_DIR:-$HOME/Projetos/palamar-hyprland}"
SDDM_THEME_URL="https://github.com/JaKooLit/simple-sddm-2.git"
SDDM_THEME_DIR="/usr/share/sddm/themes/simple_sddm_2"
OMARCHY_URL="https://github.com/omacom/omarchy.git"
THEMES_DIR="$HOME/.local/share/hypr-themes"

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

ensure_sddm_theme() {
    step "Tema do SDDM"
    if [[ -d $SDDM_THEME_DIR/.git ]]; then
        skip "já existe"
    else
        run sudo git clone "$SDDM_THEME_URL" "$SDDM_THEME_DIR"
        run sudo chown -R "$USER:$USER" "$SDDM_THEME_DIR"
    fi
}

link_system_configs() {
    step "Configurações de sistema"
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

fetch_theme_backgrounds() {
    step "Fundos dos temas"
    if [[ -d $THEMES_DIR/tokyo-night/backgrounds ]]; then
        skip "já presentes"
        return
    fi
    if (( DRY_RUN )); then
        printf '    [dry-run] clona %s e copia os backgrounds\n' "$OMARCHY_URL"
        return 0
    fi
    local tmp
    tmp=$(mktemp -d)
    git clone --depth 1 "$OMARCHY_URL" "$tmp/omarchy"
    local theme name
    for theme in "$tmp"/omarchy/themes/*/; do
        name=$(basename "$theme")
        [[ -d $THEMES_DIR/$name && -d $theme/backgrounds ]] || continue
        cp -r "$theme/backgrounds" "$THEMES_DIR/$name/"
    done
    rm -rf "$tmp"
}

finish() {
    step "Pronto"
    cat <<'EOF'
    Falta apenas o que não cabe no repositório:
      - ~/Imagens/wallpapers (ver wallpapers.txt)
      - o fundo da tela de login: sddm-select-wallpaper

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
    link_user_configs
    ensure_sddm_theme
    link_system_configs
    enable_sddm
    fetch_theme_backgrounds
    finish
}

main "$@"
