(import jaylib)
(import ./render-layouting2 :as r :fresh true)
(import freja/frp)
(import ./assets :as a)


(defn in-rec?
  [[px py] x y w h]
  (and
    (>= px x)
    (<= px (+ x w))
    (>= py y)
    (<= py (+ y h))))


(defn text
  [{:size size
    :font font
    :line-height line-height
    :color color
    :spacing spacing} & children]
  (default size (dyn :text/size 14))
  (default font (dyn :text/font))
  (default line-height (dyn :text/line-height 1))
  (default spacing (dyn :text/spacing 2))
  (default color 0x000000ff)

  (def t (string/join children ""))
  (def lines (string/split "\n" t))
  (def line-ys (array/new (length lines)))
  (var w 0)
  (var h 0)

  (array/push line-ys 0)

  (each l lines
    (let [[lw lh] (jaylib/measure-text-ex (a/font font size) l size spacing)]
      (set w (max w lw))
      (+= h (* line-height lh))
      (array/push line-ys h)))

  (+= h (* line-height (min 0 (dec (length lines)))))

  @{:render r/text-render
    :color color
    :size size
    :spacing spacing
    :font font
    :text t
    :line-height line-height
    :line-ys line-ys
    :lines lines
    :width w
    :height h})


(defn merge-props
  [props extra]
  (def new-props (merge-into @{} props))

  (update new-props :height
          |(-> (if $
                 $
                 (extra :height)) # height overrides max-height
))

  (update new-props :max-width
          |(-> (if $
                 (min $ (extra :max-width))
                 (extra :max-width))
               (max (get new-props :width 0)) # width overrides max-width
))

  (update new-props :max-height
          |(-> (if $
                 (min $ (extra :max-height))
                 (extra :max-height))
               (max (get new-props :height 1)) # height overrides max-height
))

  new-props)

(var compile nil)


(defmacro children-geometries
  ``
Takes a list of tables/structs with a `:width` / `:height`, and a `max-width` number,
and a body.
Evaluates the body for each child in cs, with some special variables set.
$left $right $top $bottom $middle-x $middle-y corresponds
to each childs position. E.g. $left would be the left side
of the child, and $bottom the bottom side.
These positions are affected by wrapping, i.e. if childrens width accumulate
to become greater than max-width, a new row is added.

In body the variable $child is also available, which is set to the current child
of each iteration.
``
  [cs max-width & body]
  (with-syms [$x $y $row-h $w $h $xi]
    ~(do
       (var $left 0)
       (var $right 0)
       (var $top 0)
       (var $bottom 0)
       (var $middle-x 0)
       (var $middle-y 0)

       (var ,$x 0)
       (var ,$y 0)
       (var ,$row-h 0)

       (var ,$xi 0)

       (loop [$i :range [0 (length ,cs)]
              :let [$child (,cs $i)]]
         (def ,$w ($child :width))
         (def ,$h ($child :height))

         (when (and (pos? ,$x)
                    (and ,max-width
                         (> (+ ,$x ,$w)
                            ,max-width)))
           (+= ,$y ,$row-h)
           (set ,$x 0)
           (set ,$xi 0)
           (set ,$row-h 0))

         (set $top ,$y)
         (set $bottom (+ ,$y ,$h))
         (set $left ,$x)
         (set $right (+ ,$x ,$w))
         (set $middle-x (math/floor (+ ,$x (* 0.5 ,$w))))
         (set $middle-y (math/floor (+ ,$y (* 0.5 ,$h))))

         (+= ,$x ,$w)

         (set ,$row-h (max ,$row-h ,$h))

         ,;body))))

(comment
  (children-geometries
    [{:width 50
      :height 20}
     {:width 50
      :height 20}
     {:width 50
      :height 20}]
    100
    (print "\tleft:\t" $left
           "\tright:\t" $right
           "\ttop:\t" $top
           "\tbottom:\t" $bottom
           "\tmiddle-x:\t" $middle-x
           "\tmiddle-y:\t" $middle-y))
  #
)

