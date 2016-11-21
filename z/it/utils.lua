--local it = require("z.it")
local z=z
local pairs=pairs
local type=type
local tonumber=tonumber
local naughty=require("naughty")
local awful=require("awful")
local client=client
module("z.it.utils")






--I need to rewrite this, and also define somewhere how i want this to behave,
--This will sometimes move client to all tags in args.tagset, sometimes just the 1st one,
--Is args.tagset an array of tagsets or one tagset. also elements.find and tagset.find need to be better defined
function move_client(c,elem,args)
--function z.it.utils.move_client(c,elem,args)
--    naughty.notify({text="moving client to".. args.tagset.label .. " to tag "..args.tagset.tag[1].label})
    
    local tagset=elem:find(args)
    if not tagset then --Tagset does not exist
        z.debug.msg("No existing tagset")
        if args.tagset and args.tagset.tag and args.tagset.label and args.tagset.tag[1].label then --No matching tagsets, create from fist args.tagset.tag
            z.debug.msg("Creating a new tagset")
            local new_tag=z.it.tag({label=args.tagset.tag[1].label,clients={c},rules=args.tagset.tag[1].rules},args.screen)
            args.tagset.tag=nil
            --Check if tagset.label exist but without tag.label, use it to add new_tag
            args.tagset.tag=nil
            local found_ts=elem:find(args)
            if found_ts then
                found_ts[1]:add_tag({tag=new_tag}) --Add tag to first tagset with label args.tagset.label
                elem:bind_tag_signals(elem.screen[args.screen],found_ts[1],new_tag)
            else --Not even a tagset with args.tagset.label, creating a brand new tagset
                --if found_ts then z.debug.msg("YES! Found a tagset name"..found_ts.label.." without required tag") end
                local new_ts= z.it.tagset({label=args.tagset.label,tag={new_tag}},args.screen)
                elem.screen[args.screen]:add_tagset({tagset=new_ts})
                elem:bind_tagset_signals(elem.screen[args.screen],new_ts)
                --local new_ts=z.it.tagset(args.tagset,args.screen)
            end
        end    
    else --Found tagset described in args.tagset
        z.debug.msg("Found existing tagset")
        local t=tagset[1]:find({tag=args.tagset.tag[1]})
        --for i,tag in pairs(tagset) do
        --    if tag.label=args.tagset.tag[1].label then
        --    end
        --end
        for i,client in pairs(args.clients) do
            --awful.client.movetotag(tagset[1].tag[1].awful_tag[args.screen])
            awful.client.movetotag(t[1].awful_tag[args.screen],client)
            awful.client.jumpto(client,true)
        end
        --toggle on rest
        for i,ts in pairs(tagset) do
            for j,tag in pairs(ts) do
                --tag.awful_tag[args.screen]
                for i,client in pairs(args.clients) do
                    --awful.client.toggletag(tag.awful_tag,client) -- <<--TODO This seem to be broken somehow??!
                    --awful.tag.withcurrent(c) -- << --STILL NO
                    --awful.client.toggletag(tag.awful_tag[args.screen],client) -- << --Still no!
                end
            end 
        end
    end
end


