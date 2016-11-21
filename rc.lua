-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local remote = require("awful.remote")
-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end
local z = require("z")
z.debug.enabled=true
-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init("/usr/local/share/awesome/themes/default/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "urxvt"
editor = os.getenv("EDITOR") or "vi"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
local it = z.it.elements({})
for s = 1, screen.count() do
    local scr={
        id=s,
        tagset={
            [1]={
                 label='sys',
                 tag={
                    [1]={
                        label='init'
                    }
                }
            }
        }
    }
    it:add_screen(scr)    
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock()

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({
                                                      theme = { width = 250 }
                                                  })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(mytextclock)
    right_layout:add(mylayoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",
        function()
            it.screen[mouse.screen].lpanel:pop({timeout=1})
            it:cycle({type="tag", direction=-1,screen=mouse.screen})
        end       
    ),
    awful.key({ modkey,           }, "Right",  
        function()
            it.screen[mouse.screen].lpanel:pop({timeout=1})
            it:cycle({type="tag", direction=1,screen=mouse.screen})
        end
    ),
    awful.key({ modkey,           }, "Up",
        function()
            it.screen[mouse.screen].lpanel:pop({timeout=1})
            it:cycle({type="tagset", direction=-1,screen=mouse.screen})
        end
    ),
    awful.key({ modkey,           }, "Down",
        function()
            it.screen[mouse.screen].lpanel:pop({timeout=1})
            it:cycle({type="tagset", direction=1,screen=mouse.screen})
        end
    ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end),

    --Tagging
    awful.key({ modkey }, "F2", function() 
        z.it.utils.toggle(it)
    end),
    awful.key({ modkey, "Control"  }, "Left", function() 
        z.it.utils.move_tag(it,{screen=mouse.screen,direction="left"})
    end),
    awful.key({ modkey, "Control"  }, "Right", function() 
        z.it.utils.move_tag(it,{screen=mouse.screen,direction="right"})
    end),
    awful.key({ modkey }, "t", function() 
        it:add_tag({})
        it.screen[mouse.screen].lpanel:pop({})
    end),
    awful.key({ modkey , "Shift" }, "t", function() 
        it:add_tagset({})
        it.screen[mouse.screen].lpanel:pop({})
    end ),
    awful.key({ modkey ,  },"BackSpace" , function() 
        --it:rename_tagset({})
        it.screen[mouse.screen].lpanel:show()
        it:rename_tag({})
    end ),
    awful.key({ modkey , "Shift"}, "BackSpace", function() 
        it.screen[mouse.screen].lpanel:show()
        it:rename_tagset({})
    end ),
    awful.key({ modkey , "Mod1" }, "t", function() 
        it.screen[mouse.screen].lpanel:pop()
        it:delete_tag({})
    end ),
    awful.key({ modkey ,}, "d", function() 
        it:dump()
    end ),
    --[[Volume ]]--
    awful.key({ },"XF86AudioRaiseVolume" , function() 
        naughty.notify({text="Vol up"})
    end),
    awful.key({ },"XF86AudioLowerVolume" , function() 
        naughty.notify({text="Vol down"})
    end),
    --[[ Network monitor ]]--
    awful.key({ modkey,       },"z",function() z.network.connections.toggle() end )
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Mod1"    }, "space",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.toggletag(tag)
                          end
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

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
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    { rule = { class = "Xombrero"},
      callback = function(c) 
        local ts={label="web",tag={ {label="tor",clients={c},rules={delete_when_empty=true}} } }
        z.it.utils.create_new_tag_in_first_tagset(it,{tagset=ts,screen=mouse.screen})                            
        z.it.utils.pop(it)
      end }, 
    { rule_any = { class = {"Firefox"} },except={name="Downloads"},
      callback = function(c) 
        local ts={label="web",tag={ {label="www",clients={c},rules={delete_when_empty=true}} } }
        z.it.utils.create_new_tag_in_first_tagset(it,{tagset=ts,screen=mouse.screen})                            
        z.it.utils.pop(it)
      end }, 
    { rule_any = { class = {"chromium-browser"} },except={name="Downloads"},
      callback = function(c) 
        local ts={label="web",tag={ {label="www",clients={c},rules={delete_when_empty=true}} } }
        z.it.utils.create_new_tag_in_first_tagset(it,{tagset=ts,screen=mouse.screen})                            
        z.it.utils.pop(it)
      end }, 
--[[ Net stuff ]]--
    { rule = { class = "Icedove"},
      callback = function(c) 
        naughty.notify({text='Icedove'})
        local ts={label="net",tag={ {label="mail",clients={c},rules={delete_when_empty=true}} } }
        z.it.utils.move_client(c,it, {tagset=ts,screen=mouse.screen,clients={c}})
        z.it.utils.pop(it)
      end }, 
    { rule = { class = "Pidgin"},
      callback = function(c) 
        local ts={label="net",tag={ {label="chat",clients={c},rules={delete_when_empty=true}} } }
        z.it.utils.move_client(c,it, {tagset=ts,screen=mouse.screen,clients={c}})
        z.it.utils.pop(it)
      end }, 
--[[ Sysadmin stuff ]]--
    { rule = { class = "Wireshark"},
      callback = function(c) 
        local ts={label="netsec",tag={ {label="capture",clients={c},rules={delete_when_empty=true}} } }
        z.it.utils.move_client(c,it, {tagset=ts,screen=mouse.screen,clients={c}})
        z.it.utils.pop(it)
      end }, 
    { rule = { name = "tmux_ifaces"},
      callback = function(c) 
        local ts={label="netsec",tag={ {label="interfaces",clients={c},rules={delete_when_empty=true}} } }
        z.it.utils.move_client(c,it, {tagset=ts,screen=mouse.screen,clients={c}})
        z.it.utils.pop(it)
      end }, 
    { rule = { name = "tmux_net_logs"},
      callback = function(c) 
        local ts={label="netsec",tag={ {label="logs",clients={c},rules={delete_when_empty=true}} } }
        z.it.utils.move_client(c,it, {tagset=ts,screen=mouse.screen,clients={c}})
        z.it.utils.pop(it)
      end }, 
    { rule = { class = "Amarok"},
      callback = function(c) 
        local ts={label="media",tag={ {label="music",clients={c},rules={delete_when_empty=true}} } }
        z.it.utils.move_client(c,it, {tagset=ts,screen=mouse.screen,clients={c}})
        z.it.utils.pop(it)
      end }, 
    { rule = { class = "Transmission-gtk"},
      callback = function(c) 
        --naughty.notify({text='Icedove'})
        local ts={label="net",tag={ {label="p2p",clients={c},rules={delete_when_empty=true}} } }
        z.it.utils.move_client(c,it, {tagset=ts,screen=mouse.screen,clients={c}})
        z.it.utils.pop(it)
      end }, 
    { rule = { class = "Deluge"},
      callback = function(c) 
        --naughty.notify({text='Icedove'})
        local ts={label="net",tag={ {label="p2p - deluge",clients={c},rules={delete_when_empty=true}} } }
        z.it.utils.move_client(c,it, {tagset=ts,screen=mouse.screen,clients={c}})
        z.it.utils.pop(it)
      end }, 
    { rule = { class = "Wicd-client.py"},
      callback = function(c) 
        --naughty.notify({text='Icedove'})
        local ts={label="sys",tag={ {label="wicd",clients={c},rules={delete_when_empty=true}} } }
        z.it.utils.move_client(c,it, {tagset=ts,screen=mouse.screen,clients={c}})
        z.it.utils.pop(it)
      end }, 
    { rule = { class = "Xchat"},
      callback = function(c) 
        --naughty.notify({text='Icedove'})
        local ts={label="net",tag={ {label="xchat",clients={c},rules={delete_when_empty=true}} } }
        z.it.utils.move_client(c,it, {tagset=ts,screen=mouse.screen,clients={c}})
        z.it.utils.pop(it)
      end }, 
    { rule = { name = ".*TorChat*."},
      callback = function(c) 
        --naughty.notify({text='Icedove'})
        local ts={label="net",tag={ {label="chat",clients={c},rules={delete_when_empty=true}} } }
        z.it.utils.move_client(c,it, {tagset=ts,screen=mouse.screen,clients={c}})
        z.it.utils.pop(it)
      end }, 
--[[Awesome development environment rules ]]--
    { rule = { class = "Xephyr"},
      callback = function(c) 
        local ts={label="awesome-dev",tag={ {label="run",clients={c}} } }
        z.it.utils.move_client(c,it, {tagset=ts,screen=mouse.screen,clients={c}})
        z.it.utils.pop(it)
      end }, 
    { rule = { name = "awesome_test"},
      callback = function(c) 
        local ts={label="awesome-dev",tag={ {label="run",clients={c}} } }
        z.it.utils.move_client(c,it, {tagset=ts,screen=mouse.screen,clients={c}})
        z.it.utils.pop(it)
      end }, 
    { rule = { class = "awesome_test"},
      callback = function(c) 
        local ts={label="awesome-dev",tag={ {label="run",clients={c}} } }
        z.it.utils.move_client(c,it, {tagset=ts,screen=mouse.screen,clients={c}})
        z.it.utils.pop(it)
      end }, 
    { rule = { name = "tmux_env.sh"},
      callback = function(c) 
        naughty.notify({text="got awesome_tmux class"})
        local ts={label="awesome-dev",tag={ {label="tmux",clients={c}} } }
        z.it.utils.move_client(c,it, {tagset=ts,screen=mouse.screen,clients={c}})
        z.it.utils.pop(it)
      end }, 
    { rule = { class = "Eclipse"},
      callback = function(c) 
        local ts={label="android-dev",tag={ {label="eclipse",clients={c},rules={delete_when_empty=true}} } }
        z.it.utils.move_client(c,it, {tagset=ts,screen=mouse.screen,clients={c}})
        z.it.utils.pop(it)
      end }, 
    { rule = { class = "jetbrains-android-studio"},
      callback = function(c) 
        local ts={label="android-dev",tag={ {label="studio",clients={c},rules={delete_when_empty=true}} } }
        z.it.utils.move_client(c,it, {tagset=ts,screen=mouse.screen,clients={c}})
        z.it.utils.pop(it)
      end }, 
    { rule = { class = "Eclipse", name = "Debug - *"},
      callback = function(c) 
        naughty.notify({text="****** ECLIPSE Debug"})
        local ts={label="android-dev",tag={ {label="debug",clients={c},rules={delete_when_empty=true}} } }
        z.it.utils.move_client(c,it, {tagset=ts,screen=mouse.screen,clients={c}})
        z.it.utils.pop(it)
      end }, 
    { rule = { class = "emulator64-arm"},
      callback = function(c) 
        local ts={label="android-dev",tag={ {label="emulator",clients={c},rules={delete_when_empty=true}} } }
        z.it.utils.move_client(c,it, {tagset=ts,screen=mouse.screen,clients={c}})
        z.it.utils.pop(it)
      end }, 
    { rule = {  name = ".*term*."},
      callback = function(c) 
        naughty.notify({text="all term"})
      end }, 

}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
client.connect_signal("unmanage", function(c) it:client_killed(c,{}) end)
-- }}}

function add_tag(args)
        it:add_tag(args)
        it.screen[mouse.screen].lpanel:pop({})
end

function add_tagset(args)
        it:add_tagset(args)
        it.screen[mouse.screen].lpanel:pop({})
end

function test1() 
    it.screen[1]:add_tagset({})
    z.debug.msg("test1")
end
function test_presets() 
    t={
        label='cmd',
        commands={'urxvt -name cmd_name'}
    }
    ts={
        label='cmd_ts',
        tag=t
    }
    it:add_tagset({
        label='hi',
        tag={
            [0]={
                label='tag1',
                commands={'urxvt -name name1'}
            },
            [1]={
                label='doc',
                commands={'surf http://www.google.com'}
            }
        }
    })
end
--test_presets()

function test_spawn()
    --local spn = require("awful"):spawn()
    --local spn = awful.spawn:spawn("cmd",false,{})
    
    z.debug.msg("Test Spawn : "..type(spn))
    
    --spawn.spawn("urxvt -name blah",{},{})
    --awful.spawn.spawn("urxvt -name blah",{},{})
end
--test_spawn()