(defn elems->bounding-box
  ``
With elements `es` flowing from left to right, wrapping on
max-width `mw`, imagine a rectangle surrounding all the elements.
This function returns the size of that rectangle.
``
  [mw es]
  (var w 0)
  (var h 0)
  (children-geometries
    es
    mw
    (set w (max w $right))
    (set h (max h $bottom)))
  [w h])

(defn flow-elements
  ``
With elements `es` flowing from left to right, wrapping on
max-width `mw`, imagine a rectangle surrounding all the elements.
This function returns the size of that rectangle.

Sets the x/y-offset of the elements.
``
  [mw es]
  (var w 0)
  (var h 0)
  (children-geometries
    es
    mw
    (def x (get-in $child [:offset 0] 0))
    (def y (get-in $child [:offset 1] 0))
    (put $child :offset @[(+ x $left)
                          (+ y $top)])
    (set w (max w $right))
    (set h (max h $bottom)))
  [w h])


(defn horizontal-elements
  ``
With elements `es` flowing from left to right,
imagine a rectangle surrounding all the elements.
This function returns the size of that rectangle.

Sets the x/y-offset of the elements.
``
  [es]
  (var w 0)
  (var h 0)
  (children-geometries
    es
    nil
    (def x (get-in $child [:offset 0] 0))
    (def y (get-in $child [:offset 1] 0))
    (put $child :offset @[(+ x $left)
                          (+ y $top)])
    (set w (max w $right))
    (set h (max h $bottom)))
  [w h])


(defn vertical-elements
  ``
With elements `es` flowing from top to bottom,
imagine a rectangle surrounding all the elements.
This function returns the size of that rectangle.

Sets the x/y-offset of the elements.
``
  [es]
  (var w 0)
  (var h 0)
  (children-geometries
    es
    0
    (def x (get-in $child [:offset 0] 0))
    (def y (get-in $child [:offset 1] 0))
    (put $child :offset @[(+ x $left)
                          (+ y $top)])
    (set w (max w $right))
    (set h (max h $bottom)))
  [w h])


(defn compile-children
  [props children]
  (var new-children @[])

  (loop [c :in (or children [])
         :when c]
    (array/push new-children (if (table? c)
                               c
                               (compile
                                 {:max-width (min (props :max-width)
                                                  (get props :width 99999999))
                                  :max-height (min (props :max-height)
                                                   (get props :height 99999999))}
                                 c))))

  new-children)


(defn block
  [props & children]
  (def {:height height
        :width width
        :max-height max-height
        :max-width max-width}
    props)

  (default width max-width)
  (def max-height (or height max-height))

  (def children (compile-children props children))

  (def [_ h] (flow-elements max-width children))

  (default height h)
  (assert width "width must be set")

  @{:width width
    :height height
    :children children}
  #
)

(defn add-children
  [component children &keys {:max-width max-width
                             :max-height max-height}]
  (assert max-width "there must always be a :max-width")
  (assert max-height)

  (def children (map |(if (table? $)
                        $ ## if the child is already a table, it has already been compiled
                        (compile {:max-width max-width
                                  :max-height max-height} $))
                     (filter truthy?
                             (or children []))))

  (def [w h] (flow-elements max-width children))

  (-> component
      (update :width |(or $ w))
      (update :height |(or $ h))
      (put :children children)))

(import spork/test)

