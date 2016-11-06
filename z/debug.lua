local ipairs=ipairs
local type=type
local print=print
local naughty=require('naughty')
module('z.debug')

function print_table(t)
    for i,element in ipairs(t)do
        print(i.." type:"..type(element))
    end
end


function dump(e)
    naughty.notify({text="type"..type(e)})
    print ("type"..type(e).."\n")
--    if type(e)=='userdata' then print "user data\n" end
end


function msg(txt)
    naughty.notify({text="debug:"..txt,timeout=30})
end
