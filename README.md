#Z - Another configuration framework for the awesome window manager
##z.* is a collection modules for awesome 

[![Demo video](http://img.youtube.com/vi/GTmk7h5BDBs/0.jpg)](http://www.youtube.com/watch?v=GTmk7h5BDBs "Awesome Z")

At it's core, z provides two types of panels: panel.lua, and lpanel.lua, it also contains a utils.lua which has some helper functions.

A panel is a floating wibox with a list of either strings or widgets. It provides binding for assigning actions to the list elements, for scrolling up/down/first/last on the displayed list, for showing/hidding/timer-popup of the host wibox, setting the list's payload (for example the widgets list, or list of strings), allows for selection (of string or widget) and appending an element to the list.

lpanel does more or less the same, but handles a list of awesome layouts as inputes instead of strings or widgets.

On top of this, we have some modules that utilize the above to provide some useful functionality.

##z.it - i tag, you're it, z.it is for tagging

z.it is composed of several parts: elements, screens, tagsets and tags.

Each screen contains a list of tagsets, each tagset contains a list of tags.
elements is the base module, and is used to interface with the different components.
There is also a z/it/utils.lua which contains helper funcitonality.

```lua
local z = require("z")
...
local it = z.it.elements({})
```

To define a set of initial tagsets and tags for each screen:
```lua
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
```
This will iterate over the screens, and construct the tagsets. elements will handle constructing the tagsets and tags for each screen.
You can then call functions in the elements object (it) to add screens, tagsets, tags. you can also bind keys for renaming, deleting, cycling etc.

In your global keys, you probably want to do something like this:
```lua

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
    ...
```
What this does:

```lua 
it.screen[mouse.screen].lpanel:pop({timeout=1}) 
```
pops the panel displaying the tagsets for 1 second, then hides it

```lua
it:cycle({type="<TYPE>", direction=<DIR>,screen=mouse.screen})
```
where \<TYPE> is either "tag" or "tagset", and \<DIR> is the cycling direction (1 forwards, -1 backwards).
This will just cycle through the tags and tagsets accordingly.

In order to show/hide the panel containing all of this, you wanna do something like this:

```lua
    awful.key({ modkey }, "F2", function()
        z.it.utils.toggle(it)
    end),
```
To create a new tag or tagset:
```lua
    awful.key({ modkey }, "t", function()
        it:add_tag({})
        it.screen[mouse.screen].lpanel:pop({})     end),
    awful.key({ modkey , "Shift" }, "t", function()
        it:add_tagset({})
        it.screen[mouse.screen].lpanel:pop({})
    end ),
```
To organise the tags in the tagset, by shifting them left or right, use:
```lua
    awful.key({ modkey, "Control"  }, "Left", function()
        z.it.utils.move_tag(it,{screen=mouse.screen,direction="left"})
    end),
    awful.key({ modkey, "Control"  }, "Right", function()
        z.it.utils.move_tag(it,{screen=mouse.screen,direction="right"})
    end),
```

To rename a tag or a tagset:
```lua
    awful.key({ modkey ,  },"BackSpace" , function()
        --it:rename_tagset({})
        it.screen[mouse.screen].lpanel:show()
        it:rename_tag({})
    end ),
    awful.key({ modkey , "Shift"}, "BackSpace", function()
        it.screen[mouse.screen].lpanel:show()
        it:rename_tagset({})
    end ),
```
and to delete a tag:
```lua
    awful.key({ modkey , "Mod1" }, "t", function()
        it.screen[mouse.screen].lpanel:pop()
        it:delete_tag({})
    end ),
```

Please note: that many of the above function calls accept arguments which I have not shown, until i start documenting those, you're going to have to look at the code or use the default behiviour i'm affraid.
