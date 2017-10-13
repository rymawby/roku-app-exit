function init() as Void
    print "ExitApp"
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
    if key = "OK" then
        m.top.exitApp = true
    end if
end function
