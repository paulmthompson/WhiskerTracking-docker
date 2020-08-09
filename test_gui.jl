using WhiskerTracking

println("Whisker Tracking Loaded")

myhandles=make_gui();

println("GUI Made")

WhiskerTracking.add_callbacks(myhandles.b,myhandles)

if !isinteractive()
  c=Condition()
  signal_connect(myhandles.b["win"],:destroy) do c_widget
    notify(c)
  end
  wait(c)
end
