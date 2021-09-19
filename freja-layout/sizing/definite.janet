(use ../assert2)
(use ../compile-hiccup)

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

### ROW


(defn row-sizing
  [row context-max-width context-max-height]

  (default-content-widths row context-max-width context-max-height)

  (def {:children children} row)

  # sum of all childrens' minimum width
  (var cs-min-width 0)
  (var row-h 0)

  # we need to figure out width per weight
  (var total-weight 0)
  (def total-width context-max-width)
  (var width-used 0)

  (loop [c :in children
         :let [{:weight weight
                :preset-width preset-width} (c :props)]]
    (cond preset-width
      (+= width-used preset-width)

      weight
      (+= total-weight weight)))

  (def width-per-weight (/ (- total-width width-used)
                           total-weight))

  # store leftover width when there is fractioned widths
  (var extra 0)

  (loop [c :in children
         :let [{:weight weight} (c :props)
               left-of-max-width (- (row :content-max-width)
                                    cs-min-width)]]
    (def max-width
      (if weight
        # we don't want fractions in our widths
        # so when extra passes a threshold,
        # we inc the width
        (min left-of-max-width
             (let [w (* weight width-per-weight)
                   floored-w (math/floor w)
                   leftover (- w floored-w)]
               (+= extra leftover)
               # need to do this because float 1 is not always 1
               (if (>= extra 0.9999999)
                 (do (-- extra)
                   (inc floored-w))
                 floored-w)))

        left-of-max-width))

    (set-definite-sizes
      c
      max-width
      (row :content-max-height))
    (+= cs-min-width (c :min-width))
    (set row-h (max row-h (c :min-height))))

  (put row :min-width (max cs-min-width
                           (get :row :min-width 0)))
  (put row :min-height (max row-h
                            (get :row :min-height 0)))

  row)
