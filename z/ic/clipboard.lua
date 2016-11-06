local setmetatable = setmetatable
local naughty=require("naughty")
local wibox=require("wibox")
local awful=require("awful")
local z=z
local io=require("io")
local os=os
module("z.ic.clipboard")
clipboard={
    lpanel=nil,
    current="",
    buffers={},
    tmp_path="",
    num_results=15,
}

function clipboard.new(args)
    local ret={}
    ret.lpanel=args.lpanel or z.lpanel({wibox_params={width=200}})
    ret.tmp_path=args.tmp_path or "/tmp/clips/"
    ret.num_results = args.num_results or 15
    --ret.lpanel.show()
    clipboard.refresh(ret,{})
    setmetatable(ret,{__index=clipboard})
    return ret
end

function clipboard.refresh(me,args)
    --for clip_file in io.popen('ls "'..me.tmp_path..'/*.clipped') do
    payload={}
    cmd='ls '..me.tmp_path..'*.clipped | tail -'..me.num_results
    for clip_file in io.popen(cmd):lines() do
        naughty.notify({text="Clip file: "..clip_file})
    end
end


setmetatable(_M, { __call=function(_, ...) return clipboard.new(...) end })
