--print ("startup loaded")

function OnSave(filename)
    if (insave) then
       return
    end    
    --print("on save: "..filename) 
    local JS_EXT = 'js'
    local IDM_BUILD = 302 -- from SciTE.h
    local ext = props['FileExt']  -- e.g 'js'
    if ext == JS_EXT then
        local f = io.popen("jshint --reporter /home/maks/config/js/scite-jshint-reporter.js "..filename.." 2>&1", 'r')
        local s = assert(f:read('*a'))
        f:close()
        output:ClearAll()
        print (s)
    else
       --print ("not JS file "..filename)       
    end
    
    return false -- dont swallow the event
end

function InsertDate()
   editor:AddText(os.date("%Y-%m-%d"))
end

-- insert the current time in HH:MM:SS format
function InsertTime()
    editor:AddText(os.date("%H:%M:%S"))
end