#it - A tagging management framework for the awesome WM



Each screen has a list of tagsets, each tagset has a list of tags,


-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
local it = z.it.elements({})
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

here every screen gets an initial tagset "sys" with first tag "init".
"it" is used as a context for the tags

