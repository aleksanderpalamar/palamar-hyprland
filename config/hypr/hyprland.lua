------------------
---- MONITORS ----
------------------
hl.monitor({
    output   = "HDMI-A-1",
    mode     = "1920x1080@60.00",
    position = "0x0",
    scale    = 1,

    bitdepth = 10,

    -- Forcar cm = "hdr" aqui joga TODO o desktop SDR dentro de um container
    -- PQ/BT.2020 de ~96 nits. A LG, ao ver sinal HDR10, liga o tone mapping dela
    -- (feito para conteudo de 1000 nits) e come o contraste -> aspecto "fumaca".
    --
    -- Com "auto" a EDID desta LG anuncia BT2020 e o Hyprland escolhe o preset
    -- "wide": gamut largo com curva SDR, que e o que o desktop quer.
    -- Se as cores ficarem estouradas/neon, troque por cm = "srgb" (segue 10-bit).
    --
    -- ATENCAO: render.cm_auto_hdr = 1 NAO funciona nesta TV -- testado com mpv
    -- gpu-next em HDR10 real e a surface solitary. O compositor sempre anuncia
    -- "srgb / 80 nits" para o app, entao o player tonemapeia HDR->SDR sozinho e
    -- nunca submete conteudo HDR; o auto-HDR nao tem o que detectar.
    -- Para HDR real use SUPER+SHIFT+H (~/.local/bin/hypr-hdr-toggle).
    cm = "auto",

    -- Estes so valem quando a tela esta DE FATO em HDR (via o toggle acima).
    -- O script sobrescreve os quatro em runtime; aqui ficam so os defaults.
    sdrbrightness = 1.2,
    sdrsaturation = 1.0,
})

-- Regra de seguranca para outros monitores que forem conectados.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })



---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal    = "kitty"
local fileManager = "nautilus"
local launcher    = "fuzzel"  -- pesquisa direta em todos os apps, como o walker do Omarchy
local menu        = "/home/palamar/.local/bin/hypr-app-menu"  -- navegação por categoria
local browser     = "firefox"


-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function()
    -- O frontend do xdg-desktop-portal sobrevive a troca de sessao e fica sem backend
    -- (ScreenCast some, o OBS perde as fontes de captura de tela). Reiniciar os dois
    -- na ordem, depois de exportar o ambiente, amarra o portal a esta sessao.
    hl.exec_cmd("sh -c 'dbus-update-activation-environment --systemd --all; systemctl --user restart xdg-desktop-portal-hyprland.service xdg-desktop-portal.service'")
    hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
    hl.exec_cmd("mako")
    hl.exec_cmd("waybar")
    hl.exec_cmd("qs -c palamar --no-duplicate --daemonize")
    -- Hyprpaper uses the persistent symlink maintained by Waypaper.
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("nm-applet --indicator")
    -- Clipboard history is optional until the official cliphist package is installed.
    hl.exec_cmd("sh -c 'command -v cliphist >/dev/null 2>&1 && { wl-paste --type text --watch cliphist store & wl-paste --type image --watch cliphist store & }'")
end)



-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_STYLE_OVERRIDE", "kvantum")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Visual do Omarchy (default/hypr/looknfeel.lua) com as cores do tema Tokyo Night.
-- Backup da config anterior: ~/.config/hypr/backups/antes-omarchy-visual-2026-10-07/

-- As cores das bordas vêm do tema atual (hypr-theme, SUPER + SHIFT + CTRL + ESPAÇO).
-- Se o arquivo gerado faltar ou quebrar, fica o Tokyo Night.
local theme_ok, theme = pcall(dofile, os.getenv("HOME") .. "/.local/state/hypr-theme/hyprland.lua")
if not theme_ok or type(theme) ~= "table" then
    theme = { active_border = "rgb(7aa2f7)", inactive_border = "rgba(595959aa)" }
end
local active_border_color   = theme.active_border
local inactive_border_color = theme.inactive_border