(varfn compile
  ````
`extra` is a struct or table containing
data coming from the parent, e.g.
max-width and max-height

## the hiccup norm

`hiccup` is an indexed object (tuple or array),
in the form of:
```
[a-function {:property :value}
  [another-function {} ...]]
```

hiccup starts with a function, then a struct / table
containing the properties. the rest of the arguments
are the children, which are more hiccup data.

children can also be atoms such as strings and numbers.

## after first compilation

the first compilation of the `hiccup` will return
either a table or another hiccup form.

if the new hiccup form is a regular hiccup form,
(an indexed form with function, props and children),
it will just run compile on it again, until
a table is returned.

### special case of first element being a table

in special cases, the first element in the result of
compiling `hiccup` is a table
this means that some hiccup has been compiled,
but the children hasn't been compiled, e.g. like this:

```
[@{:render-f r/background-render
   :background 0x00ff00ff}
 {}
 [text {} "hello"]]
```

this means that the first element is compiled, i.e.
it doesn't need compilation.
however, the children do need compilation.
additionally, all compiled hiccup needs :width and :height,
in this case, since they are not defined for the table,
it will be calculated based on the size of the children.

see the usage of `add-children` below.

#### rationale for special case

the reason for doing it this way is to let users define new
components, which wrap children, without having to manually
compile the children. in the above example, the table
is the result of compiling the `background` component,
and if you look at the source of `background`, you'll
see that it is indeed very simple, thanks to not having
to deal with children (not hard to think of real world analogies).

compare this to the source of `block`, which needs to
deal with the children explicitly. in my opinion,
this complexity is worth the ease of use for the
component designer and implementer.
````
  [context hiccup]
  (def hiccup (if (or (buffer? hiccup) (string? hiccup))
                [text {} hiccup]
                hiccup))
  (def res
    #(test/timeit
    (do
      (def [f-or-table props] hiccup)

      (assert (or (table? props) (struct? props))
              (string "props must be table or struct\n"
                      (string/format "%.40M" props)
                      "\nis not, full form:\n"
                      (string/format "%.40M" props)))

      (assert context "context must be defined")

      (def children (drop 2 hiccup))
      # (tracev hiccup)
      (def res (if (function? f-or-table)
                 (f-or-table (merge-props props context)
                             ;children)

                 (add-children
                   f-or-table
                   children
                   # if max-width or width is defined in f-or-table (i.e. the user
                   # explicitly set a width / max-width) we use that
                   # otherwise, use the max-width coming from the parent of
                   # f-or-table, that is (context :max-width)
                   :max-width (get f-or-table :max-width
                                   (get f-or-table :width
                                        (context :max-width)))
                   :max-height (get f-or-table :max-height
                                    (get f-or-table :height
                                         (context :max-height))))))

      (def res (cond (indexed? res) # tuple or array
                 (compile context res)

                 res))

      (assert (table? res) (string/join ["final result of dom-function must be table"
                                         (string f-or-table)
                                         "was not"]
                                        "\n"))

      (assert (res :width)
              (string/join ["final result of dom-function must have width"
                            (string/format "%.40m" res)
                            "did not"]
                           "\n"))

      (assert (res :height)
              (string/join ["final result of dom-function must have width"
                            (string/format "%.40m" res)
                            "did not"]
                           "\n"))

      res)) #)

  #(pp hiccup)

  res)


(defn background
  [props & children]
  (def {:color color} props)

  (default color 0x00000000)

  # by returning a tuple with
  # with children uncompiled,
  # we tell the compiler to compile them for us
  # since the props are already used,
  # we set them to `nil`
  [@{:render r/background-render
     :color color}
   {}
   ;children])

(defn block2
  [{:height height
    :width width}
   & children]
  [block {} [block {} ;children]]
  #
)


(defn button
  [props & children]
  (def off 0x00110033)
  (def down 0x00ff00ff)
  (def outside 0xff0000ff)

  (def bg (compile props
                   [background
                    {:color off}
                    ;children]))

  (defn button-on-event [self ev]
    (match ev
      ['(or (= :press (first ev))
            (= :double-click (first ev))
            (= :triple-click (first ev))) pos]
      (when (in-rec? pos
                     (dyn :offset-x)
                     (dyn :offset-y)
                     (self :width)
                     (self :height))
        (put bg :color down)
        (put self :down true))

      [:drag pos]
      (when (self :down)
        (put bg :color outside)
        (when
          (in-rec? pos
                   (dyn :offset-x)
                   (dyn :offset-y)
                   (self :width)
                   (self :height))
          (put bg :color down))

        true)

      [:release pos]
      (when (self :down)
        (put bg :color off)
        (when (in-rec? pos
                       (dyn :offset-x)
                       (dyn :offset-y)
                       (self :width)
                       (self :height))

          (when-let [cb (props :on-press)]
            (cb self ev)))
        (put self :down false)
        true)))

  [@{:on-event button-on-event}
   {}
   bg])


(defn single
  "Copy of table `t` without :children key."
  [t]
  (var nt @{})
  (loop [[k v] :pairs t
         :when (not= k :children)]
    (put nt k v))
  nt)


