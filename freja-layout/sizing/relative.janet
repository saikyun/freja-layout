(use ../assert2)
(use ../compile-hiccup)
(import ./definite :as d :fresh true)

(setdyn :pretty-format "%.40M")

####
#### RELATIVE SIZING
####
## relative sizing refers to functions for determining
## sizes when the sizes depend on other variables than
## max-width/max-height. e.g. the width of children.

## WARNING!!!
# if you do both definite AND relative sizing,
# the :content-max-width and :content-max-width
# might be mutated during relative sizing.
# so if you get confused about these values during definite-sizing,
# e.g. when printing the tree after both kinds of sizing
# make sure to print these values directly after or during definite-sizing
#
# a non-mutating solution would be nice,
# but this is how it is atm
#

(var default-relative-sizing nil)

(defn set-relative-size
  [el context-max-width context-max-height]
  (def {:relative-sizing sizing
        :width width
        :height height} el)

  # something might have set the sizes during definite sizing (eg row/column)
  # which is smaller than the original max-width/height
  # TODO: make this more clear -- now we mutate a value
  # that might be confusing if one is debugging definite-sizing
  (update el :content-max-width min width)
  (update el :content-max-height min height)

  (if sizing
    (sizing el context-max-width context-max-height)
    (default-relative-sizing el context-max-width context-max-height)))

(varfn default-relative-sizing
  [el context-max-width context-max-height]
  (def {:children children
        :content-max-width max-w
        :content-max-height max-h} el)

  (assert2 (el :width) (pp el))
  (assert2 (el :height) (pp el))

  (loop [c :in children]
    (set-relative-size c max-w max-h))

  el)

(defn flow-sizing
  [el context-max-width context-max-height]
  (def {:content-max-width max-w
        :content-max-height max-h
        :children children
        :layout/lines lines} el)

  (def max-w (min max-w context-max-width))
  (def max-h (min max-h context-max-height))

  (default lines (let [ls @[]]
                   (put el :layout/lines ls)
                   ls))

  (array/clear lines)

  (var x 0)
  (var y 0)
  (var row-h 0)
  (var biggest-w 0)

  (loop [i :range [0 (length children)]
         :let [c (get children i)
               _ (set-relative-size c max-w max-h)
               {:width w
                :height h} c]]

    (when (and (pos? x)
               (or (= x max-w) # this is to cover the case when w is 0
                   (> (+ x w) max-w)))
      (array/push lines i)
      (set biggest-w (max biggest-w x))
      (set x 0)
      (+= y row-h)
      (set row-h 0))

    (+= x w)
    (set row-h (max row-h h)))

  (unless (= (length children) (last lines))
    (array/push lines (length children)))

  (unless (el :width)
    (put el :width (max biggest-w x)))

  (unless (el :height)
    (put el :height (+ y row-h)))

  el)


(defn padding-sizing
  [el context-max-width context-max-height]

  (def has-width? (el :width))
  (def has-height? (el :height))

  (def [top right bottom left] (el :offset))
  (def max-w (- context-max-width left right))
  (def max-h (- context-max-height top bottom))

  (flow-sizing el max-w max-h)

  (unless has-width?
    (def w (el :width))
    (put el :width (max (el :min-width)
                        (+ w left right))))

  (unless has-height?
    (def h (el :height))
    (put el :height (max (el :min-height)
                         (+ h top bottom))))

  el)

