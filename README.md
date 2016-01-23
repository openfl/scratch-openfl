## Scratch 2.0 editor and player 
This is a port of the open source version of Scratch 2.0 to Haxe. Although the original Scratch 2.0 source code was released under GPL v2 or later, this fork is released under GPL v3 or later. This was necessary because it includes some code from the Apache Flex project, whose code is licensed under the Apache License v2.0. That license is incompatible with GPL v2.


### Building

I normally build the code in FlashDevelop, but I think once you have [Haxe](http://haxe.org/download/) and [OpenFL](http://www.openfl.org/download/) installed, you can build the code using 

```
openfl build html5
```

or something like that. It was tested with Haxe 3.2.1 and OpenFl 3.5.3 using the html5 target. There are a couple of small bugs in OpenFL that I found so far while getting the code to work. Hopefully, I'll get around to submitting those fixes.

By default, the Scratch distribution won't work because it doesn't come with any content. You can copy the `medialibraries` and `medialibrarythumbnails` directories to `bin/html5/bin` then things should work. If you invoke OpenFL with

```
openfl run html5
```

it will automatically start up a local webserver to properly serve the content to your web browser for debugging.

Please note that the Scratch trademarks (including the Scratch name, logo, Scratch Cat, and Gobo) are property of MIT. For use of these Marks, please see the [Scratch Trademark Policy](http://wiki.scratch.mit.edu/wiki/Scratch_1.4_Source_Code#Scratch_Trademark_Policy).

