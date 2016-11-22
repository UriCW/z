#Z - Another configuration framework for the awesome window manager
##z.* is a collection modules for awesome 

[![Demo video](http://img.youtube.com/vi/GTmk7h5BDBs/0.jpg)](http://www.youtube.com/watch?v=GTmk7h5BDBs "Awesome Z")

At it's core, z provides two types of panels: panel.lua, and lpanel.lua, it also contains a utils.lua which has some helper functions.

A panel is a floating wibox with a list of either strings or widgets. It provides binding for assigning actions to the list elements, for scrolling up/down/first/last on the displayed list, for showing/hidding/timer-popup of the host wibox, setting the list's payload (for example the widgets list, or list of strings), allows for selection (of string or widget) and appending an element to the list.

lpanel does more or less the same, but handles a list of awesome layouts as inputes instead of strings or widgets.

On top of this, we have some modules that utilize the above to provide some useful functionality.

##z.it - i tag, you're it, z.it is for tagging

Implementing a sets of tags (see ./z/it), client management, confgurable client to tag mechanism, organising clients and much more. Using the core awesome and awful implementation of tagging.

This configuration is aiming at seemlessly managing large number of applications and long lived work sessions.
It can be used for convinient development environment for a full development stack as it organises opened project and applications into multiple tags in multiple tagsets, which are renameable and highly configurable. it works well with penetration testing sessions and other complex and otherwise messy desktop environments.

It utilizes z.panel and z.lpanel (see ./z/[l]panel.lua and ./z/utils.lua) wibox panel lists and menus.
This configuration was tested on awesome "v3.5.9 (Mighty Ravendark)" and lua 5.1.5
See rc.lua for hints on how to implement your personalised modifications.
