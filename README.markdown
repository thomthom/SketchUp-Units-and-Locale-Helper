# SketchUp Units and Locale #

The purpose of this mini-library is to provide easy conversions of Area and
Volume within SketchUp as well as dealing with user environment locale.

## Lengths ##

SketchUp provides the `Length` class to format internal units into strings
representing the unit in the current model's unit and user locale. It also 
extends the `String` class with methods to convert strings from any SketchUp
unit and user's locale into `Length` objects.

## SketchUp's Shortcomings ##

### Locale Setting ###

What SketchUp lacks is methods to convert regular numbers to and from numeric
objects to strings in the user's locale. For instance `1.5.to_s` will return
a string `"1.5"` even if the user locale users comma as decimal separator - even
though `1.5.mm.to_s` will return `"1,5mm"`. Similarly, when the user locale uses
comma `"1,5".to_f` will return `1.0`.

### Areas and Volumes ###

While there is `Sketchup.format_area` that will take square inches and format
into model units there is no methods for the reverse. Volume is completely
missing. On top of that, there is no easy way to define area or volume in any
other unit than square inches - similar to `15.mm` etc.

## Unit and Locale Library Design ##

This library is intentionally not modifying or extending base classes in order
to avoid potential clashes with other libraries and any future version updates.
Because of this you have to use syntax which is slightly more awkward, such as
`Area.mm2( 500 )` instead of `500.mm2`.

The reason for not using the most elegant syntax is the shared nature of the
SketchUp Ruby API environment. This is explained in more detail in the article
[Golden Rules of SketchUp Plugin Development](http://www.thomthom.net/thoughts/2012/01/golden-rules-of-sketchup-plugin-development/).

### Module Wrapper ###

For the same reason as above the code provided is wrapped in an `Example`
module in order to indicate to developers who wish to make use of the code to
wrap everything up in their own namespace.

## Improve and Share ##

Please make comments, suggestions and improvements to this library. :)