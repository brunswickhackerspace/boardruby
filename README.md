# boardruby
Parametrically generate Eagle protoboard files

This builds an Eagle board description as an XML tree,
then simply emits it to the standard output.  To run it:

ruby genprotoboard.rb > myboard.brd

Then you can open the board file directly in Eagle, send it
to OSHPark to be fabbed, or whatever you like.

Note that it doesn't create a matching schematic, so Eagle will
give a warning about back-annotation being severed.

I haven't verified that the mounting hole logic works entirely
correctly yet.
