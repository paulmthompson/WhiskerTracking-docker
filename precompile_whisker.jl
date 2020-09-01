
using WhiskerTracking, Gtk.ShortNames, Knet

myhandles=make_gui();

WhiskerTracking.add_callbacks(myhandles.b,myhandles)