hl.config({
    render = {
        cm_enabled = true,
        cm_auto_hdr = 1,
        use_fp16 = 2,
    },

    general = {
        gaps_in     = 5,
        gaps_out    = 10,
        border_size = 2,

        col = {
            active_border   = active_border_color,
            inactive_border = inactive_border_color,
        },

        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding = 0,

        shadow = {
            enabled = false,
        },

        blur = {
            enabled = false,
        },
    },

    group = {
        col = {
            border_active   = active_border_color,
            border_inactive = inactive_border_color,
        },

        groupbar = {
            font_size                 = 12,
            font_family               = "monospace",
            font_weight_active        = "ultraheavy",
            font_weight_inactive      = "normal",
            indicator_height          = 1,
            indicator_gap             = 5,
            height                    = 22,
            gaps_in                   = 5,
            gaps_out                  = 0,
            text_color                = "rgb(ffffff)",
            text_color_inactive       = "rgba(ffffff90)",
            col = {
                active   = "rgba(00000040)",
                inactive = "rgba(00000020)",
            },
            gradients                 = true,
            gradient_rounding         = 0,
            gradient_round_only_edges = false,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Animações do Omarchy, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1.0}  } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 3.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "fadeSwitch",    enabled = false })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = false })

hl.config({
    dwindle = {
        preserve_split = true,
        force_split    = 2,
    },

    scrolling = {
        column_width = 0.49,
    },

    master = {
        new_status = "master",
    },
})


----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper    = 0,
        disable_hyprland_logo      = true,
        disable_splash_rendering   = true,
        background_color           = "rgb(000000)",
        disable_scale_notification = true,
        focus_on_activate          = true,
        middle_click_paste         = false,
        anr_missed_pings           = 3,
        on_focus_under_fullscreen  = 1,
        initial_workspace_tracking = 0,
        allow_session_lock_restore = true,
        key_press_enables_dpms     = true,
        mouse_move_enables_dpms    = true,
    },

    cursor = {
        hide_on_key_press        = true,
        warp_on_change_workspace = 1,
    },

    binds = {
        hide_special_on_workspace_change = true,
    },

    ecosystem = {
        no_update_news = true,
    },
})


---------------
---- INPUT ----
---------------

-- Igual ao Omarchy, menos o compose:caps (ele transforma o Caps Lock em tecla
-- Compose); no ABNT2 os acentos já vêm das teclas mortas.
hl.config({
    input = {
        kb_layout  = "br",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        repeat_rate        = 40,
        repeat_delay       = 250,
        numlock_by_default = true,

        touchpad = {
            natural_scroll       = false,
            clickfinger_behavior = true,
            scroll_factor        = 0.4,
        },
    },
})

-- O receptor do teclado (Compx 2.4G) aparece como dois teclados, e o Hyprland
-- guarda um Caps Lock para cada um. O Caps travava ligado nesta segunda
-- interface e vazava para a janela ao trocar o foco pelo mouse.
-- A digitação normal vem toda pela interface principal.
hl.device({
    name    = "compx-2.4g-wireless-receiver-keyboard",
    enabled = false,
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})


---------------------
---- KEYBINDINGS ----
---------------------