function create_new_tag_in_first_tagset(elem,args)
    z.debug.msg("creating...")
    if not elem or not args then return end
    if not args.tagset.label or not args.screen or not args.tagset.tag[1].label then return end

    local tagsets=elem:find({tagset={label=args.tagset.label},screen=args.screen})
    if tagsets then
        z.debug.msg("Found tagset:"..args.tagset.label)
        --local new_tag=z.it.tag({label=args.tagset.tag[1].label,clients=args.clients},args.screen)
        local new_tag=z.it.tag(args.tagset.tag[1],args.screen)
        tagsets[1]:add_tag({tag=new_tag})
        elem:bind_tag_signals(elem.screen[args.screen],tagsets[1],new_tag)
    else
        z.debug.msg("Creating tagset:"..args.tagset.label)
        z.debug.msg("Creating tag:"..args.tagset.tag[1].label)
        z.debug.msg("Creating tag, num clients:"..#args.tagset.tag[1].clients)
        local new_tag=z.it.tag(args.tagset.tag[1],args.screen)
        --local new_tag=z.it.tag({label=args.tagset.tag[1].label,clients={c}},args.screen)
        local new_ts=z.it.tagset({label=args.tagset.label,tag={new_tag}},args.screen)
        elem.screen[args.screen]:add_tagset({tagset=new_ts})
        elem:bind_tagset_signals(elem.screen[args.screen],new_ts)
    end
end

function move_to_tag_in_first_tagset(elem,args)
    z.debug.msg("moving...")
    if not elem or not args then return end
    if not args.tagset.label or not args.screen or not args.tagset.tag[1].label then return end

    local tagsets=elem:find({args})
   if tagsets then
        z.debug.msg("Found tagset:"..args.tagset.label)
        local at=tagsets[1].tag[1].awful_tag[args.screen]
        for i,client in pairs(args.clients) do
            z.debug.msg("adding client (type)"..type(client))
            move_client(client,elem,args)
            return
            --awful.client.movetotag(at,client)
        end
    else
        z.debug.msg("Creating tagset:"..args.tagset.label)
        local new_ts=z.it.tagset(args.tagset,args.screen)
        elem.screen[args.screen]:add_tagset({tagset=new_ts})
        elem:bind_tagset_signals(elem.screen[args.screen],new_ts)
        return
    end
 
end

--[[TODO
Not sure, need to think about this...
template={ tagset={tag={ {clients={"command1","command2","command3"}, default_client_layout={},nmasters,setmwfact,setfloating,setmarked,setontop... },

]]--
function create_tagset_from_template(elem,args)
    for ts in pairs(args.template.tagset) do 

        
    end 
end


--[[
TODO
How do i do this? get all clients and register signals? which signal do i register to get "client killed"?
I can awful.rules.rules=awful.rules.rules+{...} ??
What's the unmanage signal for?
]]--
function delete_when_empty(elem,tag)
    tag.rules.delete_when_empty=true
end


function pop(elem)
    for i,scr in pairs(elem.screen) do
        scr.lpanel:pop({})
    end
end
function toggle(elem)
    for i,scr in pairs(elem.screen) do
        scr.lpanel:toggle({})
    end
end


function get_client_by_pid(pid, scr) 
    local clients=client.get(scr)    
    z.debug.msg("Number of clients:"..#clients)
    for i,c in pairs(clients) do
        --z.debug.msg("Will move pid"..tonumber(c.pid).."-"..pid)
        if pid==c.pid then
            z.debug.msg("Found the right pid for "..pid)
            return c
        else
            z.debug.msg("No process "..pid.."found in clients")
        end
    end
    return nil
end


--[[Swap two tags in tagset ]]--
function swap_tags(ts,idx_a,idx_b)
    local tag_a=ts.tag[idx_a]
    local tag_b=ts.tag[idx_b]
    ts.tag[idx_a]=tag_b
    ts.tag[idx_b]=tag_a
    for i=1,#ts.wibox_layout.widgets do
        local cur_widget=ts.wibox_layout.widgets[i]
        if cur_widget==tag_a.widget_background then 
            z.debug.msg("Found tag a at index:"..i)
            ts.wibox_layout.widgets[i]=tag_b.widget_background
        elseif cur_widget==tag_b.widget_background then
            z.debug.msg("Found tag b at index:"..i)
            ts.wibox_layout.widgets[i]=tag_a.widget_background
        end
    end
end
function copy()
    ret=""
end

function paste_next()
    ret=""
end

function move_tag(elem,args)
    local scr=args.screen or 1
    local selected_ts=elem.screen[scr]:get_selected_tagsets({})[1]
    local selected_tag=selected_ts:get_selected_tags({})[1]
    if args.direction=="left" or args.direction=="right" then
       for i=1,#selected_ts.tag do
            if selected_tag == selected_ts.tag[i] then
                if args.direction=="left" and i==1 then return end
                if args.direction=="right" and i==#selected_ts.tag then return end
                if args.direction=="left" then 
                    swap_tags(selected_ts,i,i-1)
                    elem:repaint()
                    pop(elem)
                    return
                elseif args.direction=="right" then
                    swap_tags(selected_ts,i,i+1)
                    elem:repaint()
                    pop(elem)
                    return
                end
            end
       end 
    elseif args.direction=="up" or args.direction=="down" then
    end
    pop(elem)
end
--[[
Run or Raise a client
]]--
function ror(instance)
    local clients = client.get()
    for i, c in pairs(clients) do
        if(c.instance==instance) then
            local curtag = awful.tag.selected()
            awful.client.movetotag(curtag, c)
            c:raise()
            c.ontop=true
            client.focus = c
            return
        end
    end
    awful.util.spawn(instance)
end
