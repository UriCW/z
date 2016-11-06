local setmetatable = setmetatable
local z=z
local ipairs=ipairs
local pairs=pairs
local table=table
local wibox=require("wibox")
local type=type
local math=math
local table=table
local tonumber=tonumber
local awful=require("awful")
module("z.it.screen")
screen={
    id=0,
    wibox={},
    tagset={},
    lpanel=nil,
}
function screen.new(args)
    local ret={}
    if not args then return end
    scr=args.screen or 1
    if not args.tagsets and not args.tagset then
        io.stderr:write(string.format("Requires one of tagsets or tagset as argument"))
        return
    end
    if args.tagsets and args.tagset then
        io.stderr:write(string.format("can't have both tagsets and tagset as argument, don't know which to use"))
        return
    end

    if args.tagset then
        ret=screen.construct_screen_from_tagset_argument(me,args)
    elseif tags.tagsets then
        --TODO
    end
    setmetatable(ret,{__index=screen})
    screen.repaint(ret)
    return ret
end

function screen.construct_screen_from_tagset_argument(me,args)
    ret={
        tagset={}
    }
    ret.id=args.screen or 1
    ret.lpanel = args.lpanel or z.lpanel({wibox_params={width=200}})
    --ret.lpanel:show()
    for i,ts in pairs(args.tagset) do
        if not ts.label then ts.label="ts"..i end
        local ts=z.it.tagset(ts,ret.id)
        ret.tagset[tonumber(i)]=ts
        ret.lpanel:append(ts.wibox_layout)
    end
    return ret
end

function screen.repaint(me)
    --TODO this is terrible, a disaster, a catastrophe... you get the idea, figure out how to resize this properly
    --Ideally, this will be done inside z.lpanel
    local scr=me.id
    local wb_width=0
    local wb_height=0
    for i,ts in pairs(me.tagset) do
        ts:repaint({screen=scr})
        geom=ts:calculate_geometry({})
        wb_height=wb_height+geom.height
        if (geom.width > wb_width) then --Try and find widest tagset 
            wb_width=geom.width
        end
    end
    me.lpanel.wibox:geometry({width=math.ceil(wb_width*2.1),height=wb_height})
end


--Add a tagset to screen
--@args.tagset - optional already constructed tagset option to attach to screen
--@args        - opitonal arguments to z.it.tagset.new(), will only use these if missing @args.tagset argument
function screen.add_tagset(me,args) 
    if not args then args={} end
    local ts=nil
    if args.tagset then --adds an existing tagset object to screen
        ts=args.tagset
    else --construct a new tagset from arguments, which are the same as the arguments for it.tagset.new
        ts=z.it.tagset(args,me.id)
    end
    table.insert(me.tagset,ts)
    me.lpanel:append(ts.wibox_layout)
    me:repaint()
end

--cycle through all tagsets and return a list of all tagsets with at least one selected tag
function screen.get_selected_tagsets(me,args) 
    local ret={}
    for i,ts in pairs(me.tagset) do 
        for j,t in pairs(ts.tag) do
            if t.awful_tag[me.id].selected then 
                table.insert(ret,ts)
                break
            end
        end
    end
    return ret
end
--Get a list of all selected tags on screen
function screen.get_selected_tags(me,args) 
    local ret={}
    for i,ts in pairs(me.tagset) do
        selected_tags=ts:get_selected_tags()
        for j,t in pairs(selected_tags) do table.insert(ret,t) end
    end
    return ret
end

--[[ DUPLICATE???
function screen.get_selected_tagsets(me,args)
    local ret={}
    for i,ts in pairs(me.tagset) do
        if ts:has_selected_tags() then table.insert(ret,ts) end
    end
    return ret
end
]]--
function screen.cycle(me,args)
    if not args then args={} end
    if not args.type then args.type="tagset" end
    if not args.direction then args.direction=1 end
    if not args.screen then args.screen=1 end
    if args.type=="tagset" then
        local next_tagset_index=0
        for i,ts in pairs(me.tagset) do
            if ts:has_selected_tags() then   
                next_tagset_index=i+args.direction
                next_tagset_index=next_tagset_index%#me.tagset
                if next_tagset_index==0 then next_tagset_index=#me.tagset end
                --if me.tagset[tonumber(i)].last_selected_tag==nil then --If no last selected, select first tag

                --[[
                if not me.tagset[tonumber(i)].last_selected_tag or me.tagset[tonumber(i)].last_selected_tag == nil then --If no last selected, select first tag
                    z.debug.msg("no last_selected_tag, view"..next_selected_index)
                    awful.tag.viewonly(me.tagset[tonumber(next_tagset_index)].tag[1].awful_tag[args.screen])
                else --Go back to last selected tag
                    z.debug.msg("next_selected_index"..next_tagset_index)
                    awful.tag.viewonly(me.tagset[tonumber(next_tagset_index)].last_selected_tag.awful_tag[args.screen])
                end
                ]]--
                if me.tagset[tonumber(next_tagset_index)].last_selected_tag == nil then --Just incase, sometimes deleting tags seems to screw this up
                    me.tagset[tonumber(next_tagset_index)].last_selected_tag=me.tagset[tonumber(next_tagset_index)].tag[1]
                end
                awful.tag.viewonly(me.tagset[tonumber(next_tagset_index)].last_selected_tag.awful_tag[args.screen] or me.tagset[tonumber(next_tagset_index)].tag[1].awful_tag[args.screen])
                return
            end
        end
    elseif args.type=="tag" then
    else
    end
end

--Delete a tag
--@args.tags - optional list of tag objects to delete, if not provided will delete all selected tags on screen
--If we deleted the last tag on a tagset, delete the tagset as well.
function screen.delete_tag(me,args)
    if not args then args={} end
    local tags_to_delete = args.tags or me:get_selected_tags({})
    for i,ts in pairs(me.tagset) do
        ts:delete_tag({tags=tags_to_delete,rescue_tag=args.rescue_tag,force_kill=args.force_kill})
        if #ts.tag==0 then 
            me:delete_tagset({tagsets={ts}, rescue_tag=args.rescue_tag,force_kill=args.force_kill }) 
        end
    end
    me:repaint()
end



--Delete a tagset
--@args.tagsets - optional list of tagset objects, if not provided will delete selected tagsets on screen
--If the last tagset is deleted, construct a new one and attach the remaining orphaned tag to it
function screen.delete_tagset(me,args)
    if not args then args={} end
    local tagsets_to_delete=args.tagsets or me:get_selected_tagsets({})
    for i,my_tagset in pairs(me.tagset) do
        for j,ts in pairs(tagsets_to_delete) do
            if ts==my_tagset and ts:delete({rescue_tag=args.rescue_tag,force_kill=args.force_kill})==true then
                --DO DELETY STUFF HERE
                table.remove(me.tagset,tonumber(i))
                me.lpanel:remove({widget=ts.wibox_layout})
            else
                z.debug.msg("Could not delete tagset")
            end
        end
    end

    --We just deleted the last tagset, get a new one
    if #me.tagset==0 then 
        --We deleted the tagset, but awsome won't delete last awesome tag, so it is "orphaned".
        --Use it to construct a new tagset
        local a_tag={}
        a_tag[me.id]=awful.tag.selected(me.id)
        local new_tag={
            id=1,
            label=a_tag[me.id].name,
            awful_tag=a_tag
        }
        local new_tagset={
            label="main",
            tag={new_tag}
        }
        me:add_tagset(new_tagset)
    end
end

setmetatable(_M, { __call=function(_, ...) return screen.new(...) end })
