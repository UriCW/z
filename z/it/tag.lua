
local setmetatable = setmetatable
local pairs=pairs
local type=type
local table=table
local z=z
local wibox=require("wibox")
local awful=require("awful")
local beautiful = require("beautiful")
module("z.it.tag")
tag={
    id=1,
    label="",
    rules=nil,
    widget_background=nil,
    textbox=nil,
    icon=nil,
    buttons=nil,
    awful_tag=nil,
    default_client_layout=nil
}

--[[
Construct a new tag from arguments
@args.id - optional number, defaults to -1
@args.label - optional string defaults to "blah"
@args.rules - optional table (Not implemented yet)
@args.textbox - optional wibox.widget.textbox
@args.icon    - optional icon (Not implemented yet)
@args.default_client_layout - optional awful.layout, defaults to awful.layout.suit.floating
@args.awful_tag - optional awful.tag, defaults to creating a new tag "label" on screen @scr
@args.buttons - optional table of awful.button()
@args.clients - optional table of clients to move to the tag
]]--
function tag.new(args,scr)
    local ret={}
    if not scr then scr=1 end
    ret.id=args.id or -1
    ret.label=args.label or "blah"
    ret.rules=args.rules or {}
    ret.textbox=args.textbox or wibox.widget.textbox()
    ret.textbox:set_text(ret.label) --Should probably check args.textbox doesn't already have text
    ret.widget_background=wibox.widget.background()
    ret.widget_background:set_widget(ret.textbox)
    ret.icon=args.icon or nil

    ret.default_client_layout=args.default_client_layout or awful.layout.suit.floating
    ret.awful_tag=args.awful_tag or awful.tag({ret.label},scr,ret.default_client_layout)
    --If we are reusing an existing awful tag, but using a different label, rename it to args.label
--    if args.awful_tag and args.label then 
--        ret.awful_tag.name=ret.label
--    end

    ret.buttons=args.buttons or tag.get_default_buttons(ret.awful_tag,scr)
    ret.textbox:buttons(ret.buttons) --Should probably check args.textbox doesn't already have buttons and maybe append to it
    ret.textbox:set_align("center")

    if args.clients then
        for i,client in pairs(args.clients) do
            z.debug.msg("Moving client"..i)
            awful.client.movetotag(ret.awful_tag[scr],client)
        end
    end

    setmetatable(ret,{__index=tag})
    --if args.commands, uses a "hack", make tag, viewonly and awful.util.spawn
    if args.commands then
        --z.debug.msg("Commands...")
        awful.tag.viewonly(ret.awful_tag[scr])
        for i,c in pairs(args.commands) do
            --z.debug.msg("Spawn..."..c)
            local pid=awful.util.spawn(c,true,scr)    
            --z.debug.msg(pid.." "..c)
            local cli=z.it.utils.get_client_by_pid(pid,scr)
            if not cli then z.debug.msg("No Cli"); end
            --z.it.utils.move_client(cli,z.it.element,{})
        end
    end

    --setmetatable(ret,{__index=tag})

    --awful.tag.viewonly(ret.awful_tag[scr])
    --ret.awful_tag[scr]:emit_signal("property::selected")
    --tag.paint(ret,{screen=scr})
    return ret
end
--[[
    In the future, i want to be able to pass the taglist.buttons to this, but this requires implementing
    the rather complicated and obsecure code in awful.widget.taglist and awful.widget.commn (update_list/update_function)
]]--
function tag.get_default_buttons(t,s)
    ret=awful.util.table.join(
        awful.button({},1, function() awful.tag.viewonly(t[s]) end)
    )
    return ret
end

function tag.paint(me,args)
    local theme=beautiful.get() 
    local fg_focus = args.fg_focus or theme.taglist_fg_focus or theme.fg_focus
    local bg_focus = args.bg_focus or theme.taglist_bg_focus or theme.bg_focus
    local fg_urgent = args.fg_urgent or theme.taglist_fg_urgent or theme.fg_urgent
    local bg_urgent = args.bg_urgent or theme.taglist_bg_urgent or theme.bg_urgent
    if me.awful_tag[args.screen].selected then 
        me.widget_background:set_bg(bg_focus)
        me.widget_background:set_fg(fg_focus)
    else
        me.widget_background:set_bg(nil)
        me.widget_background:set_fg(nil)
    end
    me.textbox:set_text(me.label)
end

function tag.rename(me,args)
    if not args.name then return end
    me.label=args.name
    me.textbox:set_text(args.name)
    if args.screen then
        me.awful_tag[args.screen].name=args.name
    else
        for i,at in pairs(me.awful_tag) do
            at.name=args.name
        end
    end
end


--[[
@args.screen screen number
@args.rescue_tag - an opitonal tag to move clients to
@args.force_kill - if set to true and no rescue_tag then kill the clients on tag.

returns true on success, false on failure
]]--
function tag.delete(me,args)
    if not args then args={} end
    local screen=args.screen
    local clients=me:get_clients({screen=screen})
    if #clients==0 then --No client, we can delete the tag
        --DO DELETY STUFF HERE
        for i,at in pairs(me.awful_tag) do
            awful.tag.delete(at)
        end
        me.background_widget=nil
        me.textbox=nil
        me=nil --Is this allowed?
        return true;
    else
        for i,client in pairs(clients) do
            --TODO Check if client is already on another tag
            if args.rescue_tag then 
                awful.client.movetotag(args.rescue_tag,client)
                --DO DELETY STUFF HERE
                return true
            elseif args.force_kill==true then
                client:kill()
                --DO DELETY STUFF HERE
                return true
            else
                return false    
            end
        end
    end
end

function tag.get_clients(me,args)
    if not args then args={} end
    if args.screen then 
        return me.awful_tag[args.screen]:clients()
    end
    local ret={}
    for i,aw in pairs(me.awful_tag) do
        local clients=aw:clients()
        for j,c in pairs(clients) do
            table.insert(ret,c)
        end
    end
    return ret
end
setmetatable(_M, { __call=function(_, ...) return tag.new(...) end })
