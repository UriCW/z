local setmetatable = setmetatable
local ipairs = ipairs
local pairs = pairs
local table=table
local z=z
local wibox=require("wibox")
local beautiful=require("beautiful")
local awful=require("awful")
local type=type
local tonumber=tonumber
module("z.it.tagset")
tagset={
    wibox_layout={},
    label="",
    widget_background=nil,
    textbox=nil,
    tag={},
    last_selected_tag=nil
}

function tagset.new(args,scr)
    local ret={
        tag={}
    }
    if not args then args={} end
    if not args.tag then
        args.tag={}
        args.tag[1]={
            label="t1"
        }
    end
    ret.wibox_layout = args.wibox_layout or wibox.layout.flex.horizontal()
    --ret.wibox_layout = args.wibox_layout or wibox.layout.fixed.horizontal()
    --ret.label=args.label or  "blah" -- "blah" should never happen, took care of this in screen 
    ret.label=args.label or  "blah" -- "blah" should never happen, took care of this in screen 
    ret.textbox=wibox.widget.textbox()
    ret.textbox:set_text(ret.label)
    ret.widget_background=wibox.widget.background() 
    ret.widget_background:set_widget(ret.textbox)
    ret.wibox_layout:add(ret.widget_background)
    for i, tag in pairs(args.tag) do

        if not tag.label then 
            if tag.awful_tag then 
                tag.label=tag.awful_tag.name
            else 
                tag.label="tag"..i 
            end
        end
        if not tag.id then tag.id=i end

        local t=z.it.tag(tag,scr)
        table.insert(ret.tag,t)
        ret.wibox_layout:add(t.widget_background)
        awful.tag.viewonly(t.awful_tag[scr])
    end
    ret.last_selected_tag=ret.tag[1] -- last selected starts as first tag, this is to avoid an unexplained error in screen.cycle({type='tagset'})
    setmetatable(ret,{__index=tagset})
    return ret
end
function tagset.repaint(me,args)
    if me:has_selected_tags() then me:selected({}) else me:deselected({}) end
    for i,tag in pairs(me.tag) do
        tag:paint(args)
    end
    me:calculate_geometry({})
end

function tagset.add_tag(me,args) 
    local scr=args.screen or 1
    if args.tag then 
        --This sort of breaks the "convention" of having an tagset["label"].tag["label"]
        table.insert(me.tag,args.tag)
        --me.tag[args.tag.label]=args.tag --This kicked out the last tag in tagset with the same label
        me.wibox_layout:add(args.tag.widget_background)
    else
        --Here we want to create a tag like in it.elements.add_tag
        return
    end
    me:repaint({screen=scr})
end

function tagset.has_selected_tags(me)
    for i,tag in pairs(me.tag) do
        for j,at in pairs(tag.awful_tag) do
            if at.selected then return true end
        end
    end
    return false
end
function tagset.get_selected_tags(me,args)
    local ret={}
    for i,t in pairs(me.tag) do
        for j,at in pairs(t.awful_tag) do
            if at.selected then 
                table.insert(ret,t) 
            end
        end
    end
    return ret
end


function tagset.selected(me,args)
   if not args then args={} end
    theme=beautiful.get()
    local fg_focus = theme.taglist_fg_focus or theme.fg_focus
    local bg_focus = theme.taglist_bg_focus or theme.bg_focus
   me.widget_background:set_bg(bg_focus) 
   me.widget_background:set_fg(fg_focus) 
end
function tagset.deselected(me,args)
   if not args then args={} end
   me.widget_background:set_bg(nil) 
   me.widget_background:set_fg(nil) 
end

function tagset.rename(me,args) 
    if not args.name then return end
    me.label=args.name
    me.textbox:set_text(me.label)
end

--Delete a tag if no @tag or @tags specified, will delete selected tags
--@args.tags - delete a list of tags
--@args.rescue_tag - a tag to send clients to
--@args.force_kill - if true will kill clients on tag if not given a @rescue_tag to move to
function tagset.delete_tag(me,args)
    if not args then args={} end
    local return_status=true
    local tags_to_delete = args.tags or me:get_selected_tags({})
    for i,my_tag in pairs(me.tag) do
        for j,arg_tag in pairs(tags_to_delete) do
            if my_tag==arg_tag and my_tag:delete({rescue_tag=args.rescue_tag,force_kill=args.force_kill})==true then
                for k,widget in pairs(me.wibox_layout.widgets) do 
                    if widget==my_tag.widget_background then 
                        table.remove(me.wibox_layout.widgets,tonumber(k))
                    end
                end
                me.tag[i]=nil
                table.remove(me.tag,tonumber(i))
                if me.last_selected_tag==arg_tag then me.last_selected_tag=nil end
            else
               --z.debug.msg("tagset.delete_tag gould not delete tag"..my_tag.label)
                return_status=false
            end
        end
    end 
    me:repaint({screen=1})
    return return_status
end
function tagset.delete(me,args)
    if not args then args={} end
    if #me.tag==0 or me:delete_tag({tags=me.tag, rescue_tag=args.rescue_tag, force_kill=args.force_kill})==true then
        --DO DELETY STUFF HERE
        return true
    else
        return false
    end
end

function tagset.cycle(me,args)
    if not args.direction or not args.screen then return end

    for i,tag in pairs(me.tag) do
        if tag.awful_tag[args.screen].selected then 
            local next_index=(i+args.direction)%#me.tag 
            if next_index==0 then next_index=#me.tag end
            local cycled_to=me.tag[next_index]
            awful.tag.viewonly(cycled_to.awful_tag[args.screen])
            return
        end
    end
end

--A helper function to calculate required geometry, needs serious improvement! (@TODO)
function tagset.calculate_geometry(me,args)
    local sum_width=0
    local max_height=0
    for i,tag in pairs(me.tag) do
        local w,h=tag.textbox:fit(-1,-1)
        sum_width=sum_width+w
        if max_height < h then max_height=h end
    end
    local w,h=me.textbox:fit(-1,-1)
    sum_width=sum_width+w
    if max_height < h then 
        max_height=h
    end
    return {width=sum_width,height=max_height}
end


function tagset.find(me,args)
    local ret={}
    for i,t in pairs(me.tag) do
        if args.tag.label==t.label then table.insert(ret,t) end
    end
    return ret
end
setmetatable(_M, { __call=function(_, ...) return tagset.new(...) end })
