(use ../assert2)
(use ../compile-hiccup)
(import ./test-tags :as jt)
(import ./definite :as d :fresh true)

(setdyn :pretty-format "%.40M")

####
#### RELATIVE SIZING
####
## relative sizing refers to functions for determining
## sizes when the sizes depend on other variables than
## max-width/max-height. e.g. the width of children.

(var default-relative-sizing nil)

(defn set-relative-size
  [el context-max-width context-max-height]
  (def {:relative-sizing sizing} el)
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

## TODO: implement the "wrapping" behaviour

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

(comment

  (defn row-sizing
    [row context-max-width context-max-height]

    (default-content-widths row context-max-width context-max-height)

    (def {:children children} row)

    (var total-weight 0)
    (def total-width (row :content-max-width))
    (var width-used 0)

    (loop [c :in children
           :let [{:weight weight} (c :props)]]
      (if weight
        (+= total-weight weight)
        (do
          (set-definite-sizes
            c
            (row :content-max-width)
            (row :content-max-height))
          (+= width-used (c :min-width)))))

    (def width-per-weight (/ (- total-width width-used)
                             total-weight))

    (var min-h 0)

    (loop [c :in children
           :let [{:weight weight} (c :props)]]
      (when weight
        (put c :preset-width (* weight width-per-weight))
        (set-definite-sizes c
                            (c :width)
                            (row :content-max-height)))
      (set min-h (max min-h (get c :min-height))))

    (put row :min-height min-h)

    (if (zero? total-weight)
      (put row :width min-width)
      (put row :width total-width))

    row))


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

  (var min-h 0)

  (loop [c :in children
         :let [{:weight weight} (c :props)]]
    (when weight
      (put c :width (* weight width-per-weight)))
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


(defn block-sizing
  [el context-max-width context-max-height]
  (def has-width? (el :width))

  (flow-sizing el context-max-width context-max-height)
  (put el :content-width (el :width))

  (unless has-width?
    (put el :width context-max-width))

  el)

(put-in jt/tags [:flow :relative-sizing] flow-sizing)
(put-in jt/tags [:block :relative-sizing] block-sizing)
(put-in jt/tags [:padding :definite-sizing] d/padding-sizing)
(put-in jt/tags [:padding :relative-sizing] padding-sizing)
(put-in jt/tags [:row :definite-sizing] d/row-sizing)
(put-in jt/tags [:row :relative-sizing] row-sizing)
(put-in jt/tags [:background :relative-sizing] flow-sizing)

(let [el (compile [:flow {}
                   "hej"
                   [:block {}]
                   [:flow {:width 100 :height 100}]]
                  :tags jt/tags)
      with-sizes (d/set-definite-sizes el 800 600)
      with-sizes (set-relative-size el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  # size is 800 due to :block growing to max-width
  (assert2 (= (with-sizes :width) 800))

  # three lines since block becomes its own line
  (assert2 (= 3 (length (with-sizes :layout/lines)))))


(let [el (compile [:flow {}
                   "hej"
                   [:flow {:width 100 :height 100}]]
                  :tags jt/tags)
      with-sizes (d/set-definite-sizes el 800 600)
      with-sizes (set-relative-size el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  # width is the width of children
  (assert2 (= (with-sizes :width) 116))

  # three lines since block becomes its own line
  (assert2 (= 1 (length (with-sizes :layout/lines)))))


(let [el (compile [:padding {:left 500}
                   [:block {}]]
                  :tags jt/tags)
      with-sizes (d/set-definite-sizes el 800 600)
      with-sizes (set-relative-size el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  (assert2 (= 300 (get-in el [:children 0 :width])))

  (var all-have-size true)
  (d/traverse-render-tree |(set all-have-size (and all-have-size
                                                   ($ :width)
                                                   ($ :height)))
                          with-sizes)

  (assert2 all-have-size (print-tree with-sizes))

  # should be same when compiling again with caching
  (let [el (compile [:padding {:left 490 :right 10}
                     [:block {}]]
                    :tags jt/tags
                    :element el)
        with-sizes (d/set-definite-sizes el 800 600)
        with-sizes (set-relative-size el 800 600)]

    (print-tree with-sizes)
    (assert2 (table? with-sizes))

    (assert2 (= 300 (get-in el [:children 0 :width])))

    (var all-have-size true)
    (d/traverse-render-tree |(set all-have-size (and all-have-size
                                                     ($ :width)
                                                     ($ :height)))
                            with-sizes)

    (assert2 all-have-size (print-tree with-sizes))))


(let [el (compile [:padding {:left 500}
                   [:row {}
                    [:block {}
                     "a"]
                    [:block {:weight 1}]]]
                  :tags jt/tags)
      with-sizes (d/set-definite-sizes el 800 600)
      with-sizes (set-relative-size el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes)))

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


(put-in jt/tags [:shrink :relative-sizing] shrink-sizing)

(let [el (compile [:padding {:left 500}
                   [:shrink {}
                    [:block {}
                     "hello"]
                    [:block {:width 100}]]]
                  :tags jt/tags)
      with-sizes (d/set-definite-sizes el 800 600)
      with-sizes (set-relative-size el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  # shrinks to biggest child width
  (assert2 (= 100 (get-in with-sizes [:children 0 :width]))))


(let [el (compile [:padding {:left 500}
                   [:shrink {}
                    [:block {}
                     "hello"]
                    [:block {:width 10}]]]
                  :tags jt/tags)
      with-sizes (d/set-definite-sizes el 800 600)
      with-sizes (set-relative-size el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  # shrinks to biggest child width ("hello" in this case)
  (assert2 (= 26 (get-in with-sizes [:children 0 :width]))))


(let [el (compile
           [:shrink {}
            [:padding {:top 6 :bottom 6}
             "a"]
            [:block {}]]
           :tags jt/tags)
      with-sizes (d/set-definite-sizes el 800 600)
      with-sizes (set-relative-size el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  # height equal to the padding-part, since the block has 0 height
  (assert2 (= (get-in with-sizes [:children 0 :height])
              (with-sizes :height))))


#### TEXT

(let [el (compile
           [:background {:color 0x00ff00ff}
            "a"]
           :tags jt/tags)
      with-sizes (d/set-definite-sizes el 800 600)
      with-sizes (set-relative-size el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  # height equal to the padding-part, since the block has 0 height
  (assert2 (= (get-in with-sizes [:children 0 :height])
              (with-sizes :height))))


#
#
#
#
#
# just something random
#

(let [v (math/floor (inc (* 20 (math/random))))]
  (print (string/repeat ":) " v))
  (when (= v 20)
    (print "You rock!")))
