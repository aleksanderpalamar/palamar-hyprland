# palamar-hyprland

Réplica do ambiente Hyprland desta máquina: configs, scripts, listas de pacotes e
a parte de sistema. O repositório é a fonte da verdade — `~/.config` aponta para
ele por symlink.

## Estrutura

| Caminho | Conteúdo |
|---|---|
| `config/` | arquivos de `~/.config` |
| `bin/` | scripts de `~/.local/bin` |
| `home/` | o resto do `$HOME`: os 22 temas com os 114 fundos de tela (62 MB) |
| `system/` | arquivos fora do `$HOME` (`/etc`, o tema do SDDM) |
| `packages/` | `pacman.txt`, `aur.txt`, `flatpak.txt` e `ignore.txt` |
| `manifest.toml` | gerado pelo `capture`: a lista de destinos rastreados |
| `capture.toml` | o que é rastreado e o que é ignorado |
| `wallpapers.txt` | nomes da coleção pessoal de `~/Imagens/wallpapers` (não versionada) |

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

`apply` nunca sobrescreve: um arquivo existente vira `<nome>.bak.<epoch>` antes de ser
substituído.

O `$HOME` recebe **symlink** para o repositório, então editar a config altera o repo.
Já `/etc` e `/usr/share` recebem **cópia**: o greeter do SDDM roda como usuário
`sddm` e não atravessa um `$HOME` com permissão `700`, e o systemd lê
`locale.conf` e `vconsole.conf` antes de o `/home` estar montado. Link ali
deixaria o teclado, o locale e a tela de login quebrados.

O escopo padrão é `user`: um `apply` comum só mexe no `$HOME` e avisa quantas
entradas de sistema deixou de fora. `--scope system` faz só essas, e `--scope all`
faz as duas.

## Máquina nova

Num Arch recém-instalado, com o repositório em mãos, **um comando**:

```
./bootstrap.sh
```

Depois de publicar o repositório, o mesmo resultado sem clonar antes:

```
curl -fsSL https://raw.githubusercontent.com/aleksanderpalamar/palamar-hyprland/main/bootstrap.sh | bash
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
5. `packages install` — 177 pacotes dos repos, 20 do AUR, 6 flatpaks
6. Clona oh-my-zsh, powerlevel10k e os plugins; põe o zsh como shell de login
7. `apply` — os links do `$HOME` (configs, scripts, temas, fontes, dotfiles do shell)
8. `fc-cache` para registrar as fontes
9. `hypr-theme refresh` — gera o estado do tema e aplica o fundo de tela
10. `apply --scope system` com `sudo` — copia `/etc` e o tema do SDDM
11. Habilita o `sddm`

Ao fim, o ambiente está igual ao desta máquina: Hyprland, waybar, quickshell,
mako, fuzzel, kitty, hyprlock, os 22 temas com seus fundos, o shell com o
powerlevel10k, o teclado e o locale, e a tela de login com o mesmo fundo.

### Temas e fundos de tela

Os 114 fundos dos 22 temas são versionados em `home/.local/share/hypr-themes`,
junto com `colors.toml`, `icons.theme`, `preview.png` e `vscode.json` de cada um.
Os modelos que o `hypr-theme` usa para gerar o visual (waybar, mako, fuzzel,
kitty, hyprlock, quickshell, btop, VS Code) ficam em `config/hypr-theme/templates`.

O que o `hypr-theme` gera a partir deles (`~/.local/state/hypr-theme` e o link
`~/.config/hypr/current/background`) não é versionado: o passo 9 do bootstrap
recria tudo com `hypr-theme refresh`, que sem estado anterior assume o
Tokyo Night — o tema e o fundo em uso hoje. Depois, `SUPER + SHIFT + CTRL + ESPAÇO`
troca o tema e `SUPER + CTRL + ESPAÇO` troca só o fundo.

### O que o repositório não cobre

- `~/Imagens/wallpapers` — a coleção pessoal de 1,1 GB. Os fundos **dos temas**
  estão todos aqui; essa pasta é acervo, e `wallpapers.txt` lista o que ela tem.
  Sem ela, o seletor de fundo mostra só os fundos do tema atual, e nada mais muda.
- O boot (GRUB, UKI, dual-boot) e o DKMS do volante, que pertencem à instalação
  do Arch, não ao ambiente gráfico.

## Manutenção

Depois de mexer em alguma config:

```
palamar-hyprland capture          # se mexeu em arquivo novo
palamar-hyprland packages capture # se instalou ou removeu pacote
git diff
```

Com os symlinks ativos, editar `~/.config/hypr/hyprland.lua` já altera o repo — o
`capture` só é necessário para arquivos que ainda não estão no manifesto.

O manifesto guarda só o destino de cada arquivo. O caminho dentro do repositório
e o escopo saem do `src/domain/layout.rs`, então não existe como os três
discordarem entre si.

Pacotes instalados aqui mas que não fazem parte do ambiente ficam em
`packages/ignore.txt`; o `capture` não os traz de volta.
