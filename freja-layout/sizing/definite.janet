(use ../assert2)
(use ../compile-hiccup)
(import ./test-tags :as jt :fresh true)

(setdyn :pretty-format "%.40M")

####
#### DEFINITE SIZING
####
## definite sizes refer to sizes that can be determined
## from max-width / max-height alone. as an example,
## text will always grow to its max-width, so the size
## can be determined earlier than "relative" sizes.
## all min-widths can be calculated in this step too.
## another example are elements with preset width / height.

(defn traverse-render-tree
  [f el]
  (loop [c :in (get el :children)]
    (traverse-render-tree f c))

  (f el))

### ways to affect :max-width
# :max-width
# :preset-width
# :offset

(var default-definite-sizing nil)

(defn set-definite-sizes
  [el context-max-width context-max-height]
  (def {:definite-sizing sizing} el)

  # remove cached width / height
  (-> el
      (put :width nil)
      (put :height nil))

  # when sizing is definite, it is calculated before any children
  # this lets the sizing determine max width for the children etc
  (if sizing
    (sizing el context-max-width context-max-height)
    (default-definite-sizing el context-max-width context-max-height))

  # if a width was set, this will be the min-width
  # otherwise, min-width is 0
  (unless (el :min-width)
    (put el :min-width (get el :width 0)))

  # same for height
  (unless (el :min-height)
    (put el :min-height (get el :height 0)))

  el)

(defn default-content-widths
  [el context-max-width context-max-height]
  (def {:offset offset
        :preset-width preset-width
        :preset-height preset-height
        :preset-max-width preset-max-width
        :preset-max-height preset-max-height} el)

  # if w / h are preset (e.g. defined in props), those will be used
  (-> el
      (put :width preset-width)
      (put :height preset-height))

  (def max-width (-> (or preset-width
                         (min
                           (or preset-max-width 999999999)
                           context-max-width))))

  (def max-height (-> (or preset-height
                          (min #                     I'll regret this when there are
                               #                     999999k monitors
                               (or preset-max-height 999999999)
                               context-max-height))))

  (-> el
      (put :content-max-width max-width)
      (put :content-max-height max-height)))

(defn default-children
  [el]
  (def {:preset-min-width preset-min-width
        :preset-width preset-width
        :preset-min-height preset-min-height
        :preset-height preset-height} el)

  (var min-width (or preset-width preset-min-width 0))
  (var min-height (or preset-height preset-min-height 0))

  (loop [c :in (get el :children)]
    (set-definite-sizes
      c
      (el :content-max-width)
      (el :content-max-height))
    (set min-width (max min-width (c :min-width)))
    (set min-height (max min-height (c :min-height))))

  (put el :min-width min-width)
  (put el :min-height min-height))

(varfn default-definite-sizing
  [el context-max-width context-max-height]

  (default-content-widths el context-max-width context-max-height)
  (default-children el)

  el)

# basic test
(let [el (compile [:block {}
                   "hej"]
                  :tags jt/tags)
      with-sizes (set-definite-sizes el 800 600)]
  (assert2 (table? el))

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  #(print-tree (get-in with-sizes [:children 0]))
  (let [c (get-in with-sizes [:children 0])
        {:width w :height h} c]
    (assert2 (and (= w 16) (= h 14)) (pp c))))

### PADDING

(defn padding-sizing
  [el context-max-width context-max-height]
  (def [top right bottom left] (el :offset))

  (-> el
      (default-content-widths context-max-width context-max-height)
      (update :content-max-width - left right)
      (update :content-max-height - top bottom)
      default-children
      (update :min-width + left right)
      (update :min-height + top bottom)))


(put-in jt/tags [:padding :definite-sizing] padding-sizing)

### PADDING test

(let [el (compile [:padding {:left 10 :right 5
                             :top 25
                             :bottom 20}
                   [:block {}
                    "hej"]]
                  :tags jt/tags)
      with-sizes (set-definite-sizes el 800 600)]

  (print "padding")
  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  # width is max-width - left - right
  (assert2 (= 555 (with-sizes :content-max-height)))

  # height is max-height - top - bottom
  (assert2 (= 785 (with-sizes :content-max-width))))


### ROW


(defn row-sizing
  [row context-max-width context-max-height]

  (default-content-widths row context-max-width context-max-height)

  (def {:children children} row)

  (var cs-min-width 0)
  (var row-h 0)

  (loop [c :in children
         :let [{:weight weight} (c :props)]]
    (set-definite-sizes
      c
      (row :content-max-width)
      (row :content-max-height))
    (+= cs-min-width (c :min-width))
    (set row-h (max row-h (c :min-height))))

  (put row :min-width (max cs-min-width
                           (get :row :min-width 0)))
  (put row :min-height (max row-h
                            (get :row :min-height 0)))

  row)

(put-in jt/tags [:row :definite-sizing] row-sizing)

### ROW test

(let [el (compile [:row {}
                   [:block {:width 100} "hej pa dig"]
                   [:block {:weight 1}
                    [:padding {:left 200}]]
                   [:block {:weight 2}]]
                  :tags jt/tags)
      with-sizes (set-definite-sizes el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes)))

(let [el (compile [:row {}
                   [:block {:width 100} "hej pa dig"]
                   [:block {:weight 1}
                    [:padding {}
                     [:block {} "hej"]]]
                   [:block {:weight 2}]]
                  :tags jt/tags)
      with-sizes (set-definite-sizes el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  (assert2 (not (get-in el [:children 1 :width]))
           (print-tree (get-in el [:children 1])))

  (assert2 (= 116 (el :min-width))))


(let [el (compile [:row {}
                   [:block {:width 100} "hej pa dig"]
                   [:block {:weight nil}
                    [:padding {:right 300}
                     [:block {} "hej"]]]
                   [:block {:weight 2}]]
                  :tags jt/tags)
      with-sizes (set-definite-sizes el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes)))
