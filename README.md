## Scratch 2.0 editor and player [![Build Status](https://api.travis-ci.org/LLK/scratch-flash.svg?branch=master)](https://travis-ci.org/LLK/scratch-flash)
This is a port of the open source version of Scratch 2.0 to Haxe. Although the original Scratch 2.0 source code was released under GPL v2 or later, this fork is released under GPL v3 or later. This was necessary because it includes some code from the Apache Flex project, whose code is licensed under the Apache License v2.0. That license is incompatible with GPL v2.


### Building

I think it's possible to compile the code using

```
haxe -cp src -cp flex-src -swf main.swf -main Main
```

or something like that. It was tested with Haxe 3.2.1.

Please note that the Scratch trademarks (including the Scratch name, logo, Scratch Cat, and Gobo) are property of MIT. For use of these Marks, please see the [Scratch Trademark Policy](http://wiki.scratch.mit.edu/wiki/Scratch_1.4_Source_Code#Scratch_Trademark_Policy).

### Debugging
Here are a few integrated development environments available with Flash debugging support:
* [Intellij IDEA](http://www.jetbrains.com/idea/features/flex_ide.html)
* [Adobe Flash Builder](http://www.adobe.com/products/flash-builder.html)
* [FlashDevelop](http://www.flashdevelop.org/)
* [FDT for Eclipse](http://fdt.powerflasher.com/)
