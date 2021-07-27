(defn v+!
  ``
Destructivly adds two vectors of size 2 together.
Mutates the first argument.
``
  [v0 v1]
  (update v0 0 + (v1 0))
  (update v0 1 + (v1 1)))

(defn size->px
  ``
Takes a container-size which should be an array/tuple with
absolute pixel sizes, e.g. `[100 30]'.
`grid-size` is either in absolute pixel values,
or in percentage form, e.g. `[[10 :%] [20 :%]]`.
This would mean the grid item should be 10% the width of
the container, and 20% of the height.
``
  [container-size grid-size]
  (seq [i :range [0 (length grid-size)]
        :let [s (grid-size i)]]
    (match s
      [n :%] (* n 0.01 (container-size i))
      [n :px] n
      n n)))

(defmacro children-geometries
  ``
Takes a list of tables/structs with a `:size-px`, and a `max-width` number,
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
  (with-syms [$x $y $row-h $w $h]
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

       (loop [$child :in ,cs]
         (def [,$w ,$h] ($child :size-px))

         (when (and (pos? ,$x)
                    (> (+ ,$x ,$w)
                       ,max-width))
           (+= ,$y ,$row-h)
           (set ,$x 0)
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
    [{:size-px [50 20]}
     {:size-px [50 20]}
     {:size-px [50 20]}]
    100
    (print "\tleft:\t" $left
           "\tright:\t" $right
           "\ttop:\t" $top
           "\tbottom:\t" $bottom
           "\tmiddle-x:\t" $middle-x
           "\tmiddle-y:\t" $middle-y))
  #
)

(defn bounding-box
  ``
Takes a list of tables/structs with a `:size-px`, and a `max-width` number.
Returns the size of the rectangle encompassing all these elements,
including when elements are wrapped due to becoming wider
than the max-width.
``
  [elems max-width]
  (var res @[0 0])

  (children-geometries
    elems
    max-width
    (put res 0 (max (res 0) $right))
    (put res 1 $bottom))

  res)

(assert (deep= (bounding-box [{:size-px [50 20]}
                              {:size-px [50 20]}]
                             100)
               @[100 20]))

(assert (deep= (bounding-box [{:size-px [60 20]}
                              {:size-px [50 20]}]
                             100)
               @[60 40]))

(assert (deep= (bounding-box [{:size-px [30 20]}
                              {:size-px [30 40]}]
                             50)
               @[30 60]))

(defn get-sizes
  ````
Takes a `dom` table/struct, which has this format:
```
{:size size          # e.g. [20 40] for w/h in pixels
                     # can be nil

 :children children  # array/tuple of children
                     # each child should be a dom table/struct

 :padding padding    # e.g. [10  20    30     40]
                     #       top right bottom left padding
                     # to remember, think of a clock starting at the top

 :grid grid          # array/tuple of grid sizes for children
                     # e.g. [[100 30] [20% 10%]] would mean
                     # first child has 100px width, 30px height
                     # second child has 20% width, 10% height
                     # when using %, it is based on the size of the parent
}
```
````
  [dom &keys {:container container
              :grid-size grid-size
              :max-width max-width}]
  (def {:size size
        :children children
        :padding padding
        :grid grid
        :bg bg}
    dom)

  (default padding [0 0 0 0])

  # padding positions
  # 0 = top
  # 1 = right
  # 2 = bottom
  # 3 = left
  # same as css. like a clock starting at 12
  (def padding-size
    @[(+ (padding 1) (padding 3))
      (+ (padding 0) (padding 2))])

  # either there's an explicit size
  # or there's a grid-size (size defined by container)
  # or the size is dependent on children (= size nil)
  (default size grid-size)

  # either there is a pre-defined size in the dom
  # or it gets the max-width from the container
  (def max-width (or (get size 0)
                     max-width
                     (error "need max-width or size 0")))

  # reduce max width by width of the padding
  (def max-width (- max-width (padding-size 0)))

  (def me @{:bg bg
            :padding padding
            :max-width max-width})

  ## try to determine my size
  (put me :size-px
       ## do I have an explicit size?
       (cond size
         (seq [i :range [0 (length size)]
               :let [s (size i)]]
           (match s
             #[n :%] (* n 0.01 ((container :size-px) i))
             [n :px] n
             n n))

         ## or maybe a grid size?
         grid-size))

  (when children
    # width of all children that use % or pixel values
    (put absolute-width
      (reduce
        (fn [aw {:size size}]
### TODO check size and add to aw
)
        0
        children)

    (put me :children
         (seq [i :range [0 (length children)]
               :let [c (children i)
                     grid-size (-?>> (get grid i)
                                     (size->px [max-width (size 1)]))]]
           (get-sizes c
                      :grid-size grid-size
                      :container me
                      :max-width max-width))))

  (unless (me :size-px)

    (put me :size-px
         (v+! (bounding-box
                (or (me :children) [])
                max-width)

              padding-size))

    (pp (me :size-px)))

  me)

(defn get-positions
  [idom &keys {:container container
               :grid-pos grid-pos}]
  (def {:children children
        :grid grid
        :padding padding
        :max-width max-width} (tracev idom))

  (put idom :pos-px grid-pos)

  (children-geometries
    (or children [])
    max-width
    (get-positions
      $child :grid-pos
      [(+ (get padding 3 0) $left)
       (+ (get padding 0 0) $top)])
    (pp ($child :pos)))

  idom
  #
)

(comment
  ### TODO: fix grandchild position
  (def tree {:size [300 300]
             :padding [20 20 0 20]
             :children [{:bg 0x000000ff
                         #:size [60 40]
                         :children [{:bg :blue
                                     :size [160 40]}]}
                        {:bg :green
                         :size [80 60]}
                        {:bg :red
                         :size [30 40]}
                        {:size [30 40]}
                        {:bg :red
                         :size [30 40]}
                        {:size [30 40]}
                        {:bg :red
                         :size [30 40]}
                        {:size [30 40]}
                        {:bg :red
                         :size [30 40]}]}))

### TODO: support weight & absolute pixels
# space-between
(def tree
  {:size [300 300]
   :padding [20 20 20 20]
   :grid [[[1 :weight] 10]
          [20 20]
          [[1 :weight] 30]]
   :children [{:bg :red}
              {}
              #{:bg :red}
]})

(def tree (get-sizes tree))

(def tree (get-positions tree :grid-pos [0 0]))

(pp tree)

(defn traverse
  ``
Applies f to each dom node.
Useful for debugging.
``
  [f tree]
  (f tree)
  (when-let [cs (tree :children)]
    (each c cs (traverse f c))))

(comment
  (def tree
    (get-sizes {:size [800 600]
                :grid [[[10 :%] [10 :%]]
                       [[20 :%] [20 :%]]]
                :children
                [{:children
                  [{:children
                    [{:padding [1000 1000 1000 1000]
                      :children
                      [{:size [30 20]}]}]}]}
                 {}]}))
  (pp tree)
  @{:children @[@{:children @[@{:children @[@{:children @[@{:size-px @[30 20]}] :size-px @[2030 2020]}] :size-px @[2030 2020]}] :size-px @[80 60]} @{:size-px @[160 120]}] :size-px @[800 600]}

  (traverse |(pp ($ :size-px)) tree)
  @[800 600]
  @[80 60]
  @[2030 2020]
  @[2030 2020]
  @[30 20]
  @[160 120]

  #
)

(import freja/frp)
(comment
  (def tree
    (get-sizes {:size [800 600]
                :grid [[[50 :%] [50 :%]]
                       [[20 :%] [20 :%]]]
                :bg :gray
                :children
                [{:bg :blue
                  :children
                  [{:bg :green
                    :padding [5 5 5 5]
                    :children
                    [{:padding [10 10 10 10]
                      :bg :pink
                      :children
                      [{:size [40 30]
                        :bg :white}
                       {:size [40 30]
                        :bg :white}
                       {:size [40 30]
                        :bg :white}
                       {:size [40 30]
                        :bg :white}
                       {:size [40 30]
                        :bg :white}
                       {:size [40 30]
                        :bg :white}
                       {:size [40 30]
                        :bg :white}
                       {:size [20 80]
                        :bg :orange}
                       {:padding [30 10 20 10]
                        :bg :purple
                        :children
                        [{:size [20 20]}]}]}]}]}
                 #{:size [10 10]}
]})))

(defmacro with-matrix
  [& body]
  ~(do (rl-push-matrix)

     (try (do ,;body
            (rl-pop-matrix))
       ([err]
         (do
           (rl-pop-matrix)
           (error err))))))

(defn draw
  [[_ dt]]

  (with-matrix
    (rl-translatef 800 100 0)

    (var rgb @[0.1 0.1 0.1])

    (traverse (fn [node]
                (update rgb 0 + 0.1)
                (def [w h] (node :size-px))
                (def [x y] (node :pos-px))
                (draw-rectangle-rec [x y w h] (get node :bg rgb)))
              tree))
  #
)

(defonce render-it @{})

(merge-into
  render-it
  @{:on-event (fn [_ ev] (draw ev))})

(frp/subscribe-finally! frp/frame-chan render-it)


# test padding / "flow"
(let [tree
      (get-sizes {:padding [13 7 17 5]
                  :children [{:size [33 41]}
                             {:size [33 41]}
                             {:size [33 41]}]}
                 :max-width (+ 66 7 5))]

  # (pp (tree :size-px))

  (assert (= (get-in tree [:size-px 0])
             (+ 33 33 7 5)))
  #             w  w  right left

  (assert (= (get-in tree [:size-px 1])
             (+ 41 41 13 17)))
  #             h  h  top bottom
  #
)