-- Atalhos do Omarchy (default/hypr/bindings/*.lua). Onde o Omarchy chama um
-- script omarchy-*, o atalho usa o programa equivalente desta máquina.
-- SUPER + K lista todos os atalhos que têm descrição.

local bin = "/home/palamar/.local/bin/"

local function bind(keys, description, action, opts)
    opts = opts or {}
    opts.description = description
    if type(action) == "string" then
        action = hl.dsp.exec_cmd(action)
    end
    hl.bind(keys, action, opts)
end

local function has_tag(window, wanted)
    for _, tag in ipairs(window.tags or {}) do
        -- Tags dinâmicas terminam em "*".
        if tag:gsub("%*$", "") == wanted then
            return true
        end
    end
    return false
end

-- Manda o atalho para a janela focada em dois tempos (down/up) porque o
-- send_shortcut às vezes deixa a tecla presa. Mesma solução do Omarchy.
local function send_shortcut_once(mods, key)
    return function()
        hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
        hl.timer(function()
            hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
        end, { timeout = 50, type = "oneshot" })
    end
end

-- Copiar/colar universal: terminais usam CTRL + SHIFT + C/V, o resto CTRL + C/V.
local function universal_clipboard_shortcut(key)
    return function()
        local window = hl.get_active_window()
        if window and has_tag(window, "terminal") then
            send_shortcut_once("CTRL SHIFT", key)()
        else
            send_shortcut_once("CTRL", key)()
        end
    end
end

-- SUPER + O: solta a janela (flutuante, centralizada e fixada por cima de tudo).
local function toggle_pop()
    local window = hl.get_active_window()
    if not window then
        return
    end

    if window.pinned then
        hl.dispatch(hl.dsp.window.pin())
        hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
        hl.dispatch(hl.dsp.window.tag({ tag = "-pop" }))
    else
        hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
        hl.dispatch(hl.dsp.window.resize({ x = 1300, y = 900 }))
        hl.dispatch(hl.dsp.window.center())
        hl.dispatch(hl.dsp.window.pin())
        hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top" }))
        hl.dispatch(hl.dsp.window.tag({ tag = "+pop" }))
    end
end

-- SUPER + L: alterna o workspace atual entre dwindle e scrolling.
local function toggle_workspace_layout()
    local workspace = hl.get_active_workspace()
    if not workspace then
        return
    end

    local layout = "dwindle"
    if workspace.tiled_layout == "dwindle" then
        layout = "scrolling"
    end

    hl.workspace_rule({ workspace = tostring(workspace.id), layout = layout })
    hl.dispatch(hl.dsp.exec_cmd("notify-send -t 2000 'Layout do workspace: " .. layout .. "'"))
end

-- SUPER + BACKSPACE: liga/desliga a transparência da janela focada.
local function toggle_transparency()
    local window = hl.get_active_window()
    if not window then
        return
    end

    if has_tag(window, "terminal") or has_tag(window, "transparent") then
        hl.dispatch(hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" }))
    else
        hl.dispatch(hl.dsp.window.tag({ tag = "+transparent" }))
        hl.dispatch(hl.dsp.window.set_prop({ prop = "opaque", value = "false" }))
    end
end

-- SUPER + SHIFT + BACKSPACE: tira/devolve os espaços e bordas entre janelas.
local no_gaps = false
local function toggle_gaps()
    no_gaps = not no_gaps
    if no_gaps then
        hl.config({ general = { gaps_in = 0, gaps_out = 0, border_size = 0 } })
    else
        hl.config({ general = { gaps_in = 5, gaps_out = 10, border_size = 2 } })
    end
end

-- Aplicativos
bind("SUPER + RETURN",               "Terminal",                        terminal)
bind("SUPER + SHIFT + RETURN",       "Navegador",                       browser)
bind("SUPER + SHIFT + B",            "Navegador",                       browser)
bind("SUPER + SHIFT + ALT + B",      "Navegador (privado)",             browser .. " --private-window")
bind("SUPER + SHIFT + F",            "Gerenciador de arquivos",         fileManager .. " --new-window")
bind("SUPER + SHIFT + N",            "Editor",                          "code")
bind("SUPER + SHIFT + M",            "Música",                          "spotify")
bind("SUPER + SHIFT + O",            "Obsidian",                        "flatpak run md.obsidian.Obsidian")
bind("SUPER + SHIFT + A",            "ChatGPT",                         "gtk-launch chatgpt")

-- Atalhos que já eram seus e não colidem com os do Omarchy
bind("SUPER + E",                    "Gerenciador de arquivos",         fileManager)
bind("SUPER + B",                    "Navegador",                       browser)
bind("SUPER + M",                    "Aplicativos por categoria",       menu)
bind("SUPER + H",                    "Encerrar sessão (hyprshutdown)",  "hyprshutdown")
bind("SUPER + R",                    "Recarregar Hyprland e waybar",    "sh -c 'hyprctl reload; pkill -SIGUSR2 waybar'")
bind("SUPER + SHIFT + H",            "Alternar SDR/HDR",                bin .. "hypr-hdr-toggle")

-- Janelas
bind("SUPER + W",                    "Fechar janela",                   hl.dsp.window.close())
bind("SUPER + Q",                    "Fechar janela",                   hl.dsp.window.close())
bind("SUPER + J",                    "Alternar divisão",                hl.dsp.layout("togglesplit"))
bind("SUPER + P",                    "Pseudo-janela",                   hl.dsp.window.pseudo())
bind("SUPER + T",                    "Alternar flutuante/lado a lado",  hl.dsp.window.float({ action = "toggle" }))
bind("SUPER + F",                    "Tela cheia",                      hl.dsp.window.fullscreen({ mode = "fullscreen" }))
bind("SUPER + ALT + F",              "Largura total",                   hl.dsp.window.fullscreen({ mode = "maximized" }))
bind("SUPER + O",                    "Soltar janela (flutuar e fixar)", toggle_pop)
bind("SUPER + L",                    "Alternar layout do workspace",    toggle_workspace_layout)

bind("SUPER + left",                 "Foco à esquerda",                 hl.dsp.focus({ direction = "l" }))
bind("SUPER + right",                "Foco à direita",                  hl.dsp.focus({ direction = "r" }))
bind("SUPER + up",                   "Foco acima",                      hl.dsp.focus({ direction = "u" }))
bind("SUPER + down",                 "Foco abaixo",                     hl.dsp.focus({ direction = "d" }))

bind("SUPER + SHIFT + left",         "Trocar janela com a da esquerda", hl.dsp.window.swap({ direction = "l" }))
bind("SUPER + SHIFT + right",        "Trocar janela com a da direita",  hl.dsp.window.swap({ direction = "r" }))
bind("SUPER + SHIFT + up",           "Trocar janela com a de cima",     hl.dsp.window.swap({ direction = "u" }))
bind("SUPER + SHIFT + down",         "Trocar janela com a de baixo",    hl.dsp.window.swap({ direction = "d" }))

-- Workspaces: code:10..19 são as teclas 1..0 pela posição física.
for i = 1, 10 do
    local key = "code:" .. tostring(i + 9)
    bind("SUPER + " .. key,               "Ir para o workspace " .. i,                hl.dsp.focus({ workspace = tostring(i) }))
    bind("SUPER + SHIFT + " .. key,       "Mover janela para o workspace " .. i,      hl.dsp.window.move({ workspace = tostring(i) }))
    bind("SUPER + SHIFT + ALT + " .. key, "Mover janela (sem seguir) para o " .. i,   hl.dsp.window.move({ workspace = tostring(i), follow = false }))
end

-- Rascunho (scratchpad). code:49 é a tecla à esquerda do 1.
bind("SUPER + S",                    "Mostrar/ocultar rascunho",        hl.dsp.workspace.toggle_special("scratchpad"))
bind("SUPER + ALT + S",              "Mover janela para o rascunho",    hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
bind("SUPER + code:49",              "Mostrar/ocultar rascunho",        hl.dsp.workspace.toggle_special("scratchpad"))
bind("SUPER + SHIFT + code:49",      "Mover janela para o rascunho",    hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

bind("SUPER + TAB",                  "Próximo workspace",               hl.dsp.focus({ workspace = "e+1" }))
bind("SUPER + SHIFT + TAB",          "Workspace anterior",              hl.dsp.focus({ workspace = "e-1" }))
bind("SUPER + CTRL + TAB",           "Último workspace usado",          hl.dsp.focus({ workspace = "previous" }))

bind("SUPER + SHIFT + ALT + left",   "Mover workspace p/ monitor à esquerda", hl.dsp.workspace.move({ monitor = "l" }))
bind("SUPER + SHIFT + ALT + right",  "Mover workspace p/ monitor à direita",  hl.dsp.workspace.move({ monitor = "r" }))
bind("SUPER + SHIFT + ALT + up",     "Mover workspace p/ monitor acima",      hl.dsp.workspace.move({ monitor = "u" }))
bind("SUPER + SHIFT + ALT + down",   "Mover workspace p/ monitor abaixo",     hl.dsp.workspace.move({ monitor = "d" }))

bind("ALT + TAB",                    "Próxima janela",                  hl.dsp.window.cycle_next())
bind("ALT + SHIFT + TAB",            "Janela anterior",                 hl.dsp.window.cycle_next({ next = false }))
bind("ALT + TAB",                    "Trazer janela ativa para frente", hl.dsp.window.bring_to_top())
bind("ALT + SHIFT + TAB",            "Trazer janela ativa para frente", hl.dsp.window.bring_to_top())

bind("CTRL + ALT + TAB",             "Próximo monitor",                 hl.dsp.focus({ monitor = "+1" }))
bind("CTRL + ALT + SHIFT + TAB",     "Monitor anterior",                hl.dsp.focus({ monitor = "-1" }))

-- Redimensionar: code:20 é a tecla "-" e code:21 a tecla "=".
bind("SUPER + code:20",                 "Alargar janela",                  hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
bind("SUPER + code:21",                 "Estreitar janela",                hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
bind("SUPER + SHIFT + code:20",         "Encurtar janela",                 hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
bind("SUPER + SHIFT + code:21",         "Alongar janela",                  hl.dsp.window.resize({ x = 0, y = 100, relative = true }))
bind("SUPER + ALT + code:20",           "Alargar janela um pouco",         hl.dsp.window.resize({ x = -25, y = 0, relative = true }))
bind("SUPER + ALT + code:21",           "Estreitar janela um pouco",       hl.dsp.window.resize({ x = 25, y = 0, relative = true }))
bind("SUPER + SHIFT + ALT + code:20",   "Encurtar janela um pouco",        hl.dsp.window.resize({ x = 0, y = -25, relative = true }))
bind("SUPER + SHIFT + ALT + code:21",   "Alongar janela um pouco",         hl.dsp.window.resize({ x = 0, y = 25, relative = true }))
bind("SUPER + CTRL + code:20",          "Alargar janela bastante",         hl.dsp.window.resize({ x = -300, y = 0, relative = true }))
bind("SUPER + CTRL + code:21",          "Estreitar janela bastante",       hl.dsp.window.resize({ x = 300, y = 0, relative = true }))
bind("SUPER + CTRL + SHIFT + code:20",  "Encurtar janela bastante",        hl.dsp.window.resize({ x = 0, y = -300, relative = true }))
bind("SUPER + CTRL + SHIFT + code:21",  "Alongar janela bastante",         hl.dsp.window.resize({ x = 0, y = 300, relative = true }))

bind("SUPER + mouse_down",           "Próximo workspace",               hl.dsp.focus({ workspace = "e+1" }))
bind("SUPER + mouse_up",             "Workspace anterior",              hl.dsp.focus({ workspace = "e-1" }))
bind("SUPER + mouse:272",            "Mover janela",                    hl.dsp.window.drag(),   { mouse = true })
bind("SUPER + mouse:273",            "Redimensionar janela",            hl.dsp.window.resize(), { mouse = true })

-- Grupos (abas de janelas)
bind("SUPER + G",                    "Agrupar/desagrupar",              hl.dsp.group.toggle())
bind("SUPER + ALT + G",              "Tirar janela do grupo",           hl.dsp.window.move({ out_of_group = true }))
bind("SUPER + ALT + left",           "Pôr janela no grupo à esquerda",  hl.dsp.window.move({ into_group = "l" }))
bind("SUPER + ALT + right",          "Pôr janela no grupo à direita",   hl.dsp.window.move({ into_group = "r" }))
bind("SUPER + ALT + up",             "Pôr janela no grupo acima",       hl.dsp.window.move({ into_group = "u" }))
bind("SUPER + ALT + down",           "Pôr janela no grupo abaixo",      hl.dsp.window.move({ into_group = "d" }))
bind("SUPER + ALT + TAB",            "Próxima janela do grupo",         hl.dsp.group.next())
bind("SUPER + ALT + SHIFT + TAB",    "Janela anterior do grupo",        hl.dsp.group.prev())
bind("SUPER + CTRL + left",          "Janela do grupo à esquerda",      hl.dsp.group.prev())
bind("SUPER + CTRL + right",         "Janela do grupo à direita",       hl.dsp.group.next())
bind("SUPER + ALT + mouse_down",     "Próxima janela do grupo",         hl.dsp.group.next())
bind("SUPER + ALT + mouse_up",       "Janela anterior do grupo",        hl.dsp.group.prev())
for index = 1, 5 do
    bind("SUPER + ALT + code:" .. tostring(index + 9), "Janela " .. index .. " do grupo", hl.dsp.group.active({ index = index }))
end

-- Menus e utilidades
bind("SUPER + SPACE",                "Pesquisar aplicativos",           launcher)
bind("SUPER + ALT + SPACE",          "Central de controle",             "qs ipc -c palamar call controlCenter toggle")
bind("SUPER + ESCAPE",               "Menu do sistema",                 bin .. "hypr-system-menu")
bind("XF86PowerOff",                 "Menu do sistema",                 bin .. "hypr-system-menu", { locked = true })
bind("SUPER + K",                    "Atalhos de teclado",              bin .. "hypr-keybindings")
bind("SUPER + SHIFT + SPACE",        "Mostrar/ocultar a barra",         "pkill -SIGUSR1 waybar")
bind("SUPER + CTRL + SPACE",         "Trocar papel de parede",          "qs ipc -c palamar call picker backgrounds")
bind("SUPER + SHIFT + CTRL + SPACE", "Trocar tema",                     "qs ipc -c palamar call picker themes")
bind("SUPER + SHIFT + S",            "Wallpaper da tela de login",      bin .. "sddm-select-wallpaper")
bind("SUPER + BACKSPACE",            "Transparência da janela",         toggle_transparency)
bind("SUPER + SHIFT + BACKSPACE",    "Espaços entre janelas",           toggle_gaps)
bind("SUPER + CTRL + L",             "Bloquear a tela",                 "pidof hyprlock || hyprlock")
bind("SUPER + CTRL + I",             "Bloqueio por inatividade",        "sh -c 'if pkill -x hypridle; then notify-send -t 2000 \"Bloqueio por inatividade desligado\"; else setsid -f hypridle >/dev/null 2>&1; notify-send -t 2000 \"Bloqueio por inatividade ligado\"; fi; pkill -RTMIN+9 waybar'")

-- Notificações (mako)
bind("SUPER + comma",                "Dispensar última notificação",    "makoctl dismiss")
bind("SUPER + SHIFT + comma",        "Dispensar todas as notificações", "makoctl dismiss --all")
bind("SUPER + CTRL + comma",         "Silenciar notificações",          "sh -c 'makoctl mode -t do-not-disturb; pkill -RTMIN+10 waybar'")
bind("SUPER + ALT + comma",          "Abrir última notificação",        "makoctl invoke")
bind("SUPER + SHIFT + ALT + comma",  "Reabrir notificação dispensada",  "makoctl restore")

-- Painéis da barra (quickshell "palamar"), os mesmos do clique nos ícones da waybar
local panel = "qs ipc -c palamar call panels toggle "
bind("SUPER + CTRL + A",             "Painel de som",                   panel .. "audio")
bind("SUPER + CTRL + B",             "Painel de bluetooth",             panel .. "bluetooth")
bind("SUPER + CTRL + W",             "Painel de rede",                  panel .. "network")
bind("SUPER + CTRL + D",             "Painel da tela",                  panel .. "display")
bind("SUPER + CTRL + ALT + D",       "Calendário",                      panel .. "calendar")
bind("SUPER + CTRL + T",             "Monitor do sistema (btop)",       terminal .. " -e btop")

-- Lupa
bind("SUPER + CTRL + Z", "Aumentar zoom", function()
    local zoom = hl.get_config("cursor.zoom_factor") or 1
    hl.config({ cursor = { zoom_factor = zoom + 1 } })
end)
bind("SUPER + CTRL + ALT + Z", "Zoom normal", function()
    hl.config({ cursor = { zoom_factor = 1 } })
end)

-- Captura de tela
bind("Print",                        "Captura de uma área",             bin .. "hypr-screenshot region")
bind("SHIFT + Print",                "Captura da tela inteira",         bin .. "hypr-screenshot full")
bind("SUPER + Print",                "Captura de uma área",             bin .. "hypr-screenshot region")
bind("SUPER + SHIFT + Print",        "Captura da janela",               bin .. "hypr-screenshot window")

-- Área de transferência universal
bind("SUPER + A",                    "Selecionar tudo",                 send_shortcut_once("CTRL", "A"))
bind("SUPER + C",                    "Copiar",                          universal_clipboard_shortcut("C"))
bind("SUPER + V",                    "Colar",                           universal_clipboard_shortcut("V"))
bind("SUPER + X",                    "Recortar",                        send_shortcut_once("CTRL", "X"))
bind("SUPER + CTRL + V",             "Histórico da área de transferência", bin .. "hypr-clipboard")

-- Volume, brilho e mídia
bind("XF86AudioRaiseVolume",         "Aumentar volume",                 "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", { locked = true, repeating = true })
bind("XF86AudioLowerVolume",         "Diminuir volume",                 "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",      { locked = true, repeating = true })
bind("ALT + XF86AudioRaiseVolume",   "Aumentar volume (fino)",          "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 1%+", { locked = true, repeating = true })
bind("ALT + XF86AudioLowerVolume",   "Diminuir volume (fino)",          "wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-",      { locked = true, repeating = true })
bind("XF86AudioMute",                "Silenciar",                       "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",     { locked = true })
bind("XF86AudioMicMute",             "Silenciar microfone",             "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",   { locked = true })
bind("XF86MonBrightnessUp",          "Aumentar brilho",                 "brightnessctl -e4 -n2 set 5%+",                  { locked = true, repeating = true })
bind("XF86MonBrightnessDown",        "Diminuir brilho",                 "brightnessctl -e4 -n2 set 5%-",                  { locked = true, repeating = true })

bind("XF86AudioNext",                "Próxima faixa",                   "playerctl next",       { locked = true })
bind("ALT + XF86AudioPlay",          "Próxima faixa",                   "playerctl next",       { locked = true })
bind("XF86AudioPause",               "Pausar",                          "playerctl play-pause", { locked = true })
bind("XF86AudioPlay",                "Tocar",                           "playerctl play-pause", { locked = true })
bind("XF86AudioPrev",                "Faixa anterior",                  "playerctl previous",   { locked = true })
bind("ALT + SHIFT + XF86AudioPlay",  "Faixa anterior",                  "playerctl previous",   { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Regras do Omarchy (default/hypr/windows.lua e default/hypr/apps/*.lua).
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

hl.window_rule({
    -- Ignore maximize requests from all apps.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

-- Terminais ganham a tag "terminal" (usada pelo copiar/colar universal e pela transparência).
hl.window_rule({
    match = { class = "(Alacritty|kitty|com.mitchellh.ghostty|foot|org\\.codeberg\\.dnkl\\.foot|wezterm)" },
    tag   = "+terminal",
})
hl.window_rule({ match = { class = "org\\.gnome\\.Nautilus" }, tag = "+transparent" })

-- Transparência padrão do Omarchy.
hl.window_rule({ match = { tag = "terminal" },    opacity = "0.985 0.96" })
hl.window_rule({ match = { tag = "transparent" }, opacity = "0.985 0.96" })

-- Rolagem do touchpad mais rápida no terminal.
hl.window_rule({ match = { class = "(Alacritty|kitty)" }, scroll_touchpad = 1.5 })

-- Janelas flutuantes: diálogos do portal, visualizadores e "Sobre".
hl.window_rule({
    match = { class = "(org.gnome.NautilusPreviewer|org.gnome.Evince|About|imv|mpv|xdg-desktop-portal-gtk)" },
    tag   = "+floating-window",
})
hl.window_rule({
    match = {
        class = "(sublime_text|DesktopEditors|org.gnome.Nautilus)",
        title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to [open|save].*|[C|c]hoose.*)",
    },
    tag   = "+floating-window",
})
hl.window_rule({ match = { tag = "floating-window" }, float = true })
hl.window_rule({ match = { tag = "floating-window" }, center = true })
hl.window_rule({ match = { tag = "floating-window" }, size = { 875, 600 } })

-- Janela solta com SUPER + O ganha cantos arredondados.
hl.window_rule({ match = { tag = "pop" }, rounding = 8 })

-- Impede o bloqueio por inatividade enquanto a janela estiver aberta.
hl.window_rule({ match = { tag = "noidle" }, idle_inhibit = "always" })

-- Steam
hl.window_rule({ match = { class = "steam" }, float = true, idle_inhibit = "fullscreen" })
hl.window_rule({ match = { class = "steam", title = "Steam" }, center = true, size = { 1100, 700 } })
hl.window_rule({ match = { class = "steam", title = "Friends List" }, size = { 460, 800 } })

-- Picture-in-picture
hl.window_rule({ match = { title = "(Picture.?in.?[Pp]icture)" }, tag = "+pip" })
hl.window_rule({
    match             = { tag = "pip" },
    float             = true,
    pin               = true,
    size              = { 600, 338 },
    keep_aspect_ratio = true,
    border_size       = 0,
    move              = { "(monitor_w-window_w-40)", "(monitor_h*0.04)" },
})

-- Navegadores
hl.window_rule({ match = { class = "((google-)?[cC]hrom(e|ium)|[bB]rave-browser|[mM]icrosoft-edge|Vivaldi-stable|helium)" }, tag = "+chromium-based-browser" })
hl.window_rule({ match = { class = "([fF]irefox|zen|librewolf)" }, tag = "+firefox-based-browser" })
hl.window_rule({ match = { tag = "chromium-based-browser" }, tile = true })
-- Esconde o aviso de "está compartilhando a tela".
hl.window_rule({ match = { title = ".*is sharing.*" }, workspace = "special silent" })

-- JetBrains: sem foco seguindo o mouse (menus somem).
hl.window_rule({ match = { class = "^(jetbrains-.*)$" }, no_follow_mouse = true })
