-- If LuaRocks is installed, make sure that packages installed through it are -- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
--local lain = require("lain")
--local freedesktop   = require("freedesktop")
--local dpi = require("beautiful.xresources").apply_dpi

local xrandr = require("xrandr")

-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- This function will run once every time Awesome is started
local function run_once(cmd)
    awful.spawn.with_shell(string.format("pgrep -u $USER -fx '%s' > /dev/null || (%s)", cmd, cmd))
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        -- Make sure we don't go into an endless error loop
        if in_error then
            return
        end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions

modkey = "Mod3"
terminal = "konsole"
--terminal = "xfce4-terminal"
editor = os.getenv("EDITOR") or "/usr/bin/vim"
editor_cmd = terminal .. " -e " .. editor
rofi_cmd = "rofi -modi combi -combi-modi drun,run -show combi"

local themes = {
    "blackburn",       -- 1
    "copland",         -- 2
    "dremora",         -- 3
    "holo",            -- 4
    "multicolor",      -- 5
    "powerarrow",      -- 6
    "powerarrow-dark", -- 7
    "rainbow",         -- 8
    "steamburn",       -- 9
    "vertex",          -- 10
}
-- Themes define colours, icons, font and wallpapers.
beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
--beautiful.init(string.format( "%s/.config/awesome/themes/%s/theme.lua", os.getenv("HOME"), themes[1]))

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
    { "hotkeys", function()
        hotkeys_popup.show_help(nil, awful.screen.focused())
    end },
    { "edit config", editor_cmd .. " " .. awesome.conffile },
    { "restart", awesome.restart },
    { "quit", function()
        awesome.quit()
    end },
}

mymainmenu = awful.menu(
        { items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                    { "open terminal", terminal }
        }
        })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

local function set_wallpaper(s)
    -- Wallpaper
    -- if beautiful.wallpaper then
    --     local wallpaper = beautiful.wallpaper
    --     -- If wallpaper is a function, call it with the screen
    --     if type(wallpaper) == "function" then
    --         wallpaper = wallpaper(s)
    --     end
    --     gears.wallpaper.maximized(wallpaper, s, true)
    -- end
    --awful.spawn.with_shell("kill -USR1 $(cat /tmp/autofeh.pid)")
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.corner.nw,
    awful.layout.suit.floating,
    awful.layout.suit.max,
    -- awful.layout.suit.tile.left,
    -- awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    -- awful.layout.suit.fair,
    -- awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.magnifier,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- }}}

local _shown_menu = {}
task_control_menu = {}
function task_menu_toggle(c)
    if _shown_menu[1] ~= nil then
        _shown_menu[1]:hide()
        _shown_menu[1]:delete()
        _shown_menu[1] = nil
    end
    menu = awful.menu({
        {
            "Close",
            function ()
                c:kill()
            end,
        },
        {
            "Move",
            function ()
                awful.mouse.client.move(c)
            end,
        }
    })
    menu:show()
    _shown_menu[1] = menu
