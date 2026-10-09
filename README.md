# palamar-hyprland

Réplica do ambiente Hyprland desta máquina: configs, scripts, listas de pacotes e
a parte de sistema. O repositório é a fonte da verdade — `~/.config` aponta para
ele por symlink.

## Estrutura

| Caminho | Conteúdo |
|---|---|
| `config/` | arquivos de `~/.config` |
| `bin/` | scripts de `~/.local/bin` |
| `home/` | o resto do `$HOME` (hoje, os temas em `.local/share/hypr-themes`) |
| `system/` | arquivos fora do `$HOME` (`/etc`, `/usr/share`) |
| `packages/` | `pacman.txt`, `aur.txt`, `flatpak.txt` e `ignore.txt` |
| `manifest.toml` | gerado pelo `capture`: origem → destino de cada arquivo |
| `capture.toml` | o que é rastreado e o que é ignorado |
| `wallpapers.txt` | nomes das imagens de `~/Imagens/wallpapers` (não versionadas) |

## Comandos

```
palamar-hyprland status              # o que está fora de sincronia
palamar-hyprland apply --dry-run     # mostra sem alterar
palamar-hyprland apply               # cria os symlinks (backup do que existir)
palamar-hyprland apply --scope all   # inclui /etc e /usr/share (precisa de root)
palamar-hyprland capture             # traz as configs do sistema para o repo
palamar-hyprland packages status     # pacotes faltando
palamar-hyprland packages install    # instala os que faltam
palamar-hyprland packages capture    # regenera as listas
```

`apply` nunca sobrescreve: um arquivo existente vira `<nome>.bak.<epoch>` antes do link.

O escopo padrão é `user`: um `apply` comum só mexe no `$HOME` e avisa quantas
entradas de sistema deixou de fora. `--scope system` faz só essas, e `--scope all`
faz as duas.

## Máquina nova

1. **Base**

   ```
   sudo pacman -S --needed git rust
   git clone <este-repo> ~/Projetos/palamar-hyprland
   cd ~/Projetos/palamar-hyprland && cargo build --release
   ```

2. **yay** (necessário para `aur.txt`)

   ```
   git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si
   ```

3. **Pacotes**

   ```
   ./target/release/palamar-hyprland packages install
   ```

4. **Configs do usuário**

   ```
   ./target/release/palamar-hyprland apply --dry-run
   ./target/release/palamar-hyprland apply
   ```

5. **Parte de sistema** (precisa de root)

   ```
   sudo --preserve-env=HOME ./target/release/palamar-hyprland apply --scope system
   ```

6. **Tema do SDDM** — ver `system/sddm-theme.txt`

   ```
   sudo git clone https://github.com/JaKooLit/simple-sddm-2.git \
     /usr/share/sddm/themes/simple_sddm_2
   sudo chown -R $USER:$USER /usr/share/sddm/themes/simple_sddm_2
   ```

   O `theme.conf` é aplicado pelo `apply`. O fundo do login se escolhe com
   `sddm-select-wallpaper`.

7. **Fundos dos temas** — os `backgrounds/` dos 22 temas não são versionados
   (57 MB). Eles vêm do Omarchy:

   ```
   git clone https://github.com/omacom/omarchy /tmp/omarchy
   for t in /tmp/omarchy/themes/*/; do
     n=$(basename "$t")
     [ -d ~/.local/share/hypr-themes/$n ] && cp -r "$t/backgrounds" ~/.local/share/hypr-themes/$n/
   done
   ```

8. **Wallpapers** — `~/Imagens/wallpapers` não é versionado. Restaurar do backup;
   `wallpapers.txt` lista o que havia.

## Manutenção

Depois de mexer em alguma config:

```
palamar-hyprland capture          # se mexeu em arquivo novo
palamar-hyprland packages capture # se instalou ou removeu pacote
git diff
```

Com os symlinks ativos, editar `~/.config/hypr/hyprland.lua` já altera o repo — o
`capture` só é necessário para arquivos que ainda não estão no manifesto.

Pacotes instalados aqui mas que não fazem parte do ambiente ficam em
`packages/ignore.txt`; o `capture` não os traz de volta.
