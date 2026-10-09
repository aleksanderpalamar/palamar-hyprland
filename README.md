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

Num Arch recém-instalado, **um comando**:

```
curl -fsSL https://raw.githubusercontent.com/aleksanderpalamar/palamar-hyprland/main/bootstrap.sh | bash
```

Se o repositório já estiver clonado:

```
./bootstrap.sh
```

Para ver o que ele faria, sem alterar nada:

```
./bootstrap.sh --dry-run
```

O script é idempotente: rodar de novo não repete o que já está feito.

### O que ele faz

1. Instala `git`, `rust` e `base-devel`
2. Clona este repositório em `~/Projetos/palamar-hyprland`
3. Instala o `yay`, se faltar
4. Compila a CLI
5. `packages install` — 172 pacotes dos repos, 20 do AUR, 6 flatpaks
6. `apply` — os 164 links do `$HOME`
7. Clona o tema do SDDM e aplica a parte de sistema com `sudo`
8. Habilita o `sddm`

### O que fica de fora

- `~/Imagens/wallpapers` (1,1 GB) — restaurar do backup; `wallpapers.txt` lista o que havia
- O fundo da tela de login — escolher com `sddm-select-wallpaper`
- O boot (GRUB, UKI, dual-boot) e o DKMS do volante

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