end

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    --awful.tag({ " 1", " 2", " 3", " 4", " 5", " 6", " 7", " 8", " 9" }, s, awful.layout.layouts[1])
    awful.tag.add("1", {
        screen = s,
        layout = awful.layout.suit.max,
        selected = true
    })
    for i = 2, 9 do
        awful.tag.add(i,
                { screen = s, layout = awful.layout.layouts[1] })
    end

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = wibox.layout.margin(awful.widget.layoutbox(s), 5, 3, 5, 5)
    s.mylayoutbox:buttons(gears.table.join(
            awful.button({ }, 1, function()
                awful.layout.inc(1)
            end),
            awful.button({ }, 3, function()
                awful.layout.inc(-1)
            end),
            awful.button({ }, 4, function()
                awful.layout.inc(1)
            end),
            awful.button({ }, 5, function()
                awful.layout.inc(-1)
            end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen = s,
        filter = awful.widget.taglist.filter.all,
        buttons = gears.table.join(
        awful.button({ }, 1, function(t)
            t:view_only()
        end),
        awful.button({ }, 3, awful.tag.viewtoggle),
        awful.button({ modkey }, 3, function(t)
            if client.focus then
                client.focus:toggle_tag(t)
            end
        end),
        awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
        awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
        )

    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen = s,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = gears.table.join(
            awful.button({ }, 1, function(c)
                if c == client.focus then
                    c.minimized = true
                else
                    c:emit_signal(
                    "request::activate",
                    "tasklist",
                    { raise = true })
                end
            end),
            awful.button({}, 2, function(c)
                c:kill()
            end),
            awful.button({ }, 3, task_menu_toggle
            --function(c)
                --awful.menu.client_list({ theme = { width = 250 } })
            --end),
            ),
            awful.button({ }, 4, function()
                awful.client.focus.byidx(1)
            end),
            awful.button({ }, 5, function()
                awful.client.focus.byidx(-1)
            end)
        ),
        style    = {
            border_width = 2,
            border_color = '#777777',
            shape        = gears.shape.rounded_bar,
        },

        widget_template = {
            id     = 'background_role',
            widget = wibox.container.background,
            {
                left  = 10,
                right = 10,
                widget = wibox.container.margin,
                {
                    layout = wibox.layout.fixed.horizontal,
                    {
                        {
                            id     = 'icon_role',
                            widget = wibox.widget.imagebox,
                        },
                        margins = 5,
                        widget  = wibox.container.margin,
                    },
                    {
                        id     = 'text_role',
                        widget = wibox.widget.textbox,
                    },
                },
            },
        },
    }

    -- Create a textclock widget
    topclock = wibox.widget.textclock("<span font=\"Source Code Pro Medium 12\">%H:%M:%S</span>", 1)
    botclock = wibox.widget.textclock("<span font=\"Source Code Pro Medium 10\">%a %d %b</span>", 1)
    mytextclock = wibox.widget {
        topclock,
        botclock,
        layout = wibox.layout.fixed.vertical,
    }

    -- Create systray
    systray = wibox.container.margin(wibox.widget.systray(true), 4, 4, 4, 4)

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "bottom", screen = s })
    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            -- mylauncher,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            --mykeyboardlayout,
            systray,
            mytextclock,
            s.mylayoutbox,
        },
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
        awful.button({ }, 3, function()
            mymainmenu:toggle()
        end)
--awful.button({ }, 4, awful.tag.viewnext),
--awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
        awful.key({ modkey, }, "s", hotkeys_popup.show_help,
                { description = "show help", group = "awesome" }),
        awful.key({ modkey, }, "Left", awful.tag.viewprev,
                { description = "view previous", group = "tag" }),
        awful.key({ modkey, }, "Right", awful.tag.viewnext,
                { description = "view next", group = "tag" }),
        awful.key({ modkey, }, "Escape", awful.tag.history.restore,
                { description = "go back", group = "tag" }),

        awful.key({ modkey, }, "j",
                function()
                    awful.client.focus.byidx(1)
                end,
                { description = "focus next by index", group = "client" }
        ),
        awful.key({ modkey, }, "k",
                function()
                    awful.client.focus.byidx(-1)
                end,
                { description = "focus previous by index", group = "client" }
        ),
        awful.key({ modkey, }, "w", function()
            mymainmenu:show()
        end,
                { description = "show main menu", group = "awesome" }),