(defn padding
  [props & children]
  (def {:max-height max-height
        :max-width max-width
        :all all
        :left left
        :top top
        :right right
        :bottom bottom}
    props)

  (default left (or all 0))
  (default top (or all 0))
  (default right (or all 0))
  (default bottom (or all 0))

  (def inner-width (- max-width left right))

  (def children (map |(compile {:max-width inner-width
                                :max-height (- max-height top bottom)} $)
                     (or children [])))

  (def [w h] (flow-elements inner-width children))

  @{:children children
    :width (+ w left right)
    :height (+ h top bottom)
    :offset [left top]})

(defn spacing
  [props & children]
  [block {}
   ;(map (fn [c]
           (when c
             [padding
              {:right (props :spacing)}
              c]))
         children)])

(defn space-evenly
  [props & children]
  (def children
    (compile-children props children))

  (def [w h] (horizontal-elements children))

  (let [space (- (props :max-width)
                 (+ ;(map |($ :width) children)))
        space-each (/ space (inc (length children)))]

    (loop [i :range [0 (length children)]
           :let [c (children i)]]
      (update-in c [:offset 0] |(+ (or (tracev $) 0)
                                   (* (inc i) space-each)))))

  [block {:width (props :max-width) :height h}
   ;children])

(defn predefined-height
  [[o props]]
  (if (table? o)
    (o :heigth)
    (props :height)))

(defn space-between
  [props & children]
  (def mh (min (props :max-height) (get props :height 99999)))

  (def vertical (= :vertical (props :direction)))

  (def children
    (if (not vertical)
      (compile-children props children)
      (do
        (def children (filter truthy? children))

        (var available-height mh)
        (var nof-flexible-children (length children))

        (loop [c :in children
               :let [ph (predefined-height c)]]
          (when ph
            (-= available-height ph)
            (-- nof-flexible-children)))

        (var flexible-height-per-child (/ available-height nof-flexible-children))

        (var new-children @[])

        (loop [c :in children
               :let [ph (predefined-height c)]]
          (array/push
            new-children
            (if (table? c)
              c
              (compile
                {:max-width (props :max-width)
                 :max-height mh
                 :height (unless ph flexible-height-per-child)} # if height isn't predefined, set the calculated height
                c))))

        new-children)))

  (when (and (not (props :height))
             vertical)
    (print "Warning: vertical is set, despite no height:\n")
    (pp props))

  (def [w h] (if vertical
               (vertical-elements children)
               (horizontal-elements children)))

  (when space-between
    (let [space (if vertical
                  (- (get props :height 0)
                     (+ ;(map |($ :height) children)))
                  (- (props :max-width)
                     (+ ;(map |($ :width) children))))
          space-each (/ space (dec (length children)))
          x-or-y (if vertical 1 0)]

      (loop [i :range [1 (length children)]
             :let [c (children i)]]

        (update-in c [:offset x-or-y] |(+ $ (* i space-each))))))

  @{:width (props :max-width)
    :height (or (props :height) h)
    :children children})

(defn vertical
  [props & children]
  (def children (compile-children props children))

  (def [w h] (vertical-elements children))

  @{:width w
    :height h
    :children children})

(defn grid
  [props & children]

  (def {:space-evenly se
        :space-between sb
        :spacing sp
        :vertical v} props)

  (cond sp (spacing props ;children)
    se (space-evenly props ;children)
    sb (space-between props ;children)
    vertical (vertical props ;children)
    [block {} ;children])
  #
)

(def tree
  [padding
   {:padding-right 50
    :padding-left 500
    :padding-top 40}
   [background {:background 0x000000ff}
    [padding {:all 10}
     [text {:size 15
            :color 0xff00ffff}
      "Hello 123 123 123 123 12 123 123!"]]]
   [block {}
    [text {} "Hello!"]]])


(comment
  (def tree-compiled
    (compile
      {:max-width (get-screen-width)
       :max-height (get-screen-height)}
      tree))

  (pp tree-compiled)

  (defonce render-tree @{})

  (put render-tree :on-event
       (fn [_ [_ dt]]
         (with-dyns [:dt dt]
           (r/render-elem tree-compiled))))

  (frp/subscribe-finally! frp/frame-chan render-tree))