(defn row-sizing
  [el context-max-width context-max-height]

  (def {:children children
        :min-width min-width} el)

  (var total-weight 0)
  (def total-width context-max-width)
  (var width-used 0)

  (loop [c :in children
         :let [{:weight weight} (c :props)]]
    (if weight
      (+= total-weight weight)
      (+= width-used (c :min-width))))

  (def width-per-weight (/ (- total-width width-used)
                           total-weight))

  (loop [c :in children
         :let [{:min-width mw} c
               {:weight weight} (c :props)]]
    (when (and weight
               (> mw width-per-weight))
      (+= width-used (c :min-width))
      (-= total-weight weight)
      (put c :width mw)))

  (def width-per-weight (/ (- total-width width-used)
                           total-weight))

  (var min-h 0)

  (var extra 0)

  (loop [c :in children
         :let [{:width cw} c
               {:weight weight} (c :props)]]
    (when (and weight (not cw))
      # the leftover / extra stuff is done in order to
      # always have int widths, but also always
      # take up all of the available width
      (let [w (* weight width-per-weight)
            floored-w (math/floor w)
            leftover (- w floored-w)]
        (+= extra leftover)
        # need to do this because float 1 is not always 1
        (if (>= extra 0.9999999)
          (do
            (-- extra)
            (put c :width (inc floored-w)))
          (put c :width floored-w))))
    (set min-h (max min-h (get c :min-height))))

  (put el :min-height min-h)

  (if (zero? total-weight)
    (put el :width width-used)
    (put el :width total-width))

  (def {:content-max-width max-w
        :content-max-height max-h
        :children children
        :layout/lines lines} el)

  (default lines (let [ls @[]]
                   (put el :layout/lines ls)
                   ls))

  (array/clear lines)

  (var x 0)
  (var y 0)
  (var row-h 0)
  (var biggest-w 0)

  (loop [i :range [0 (length children)]
         :let [c (get children i)
               weight (get-in c [:props :weight])
               _ (set-relative-size c (if weight
                                        (c :width)
                                        (get c :min-width 0)) # if no weight, shrink as much as possible
                                    max-h)
               {:width w
                :height h} c]]

    (when (and (pos? x)
               (or (= x max-w) # this is to cover the case when w is 0
                   (> (+ x w) max-w)))
      (array/push lines i)
      (set biggest-w (max biggest-w x))
      (set x 0)
      (+= y row-h))

    (+= x w)
    (set row-h (max row-h h)))

  (unless (= (length children) (last lines))
    (array/push lines (length children)))

  (unless (el :width)
    (put el :width (max biggest-w x)))

  (unless (el :height)
    (put el :height (+ y row-h)))

  el)


(defn column-sizing
  [el context-max-width context-max-height]

  (def {:children children
        :min-height min-height} el)

  (var total-weight 0)
  (def total-height context-max-height)
  (var height-used 0)

  (loop [c :in children
         :let [{:weight weight} (c :props)]]
    (if weight
      (+= total-weight weight)
      (+= height-used (c :min-height))))

  (def height-per-weight (/ (- total-height height-used)
                            total-weight))

  (loop [c :in children
         :let [{:min-height mh} c
               {:weight weight} (c :props)]]
    (when (and weight
               (> mh height-per-weight))
      (+= height-used (c :min-height))
      (-= total-weight weight)
      (put c :height mh)))

  (def height-per-weight (/ (- total-height height-used)
                            total-weight))

  (var min-w 0)

  (var extra 0)

  (loop [c :in children
         :let [{:height ch} c
               {:weight weight} (c :props)]]
    (when (and weight (not ch))
      # the leftover / extra stuff is done in order to
      # always have int weightw, but also always
      # take up all of the available height
      (let [h (* weight height-per-weight)
            floored-h (math/floor h)
            leftover (- h floored-h)]
        (+= extra leftover)
        # need to do this because float 1 is not always 1
        (if (>= extra 0.9999999)
          (do
            (-- extra)
            (put c :height (inc floored-h)))
          (put c :height floored-h))))
    (set min-w (max min-w (get c :min-width))))

  (put el :min-width min-w)

  (if (zero? total-weight)
    (put el :height height-used)
    (put el :height total-height))

  (def {:content-max-width max-w
        :content-max-height max-h
        :children children
        :layout/lines lines} el)

  (default lines (let [ls @[]]
                   (put el :layout/lines ls)
                   ls))

  (array/clear lines)

  (var x 0)
  (var y 0)
  (var column-w 0)
  (var biggest-h 0)

  # lines in :vertical are columns
  (loop [i :range [0 (length children)]
         :let [c (get children i)
               weight (get-in c [:props :weight])
               _ (set-relative-size c
                                    max-w
                                    (if weight
                                      (c :height)
                                      (get c :min-height 0)) # if no weight, shrink as much as possible
)
               {:width w
                :height h} c]]

    (when (and (pos? y)
               (or (= y max-h) # this is to cover the case when w is 0
                   (> (+ y h) max-h)))
      (array/push lines i)
      (set biggest-h (max biggest-h x))
      (set y 0)
      (+= x column-w))

    (+= y h)
    (set column-w (max column-w w)))

  (unless (= (length children) (last lines))
    (array/push lines (length children)))

  (unless (el :width)
    (put el :width (+ x column-w)))

  (unless (el :height)
    (put el :height (max biggest-h y)))

  el)


(defn block-sizing
  [el context-max-width context-max-height]
  (def has-width? (el :width))

  (flow-sizing el context-max-width context-max-height)
  (put el :content-width (el :width))

  (unless has-width?
    (put el :width context-max-width))

  el)

### SHRINK

(defn shrink-sizing
  [el context-max-width context-max-height]
  (def {:children children} el)

  (unless (el :width)
    (var w (get el :width (el :min-width)))

    (loop [c :in children]
      (set w (max w (c :min-width))))

    (put el :width w))

  (flow-sizing el (el :width) context-max-height))