-- Layout manipulation
        awful.key({ modkey, "Shift" }, "j", function()
            awful.client.swap.byidx(1)
        end,
                { description = "swap with next client by index", group = "client" }),
        awful.key({ modkey, "Shift" }, "k", function()
            awful.client.swap.byidx(-1)
        end,
                { description = "swap with previous client by index", group = "client" }),
        awful.key({ modkey, "Control" }, "j", function()
            awful.screen.focus_relative(1)
        end,
                { description = "focus the next screen", group = "screen" }),
        awful.key({ modkey, "Control" }, "k", function()
            awful.screen.focus_relative(-1)
        end,
                { description = "focus the previous screen", group = "screen" }),
        awful.key({ modkey, }, "u", awful.client.urgent.jumpto,
                { description = "jump to urgent client", group = "client" }),
        awful.key({ modkey, }, "Tab",
                function()
                    awful.client.focus.history.previous()
                    if client.focus then
                        client.focus:raise()
                    end
                end,
                { description = "go back", group = "client" }),

-- Standard program
        awful.key({ modkey, }, "Return", function()
            awful.spawn(terminal)
        end,
                { description = "open a terminal", group = "launcher" }),
        awful.key({ modkey, "Control" }, "r", awesome.restart,
                { description = "reload awesome", group = "awesome" }),
        awful.key({ modkey, "Shift" }, "e", awesome.quit,
                { description = "quit awesome", group = "awesome" }),

        awful.key({ modkey, }, "l", function()
            awful.tag.incmwfact(0.05)
        end, { description = "increase master width factor", group = "layout" }),

        awful.key({ modkey, }, "h", function()
            awful.tag.incmwfact(-0.05)
        end, { description = "decrease master width factor", group = "layout" }),

        awful.key({ modkey, "Shift" }, "h", function()
            awful.tag.incnmaster(1, nil, true)
        end, { description = "increase the number of master clients", group = "layout" }),

        awful.key({ modkey, "Shift" }, "l", function()
            awful.tag.incnmaster(-1, nil, true)
        end, { description = "decrease the number of master clients", group = "layout" }),

        awful.key({ modkey, "Control" }, "h", function()
            awful.tag.incncol(1, nil, true)
        end, { description = "increase the number of columns", group = "layout" }),

        awful.key({ modkey, "Control" }, "l", function()
            awful.tag.incncol(-1, nil, true)
        end, { description = "decrease the number of columns", group = "layout" }),

        awful.key({ modkey, }, "space", function()
            awful.layout.inc(1)
        end, { description = "select next", group = "layout" }),

        awful.key({ modkey, "Shift" }, "space", function()
            awful.layout.inc(-2)
        end, { description = "select previous", group = "layout" }),

        awful.key({ modkey, "Control" }, "n",
                function()
                    local c = awful.client.restore()
                    -- Focus restored client
                    if c then
                        c:emit_signal(
                                "request::activate", "key.unminimize", { raise = true }
                        )
                    end
                end,
                { description = "restore minimized", group = "client" }),

        awful.key({ modkey }, "x",
                function()
                    awful.prompt.run {
                        prompt = "Run Lua code: ",
                        textbox = awful.screen.focused().mypromptbox.widget,
                        exe_callback = awful.util.eval,
                        history_path = awful.util.get_cache_dir() .. "/history_eval"
                    }
                end,
                { description = "lua execute prompt", group = "awesome" }),

-- Prompt
-- awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
--           {description = "run prompt", group = "launcher"}),
-- Menubar
        awful.key({ modkey }, "p",
                function()
                    menubar.show()
                end,
                { description = "show the menubar", group = "launcher" }),
-- rofi
        awful.key({ modkey }, "d",
                function()
                    awful.spawn.with_shell(rofi_cmd)
                end,
                { description = "rofi", group = "awesome" }),
        awful.key({ "Mod1" }, "space",
                function()
                    awful.spawn.with_shell(rofi_cmd)
                end,
                { description = "rofi", group = "awesome" }),

-- other
        awful.key({ modkey, "Shift" }, "n", set_wallpaper,
                { description = "change wallpaper", group = "awesome" }),

        --awful.key({ "Mod4" }, "p", function() run_once("lxrandr") end,
        --{description = "Monitor Settings", group = "awesome"}),
        awful.key({ "Mod4" }, "p", xrandr.xrandr,
                { description = "Monitor Settings", group = "awesome" }),

