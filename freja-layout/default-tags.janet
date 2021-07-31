(use ./put-many)

(defn add-default-props
  ``
Adds all default props to `element`. If you're not using these,
you're probably doing something very special.
So I recommend that you use it. See `flow` to see how to
create a basic component using `add-default-props`.

The default props are:
:width -- absolute width of the element
:height -- absolute height of the element
:min-width -- minimum width of the element
:min-height -- minimum height of the element
:max-width -- maximum width of the element (can be overriden by big children)
:max-height -- maximum height of the element (can be overriden by big children)
``
  [element props]
  (def {:width width
        :height height
        :min-width min-width
        :min-height min-height
        :max-width max-width
        :max-height max-height} props)

  # (put-many @{} :a x :b y) is like (-> @{} (put :a x) (put :b y))
  (put-many element
            :props props
            :preset-width width
            :preset-height height
            :preset-max-width max-width
            :preset-min-width min-width
            :preset-max-height max-height
            :preset-min-height min-height))

(defn flow
  ````
A component signifying that its elements will flow from top to bottom, left to right.

`props` should be a table or struct.

`flow` only has the default properties (see `add-default-props`).

`props` is short for properties.

`_children` are unused, they are compiled in `compile-hiccup.janet`.

## Examples

`[:flow {} "a" "b" "c"]` would be rendered as:
abc

If the elements would take more width than the max-width of :flow, it would look like this:
```
[:flow {:max-width 1} "a" "b" "c"]
#=>
a
b
c
```
````
  [props & _children]
  # `(dyn :element)` is used rather than `@{}` in order to
  # cache elements when needed. For all intents and purposes
  # think of `(dyn :element)` as `@{}` 
  (-> (dyn :element)
      # adds default properties such as `:width` to the element
      (add-default-props props)))

(defn row
  ````
Like flow but tries to put all elements on a single row rather than flowing
from top to bottom, it shrinks its children, if possible.

Supports children having the property `:weight`.
`:weight` is used for relative widths.
You can mix this with children having absolute widths.

`props` should be a table or struct.

`row` only has the default properties (see `add-default-props`).

`_children` are unused, they are compiled in `compile-hiccup.janet`.

## Example
```
[:row {:width 90}
  [:flow {:weight 1}]
  [:flow {:weight 2}]]
#=>
|...|......|

# each dot represents 10px
# so the first flow would be (1 / 3) * 90 = 30px
# the second flow (2 / 3) * 90 = 60px


[:row {:width 100}
  [:flow {}
    [:flow {:width 10}]]
  [:flow {:weight 1}]
  [:flow {:weight 2}]]
#=>
|.|...|......|

# the first flow is shrunk to its smallest size,
# which is 10px (due to its child having 10px width)
# then the other elements share the rest (90px)
```
````
  [props & children]
  (-> (dyn :element)
      (add-default-props props)))

(defn in-rec?
  ``
Checks if point `[px py]` is within rectangle `x y w h`.
``
  [[px py] x y w h]
  (and
    (>= px x)
    (<= px (+ x w))
    (>= py y)
    (<= py (+ y h))))

(defn clickable
  ``
Component for creating clickable elements.
When a clickable is held down, you can move the mouse away in order to cancel the click.

`props` support the default properties (see `add-default-props`) and:
- `:on-click`
-- A function taking a single parameter `ev`, which will be the event
   resulting in the click. This function will be called when `clickable`
   is clicked.

`_children` is unused.

## Example
[:clickable
  {:on-click (fn [ev] (pp ev)
                      (print "You did it!"))}
  "Click me!"]
# click it on the point `[9 23]` (9 is the x position, 23 is the y)
#=>
[:release [9 23]]
You did it!
``
  [props & _children]
  (assert (props :on-click) "clickable should have :on-click")

  (-> (dyn :element)
      (add-default-props props)
      (put :on-event
           (fn [self ev]
             #(print "testing " (get-in self [:props :id]))

             (def [kind] ev)
             (def pos (if (= kind :scroll)
                        (ev 2)
                        (ev 1)))

             (def in?
               (in-rec? pos
                        (dyn :offset-x)
                        (dyn :offset-y)
                        (self :width)
                        (self :height)))

             (match ev
               [:press pos]
               (when in?
                 (put self :down true)
                 true)

               [:release pos]
               (when (self :down)
                 (when in? ((props :on-click) ev))

                 (put self :down false)

                 true)

               false)))))

