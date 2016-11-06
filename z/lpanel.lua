--------------------------------------
--@author Yussi Divnal
--------------------------------------
--[[[ 
    A Panel like implementation for stacked layouts
]]

local setmetatable=setmetatable
local table=table
local pairs=pairs
local tonumber=tonumber
require("z.utils")
--local utilz=require("z.utils")
local z=z
local wibox=require("wibox")
local timer=timer
local naughty=require("naughty")
module("z.lpanel")
lpanel={}

function printsomthing(args)
    print("Hi")
    end

function lpanel.new(args)
    local ret={
        pop_on=false
    }
    if(args==nil)then args={} end
	ret.wb_params = args.wibox_params or {}
	ret.wibox=z.utils.new_wibox(ret.wb_params)
    --ret.root_layout = args.root_layout or wibox.layout.margin.vertical()
    ret.root_layout = args.root_layout or wibox.layout.align.vertical()
    ret.payload_layout=args.payload_layout or wibox.layout.fixed.vertical()
    ret.num_rows=args.rows or 15
    ret.root_layout:set_middle(ret.payload_layout)
    --ret.root_layout:add(ret.payload_layout)
    ret.wibox:set_widget(ret.root_layout)
    ret.payload={}
    setmetatable(ret,{__index=lpanel})
    return ret
end

---Shows panel
function lpanel.show(me) 
    if me.pop_timer then me.pop_timer:stop() end
    me.wibox.visible=true 
end
---Hides lpanel
function lpanel.hide(me) me.wibox.visible=false end
---Toggle lpanel's visibility
function lpanel.toggle(me) 
    if me.pop_timer then me.pop_timer:stop() end
    me.wibox.visible=not me.wibox.visible 
end
--is visible
function lpanel.visible(me) return me.wibox.visible end

function lpanel.pop(me,args)
    local args=args or {}
    local timeout=args.timeout or 5
    if me:visible()==true and me.pop_on==false then return end
    me:show()
    me.pop_on=true
    if me.pop_timer then me.pop_timer:stop() end
    me.pop_timer=timer({timeout=timeout})
    me.pop_timer:connect_signal("timeout",function()
        me:hide()
        me.pop_on=false
    end)
    me.pop_timer:start()
end


--Appends lout to payload_layout, lout can be either a layout or a widget
function lpanel.append(me,lout,args)
    --local secondary_layout=wibox.layout.fixed.horizontal()
    --secondary_layout:add(lout)
    --me.root_layout:set_middle(secondary_layout)
    me.payload_layout:add(lout)
end

--@TODO
--Untested, no idea if this works 
function lpanel.set(me,louts,args)
    me.lpanel:remove({remove_all=true})
    for i,lout in pairs(louts) do
        me:append(lout,{})
    end
end


--Removes a widget (or a nested layout)
--Currently only removes from payload_layout
--@args.widget object to remove widget or layout
function lpanel.remove(me,args)
    if not args then return false end
    if args.widget then
        for i,widget in pairs(me.payload_layout.widgets) do 
            if widget==args.widget then
                table.remove(me.payload_layout.widgets,tonumber(i))
                return true
            end
        end
    elseif args.remove_all==true then
        for i,widget in pairs(me.payload_layout.widgets) do
                table.remove(me.payload_layout.widgets,tonumber(i))
        end
    end
    return false
end

--NOT WORKING!
function lpanel.autosize(me)
    local w,h = me.root_layout:fit(-1,-1)
    naughty.notify({text="######width="..w.." height="..h})
    me.wibox:geometry({width=w,height=h})    
end

setmetatable(_M, { __call=function(_, ...) return lpanel.new(...) end })