-- xfce4-screenshooter
        awful.key({ modkey, "Shift" }, "x",
                function ()
                    awful.spawn.with_shell("xfce4-screenshooter")
                end,
                { description = "Xfce4 Screenshooter", group = "awesome" })
)

clientkeys = gears.table.join(
        awful.key({ modkey, }, "f",
                function(c)
                    c.fullscreen = not c.fullscreen
                    c:raise()
                end,
                { description = "toggle fullscreen", group = "client" }),

        awful.key({ modkey, "Shift" }, "q",
                function(c)
                    c:kill()
                end,
                { description = "close", group = "client" }),

        awful.key({ modkey, "Control" }, "space",
                function(c)
                    -- placement to center
                    if not awful.client.floating then
                        awful.placement.centered(c, nil)
                    end
                    awful.client.floating.toggle(c)
                end,
                { description = "toggle floating", group = "client" }),

        awful.key({ modkey, "Control" }, "Return",
                function(c)
                    c:swap(awful.client.getmaster())
                end,
                { description = "move to master", group = "client" }),

        awful.key({ modkey, }, "o",
                function(c)
                    c:move_to_screen()
                end,
                { description = "move to screen", group = "client" }),

        awful.key({ modkey, }, "t",
                function(c)
                    c.ontop = not c.ontop
                end,
                { description = "toggle keep on top", group = "client" }),

        awful.key({ modkey, }, "n",
                function(c)
                    c.minimized = true
                end,
                { description = "minimize", group = "client" }),

        awful.key({ modkey, }, "c",
                function(c)
                    awful.placement.centered(c, nil)
                end,
                { description = "put to center", group = "client" }),

        awful.key({ modkey, }, "m",
                function(c)
                    c.maximized = not c.maximized
                    c:raise()
                end,
                { description = "(un)maximize", group = "client" }),

        awful.key({ modkey, "Control" }, "m",
                function(c)
                    c.maximized_vertical = not c.maximized_vertical
                    c:raise()
                end,
                { description = "(un)maximize vertically", group = "client" }),

        awful.key({ modkey, "Shift" }, "m",
                function(c)
                    c.maximized_horizontal = not c.maximized_horizontal
                    c:raise()
                end,
                { description = "(un)maximize horizontally", group = "client" }),

        awful.key({ modkey }, "q",
                function(c)
                    awful.mouse.client.move(c)
                end,
                { description = "move", group = "client" })
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
    -- View tag only.
            awful.key({ modkey }, "#" .. i + 9,
                    function()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                            tag:view_only()
                        end
                    end,
                    { description = "view tag #" .. i, group = "tag" }),
    -- Toggle tag display.
            awful.key({ modkey, "Control" }, "#" .. i + 9,
                    function()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                            awful.tag.viewtoggle(tag)
                        end
                    end,
                    { description = "toggle tag #" .. i, group = "tag" }),
    -- Move client to tag.
            awful.key({ modkey, "Shift" }, "#" .. i + 9,
                    function()
                        if client.focus then
                            local tag = client.focus.screen.tags[i]
                            if tag then
                                client.focus:move_to_tag(tag)
                            end
                        end
                    end,
                    { description = "move focused client to tag #" .. i, group = "tag" }),
    -- Toggle tag on focused client.
            awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                    function()
                        if client.focus then
                            local tag = client.focus.screen.tags[i]
                            if tag then
                                client.focus:toggle_tag(tag)
                            end
                        end
                    end,
                    { description = "toggle focused client on tag #" .. i, group = "tag" })
    )
end

