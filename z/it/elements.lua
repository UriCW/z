local z=z
local ipairs=ipairs
local pairs=pairs
local setmetatable = setmetatable
local type=type
local tonumber=tonumber
local table=table
local beautiful=require("beautiful")
local awful=require("awful")
module("z.it.elements")
elements={
    screen={},
}
function elements.new(args)
    local ret={}
    ret.screen={}
    if not args.screen then args.screen={} end
    for i,scr in ipairs(args.screen) do
        ret.screen[i]=elements.add_screen(ret,scr)
        ret.screen[i]:repaint()
    end
    setmetatable(ret,{__index=elements})
    return ret
end
function elements.add_screen(me,args)
    ret=z.it.screen(args)
    table.insert(me.screen,ret)
    elements.bind_signals(me,ret)
    return ret
end

--[[
Binds all signals on screen
@scr - screen object
]]--
function elements.bind_signals(me,scr)
    for i,ts in pairs(scr.tagset) do
        for j,t in pairs(ts.tag) do
            elements.bind_tag_signals(me,scr,ts,t,{})
        end
    end
end

--[[
binds signals for tag
@scr - it.elenments.screen object
@ts  - it.elements.screen.tagset object
]]--
function elements.bind_tagset_signals(me,scr,ts)
    for j,t in pairs(ts.tag) do
        elements.bind_tag_signals(me,scr,ts,t,{})
    end
end

--[[
binds signals for tag
@scr - it.elenments.screen object
@ts  - it.elements.screen.tagset object
@t   - it.elements.screen.tagset.tag object. the tag to bind
]]--
function elements.bind_tag_signals(me,scr,ts,t,args)
    t.awful_tag[scr.id]:connect_signal("property::selected", function()
        ts.last_selected_tag=t
        ts:repaint({screen=scr.id})
    end)
end
function elements.repaint(me)
    for i,scr in pairs(me.screen) do
        scr:repaint()
    end
end
function elements.add_tag(me,args) 
    local new_tag={}
    local scr=args.screen or 1
    local tag={}
    local tagset={}
    if args.tag then --Pass a z.it.tag object
        tag=args.tag 
    else -- or parameters to create z.it.tag object
        local new_tag={}
        new_tag.label=args.id or -1
        new_tag.label=args.label or "new_tag"
        new_tag.rules=args.rules or {}
        new_tag.widget_background=args.widget_background or nil
        new_tag.icon=args.icon or nic
        new_tag.buttons=args.buttons or nil
        new_tag.awful_tag = args.awful_tag or nil
        new_tag.default_client_layout=args.default_client_layout or nil
        tag=z.it.tag(new_tag)
    end
    if args.tagset then -- We add tag to one tagset
        args.tagset:add_tag({tag=tag,screen=scr})
        me:bind_tag_signals(me.screen[scr],args.tagset,tag)
    elseif args.tagsets then --we add tag to a list of tagsets
        for i,ts in pairs(args.tagsets) do
            ts:add_tag({tag=tag,screen=scr})
            me:bind_tag_signals(me.screen[scr],ts,tag)
        end
    else --we add tag to all selected tagsets on screen
        selected_tagsets=me.screen[scr]:get_selected_tagsets({})
        for i,ts in pairs(selected_tagsets) do
            ts:add_tag({tag=tag,screen=scr})
            me:bind_tag_signals(me.screen[scr],ts,tag)
        end
    end
    awful.tag.viewonly(tag.awful_tag[scr])
    me.screen[scr]:repaint({screen=scr})
end
function elements.add_tagset(me,args) 
    if not args then args={} end
    local scr=args.screen or 1
    local ts=z.it.tagset(args,scr)
    me.screen[scr]:add_tagset({tagset=ts})
    me:bind_tagset_signals(me.screen[scr],ts)
    me.screen[scr]:repaint({screen=scr})
