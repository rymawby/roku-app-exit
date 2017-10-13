# Exiting out of a Roku Brightscript SceneGraph application

Originally from a [http://rymawby.com/brightscript/roku/Exiting-out-of-a-brightscript-scenegraph-app.html](rymawby.com article).

To exit a a SceneGraph application you have to complete executions of your `main` method. A nice easy way to do this is to observe a field on your scene and then fire a `roSGNodeEvent` via the port.

You’ve probably got something like the following in your main app `brs` file.

```
screen = CreateObject("roSGScreen")
m.port = CreateObject("roMessagePort")
screen.setMessagePort(m.port)
scene = screen.CreateScene("mainScene")
screen.show()
scene.setFocus(true)

while(true)
  msg = wait(0, m.port)
  msgType = type(msg)

  if msgType = "roSGScreenEvent" then
    if msg.isScreenClosed() then
      return
    end if
  end if
end while
```

This would exit out if you clicked back on the RCU when the scene is focused as `msg.isScreenClosed()` would be true - but what if we wanted to close the app on another event? It’s actually pretty simple to do. The main challenge is exiting out of the while loop. A handy way is to add an observer to the scene and pass the port as the handler.

You could modify this main screen to look something like:
```
screen = CreateObject("roSGScreen")
m.port = CreateObject("roMessagePort")
screen.setMessagePort(m.port)
scene = screen.CreateScene("mainScene")
screen.show()
scene.observeField("exitApp", m.port)
scene.setFocus(true)

while(true)
  msg = wait(0, m.port)
  msgType = type(msg)

  if msgType = "roSGScreenEvent" then
    if msg.isScreenClosed() then
      return
    else if msgType = "roSGNodeEvent" then
      field = msg.getField()
      if field = "exitApp" then
        return
      end if
    end if
  end if
end while
```

By adding the observer `scene.observeField("exitApp", m.port)` on the scene a `roSGNodeEvent ` msg will fire on `m.port` when we change the `exitApp` interface field. It’s a nice succinct way of handling this.

Set up your `MainScene.xml` so it has an observable interface boolean field called `exitApp` or similar:
```
<?xml version="1.0" encoding="utf-8" ?>

<component name="MainScene" extends="OverhangPanelSetScene" >
    <interface>
        <field id="exitApp" type="boolean" value="false" />
    </interface>

    <children>

    </children>
    <script type="text/brightscript" uri="pkg://components/MainScene.brs" />
</component>
```


Then you need to setup your `MainScene.brs` to alter the `exitApp` variable on an `OK` click:
```
function init() as Void
    print "ExitApp"
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
    if key = "OK" then
        m.top.exitApp = true
    end if
end function
```