clientbuttons = gears.table.join(
        awful.button({ }, 1,
        function(c)
            c:emit_signal("request::activate", "mouse_click", { raise = true })
        end),
        awful.button({ "Mod1" }, 1,
        function(c)
            c:emit_signal("request::activate", "mouse_click", { raise = true })
            awful.mouse.client.move(c)
        end),
        awful.button({ "Mod1" }, 3,
        function(c)
            c:emit_signal("request::activate", "mouse_click", { raise = true })
            awful.mouse.client.resize(c)
        end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap + awful.placement.no_offscreen
      } },

    -- Floating clients.
    { rule_any = {
        instance = {
            "DTA", -- Firefox addon DownThemAll.
            "copyq", -- Includes session name in class.
            "pinentry",
        },
        class = {
            "Arandr",
            "Blueman-manager",
            "Gpick",
            "Kruler",
            "MessageWin", -- kalarm.
            "Sxiv",
            "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
            "Wpa_gui",
            "veromix",
            "xtightvncviewer",
            --"lxrandr",
        },

        -- Note that the name property shown in xprop might be set slightly after creation of the client
        -- and the name shown there might not match defined rules here.
        name = {
            "Event Tester", -- xev.
        },
        role = {
            "toolbox_windows",
            "AlarmWindow", -- Thunderbird's calendar.
            "ConfigManager", -- Thunderbird's about:config.
            "pop-up", -- e.g. Google Chrome's (detached) Developer Tools.
            "GtkFileChooserDialog",
        }
    }, properties = { floating = true },
      callback = function(c)
          c.maximized = false
          awful.placement.centered(c, nil)
      end
    },

    -- Add titlebars to normal clients and dialogs
    --{ rule_any = { type = { "normal", "dialog" } },
    --properties = { titlebars_enabled = true }
    --},

    --{ rule = { floating = true },
    --callback = function (c)
    --awful.placement.centered(c, nil)
    --c.ontop = true
    --end
    --},

    { rule = { class = "Chromium", role = "browser" },
      properties = { floating = false, tag = "3", maximized = false },
        -- Set maximized in callback. Avoid appear of border.
      callback = function(c)
          c.ontop = false
          c.maximized = true
      end
    },

    { rule = {}, properties = {},
      callback = function(c)
          if not c.maximized and c.floating then
              awful.placement.centered(c, nil)
          end

          --awful.spawn.with_shell(string.format("echo '%s ||| %s' >> ~/t.log", c.name, c.class))
          if string.match(c.name, "^Emulator") ~= nil
                  or string.match(c.name, "^Android Emulator.*") ~= nil then
              -- Android stidio emulator
              c.floating = true
              c.ontop = true
              c.border_width = 0
              c.add_signal("property::floating", function(c)
                  c.floating = true
              end)
          end
      end
    }

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup
            and not c.size_hints.user_position
            and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
            awful.button({ }, 1, function()
                c:emit_signal("request::activate", "titlebar", { raise = true })
                awful.mouse.client.move(c)
            end),
            awful.button({ }, 3, function()
                c:emit_signal("request::activate", "titlebar", { raise = true })
                awful.mouse.client.resize(c)
            end)
    )

    awful.titlebar(c):setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton(c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton(c),
            awful.titlebar.widget.ontopbutton(c),
            awful.titlebar.widget.closebutton(c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
--client.connect_signal("mouse::enter", function(c)
    --c:emit_signal("request::activate", "mouse_enter", { raise = false })
--end)

client.connect_signal("focus", function(c)
    c.border_color = beautiful.border_focus
end)
client.connect_signal("unfocus", function(c)
    c.border_color = beautiful.border_normal
end)
-- }}}

-- Auto run
do
    local cmds = {
        "fcitx",
        "nm-applet",
        "compton",
        "volumeicon",
        --"xmodmap ~/.Xmodmap",
        "xfce4-power-manager",
        -- "/home/kai/script/autofeh.py",
        "feh --bg-fill /home/kai/Photo/wallpaper.jpg",
        "/usr/lib/kdeconnectd",
        "xbindkeys"
    }

    for _, i in pairs(cmds) do
        -- run_once(i)
        awful.spawn.with_shell(i)
    end
end