end
function elements.rename_tag(me,args) 
    if not args then args={} end
    for i,s in pairs(me.screen) do
        s.lpanel:show()
    end


    if args.screen then --Only rename tags on screen args.screen @TODO
    elseif args.tagsets then --only rename tags in tagsets args.tagsets TODO
    elseif args.tags then --only rename tags in args.tags TODO
    else --Rename all selected tags
        local selected_tags={}
        for i,scr in pairs(me.screen) do 
            local sel=scr:get_selected_tags({})
            for j,t in pairs(sel) do
                table.insert(selected_tags,t)
            end
        end
        local prompt_box=awful.widget.prompt()
        for i,t in pairs(selected_tags) do 
            t.widget_background:set_widget(prompt_box)
        end
        awful.prompt.run(
            {prompt='name:'},
            prompt_box.widget,
            function(name)
                for i,t in pairs(selected_tags) do
                    t:rename({name=name})
                    t.widget_background:set_widget(t.textbox)
                end
                me:repaint()
                for i,s in pairs(me.screen) do
                    s.lpanel:hide()
                    s.lpanel:pop({timeout=2})
                end
            end,
            nil,
            nil
        )
    end
end
function elements.rename_tagset(me,args) 
    if not args then args={} end
    if args.screen then
        --@TODO only rename tagsets on screen num args.screen
    elseif args.tagsets then 
        --@TODO only rename tagsets args.tagsets
    else --@Rename all selected tagsets on all screens
        local selected_tagsets={}
        for i,scr in pairs(me.screen) do
            table.insert(selected_tagsets,scr:get_selected_tagsets({}))
        end
        local prompt_box=awful.widget.prompt()
        for i,ts in pairs(selected_tagsets) do
            ts[i].widget_background:set_widget(prompt_box)
        end
        awful.prompt.run(
            {prompt='name:'},
            prompt_box.widget,
            function(name) 
                for i,ts in pairs(selected_tagsets) do
                    ts[i]:rename({name=name})
                    ts[i].widget_background:set_widget(ts[i].textbox)
                end
                me:repaint()
                for i,s in pairs(me.screen) do
                    s.lpanel:hide()
                    s.lpanel:pop({timeout=2})
                end
            end,
            nil,
            nil
        )
    end
end
--[[
Delete a tag
@screens a list of screen numbers {1,2,3...}
@tagsets a list of tagset object
]]--
function elements.delete_tag(me,args) 
    if not args then args={} end
    for i,screen in pairs(me.screen) do
        local tags_to_delete=args.tags or screen:get_selected_tags({})
        screen:delete_tag({tags=tags_to_delete})
    end
end
--TODO
function elements.delete_tagset(me,args) end

function elements.cycle(me,args)
    if not args.type or not args.direction or not args.screen then return end

    if args.type=="tag" then 
        local selected_tagsets=me.screen[args.screen]:get_selected_tagsets({})
        for j,ts in pairs(selected_tagsets) do
            ts:cycle({direction=args.direction,screen=args.screen})
        end
    elseif args.type == "tagset" then
        me.screen[args.screen]:cycle({type=args.type,direction=args.direction,screen=args.screen})
    end
end

function elements.find(me,args)
    --z.debug.msg("Find, tagset.label:"..args.tagset.label.." tagset.tag[1].label:"..args.tagset.tag[1].label)
    if not args then return end
    if not args.screen then return end
    local ret={}
    if args.tagset then
        for i,ts in pairs(me.screen[args.screen].tagset) do 
            if args.tagset.label and ts.label==args.tagset.label then --Found a tagset with right label
                if not args.tagset.tag then --No tags to check
                    z.debug.msg("No tags queries for, returning tagset")
                    table.insert(ret,ts) 
                    --next i;
                else--TODO Check that tag label is also the same as args
                   -- for a,args.tagset
                    for a,atag in pairs(args.tagset.tag) do
                        for b,tag in pairs(ts.tag) do
                            if atag.label==tag.label then 
                                table.insert(ret,ts) 
                                z.debug.msg("***Found tag with label")
                            end
                        end
                    end
                end
                --for j,tag in pairs(ts.tag) do
                --end
                --table.insert(ret,ts)
            end
        end
    end
    if #ret > 0 then return ret else return end
end
function elements.client_killed(me,client,args)
    z.debug.msg("Client killed")    
    for i,scr in pairs(me.screen) do
        for j,ts in pairs(scr.tagset) do
            for k,t in pairs(ts.tag) do
                if t.rules.delete_when_empty and t.rules.delete_when_empty==true then
                    z.debug.msg("Got 'delete_when_empty' set")    
                    local num_clients=0
                    for l,at in pairs(t.awful_tag) do
                        z.debug.msg("Num clients"..#at:clients())
                        num_clients=num_clients+#at:clients()
                    end
                    if num_clients==0 then me:delete_tag({tags={t}}) end
                end
            end
        end
    end
end

setmetatable(_M, { __call=function(_, ...) return elements.new(...) end })