(defn text
  ````
Component for rendering text.

`props` support the default properties (see `add-default-props`) and:
- `:size` -- Font size, default 14
- `:font` -- Font family (should correspond to names registered with `assets/register-font`), default "Poppins"
- `:line-height` -- A float which will be multiplied to the height of each line of text, default 1
-- A `:line-height` of `2` means that line height should be twice as big as each line of text.
- :color -- The color of the text, e.g. `0x00ff00ff`, `:green` or `[0 1 0]`
-- See jaylib documentation for more information on how to represent colors, default 0x000000ff (black)
- :spacing -- Number of pixels between each letter, default 1
- :text -- The text to be rendered

By using `setdyn`, you can configure the defaults for:
- :size
- :font
- :line-height
- :spacing
- :color

Like this: `(setdyn :text/size 23)`

All strings `s` appearing as children will automatically be turned into `[:text {} s]`.

## Example
```
# hej is hello in swedish

"hej"
#=>
[:text {} "hej"]
#=>
hej

[:text {:size 200} "big"]
#=>
big
# imagine the above to be very big


(setdyn :text/color 0x00ff00ff)
"green hej"
#=>
hej
# imagine the above to be green
```
````
  [props & children]

  (def {:size size
        :font font
        :line-height line-height
        :color color
        :spacing spacing
        :text text} props)

  (default size (dyn :text/size 14))
  (default font (dyn :text/font "Poppins"))
  (default line-height (dyn :text/line-height 1))
  (default spacing (dyn :text/spacing 1))
  (default color (dyn :text/color 0x000000ff))

  (def t text)
  (def lines (string/split "\n" t))

  (-> (dyn :element)
      (add-default-props props)
      (put-many
        :color color
        :size size
        :spacing spacing
        :font font
        :text t
        :line-height line-height
        :lines lines)))

(defn padding
  ````
Adds pixel padding around its children.

`props` support the default properties (see `add-default-props`) and:
- `:all` -- A number for setting all of the below, will be overriden if the below are set
- `:top` -- Padding above the children
- `:right` -- Padding right of the children
- `:bottom` -- Padding below the children
- `:left` -- Padding left of the children

## Example
```
[:padding {:all 10 :bottom 20}
  "hej"]
#=>
-------
|.....|
|.hej.|
|.....|
|.....|
-------
# . means 10px of space
# | and - is just showing the bounds of the `padding` element
# it isn't actually rendered (by default)
```
````
  [props & children]
  (def {:all all
        :top top
        :right right
        :bottom bottom
        :left left} props)

  (default all 0)
  (default top all)
  (default right all)
  (default bottom all)
  (default left all)

  (-> (dyn :element)
      (add-default-props props)
      (put-many :offset [top right bottom left]
                :sizing :wrap)))

(defn align
  ````
Aligns its children to a certain part of itself.
By default grows to the full width and full height of its parent.

`props` support the default properties (see `add-default-props`) and:
- :horizontal -- :left / :right
-- :left is the "default", i.e. nothing happens, probably
-- :right aligns all children to the right side of `align`

### :vertical is not implemented yet
- :vertical -- :top / :bottom
-- :top is the "default", i.e. nothing happens, probably
-- :bottom aligns all children to the bottom side of `align`

## Example
```
[:flow {:width 100}
  [:align {:horizontal :right}
    "hej"]]
#=>
.......hej
# assuming hej takes 30px
# and each . takes 10px
# this would be the result
```
````
  [props & children]
  (def {:vertical v
        :horizontal h} props)

  (-> (dyn :element)
      (add-default-props props)
      (put-many :horizontal h
                :vertical v)))

(defn background
  ````
A component for adding background color.


`props` support the default properties (see `add-default-props`) and:
- :color -- the background color of the element, e.g. `0x00ff00ff`, `:green` or `[0 1 0]`
-- See [jaylib documentation](https://github.com/janet-lang/jaylib#colors)
 for more information on how to represent colors
-- Default 0x00000000 (fully transparent black, the last two numbers are the alpha)

## Example
```
[:background {:color 0x00ff00ff}
  "hej"]
#=>
hej
# imagine the above having green background
```
````
  [props & children]
  (def {:color color} props)

  # transparent black
  (default color 0x00000000)

  (-> (dyn :element)
      (add-default-props props)
      (put-many :color color)))

# :block is the same as flow when compiling
# but the semantic meaning is that it will grow
# to the max-width of its parent
(def tags @{:block @{:f flow}

            :flow @{:f flow}
            :row @{:f row}
            :text @{:f text}
            :padding @{:f padding}
            :align @{:f align}
            :background @{:f background}})
