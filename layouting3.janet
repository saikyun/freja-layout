(var apply-sizing nil)

(defn wrap-sizing
  ``
The element "wraps" around its children,
hugging them as closely as it can.

When children width passes max-width,
adds a new row.
``
  [el]
  (def {:children cs
        :offset offset
        :min-width min-width
        :width width
        :height height} el)
  (def [top right bottom left] (or offset [0 0 0 0]))

  (def max-width (- (or width (dyn :max-width))
                    left
                    right))

  (def max-height (- (or height (dyn :max-height))
                     top
                     bottom))

  (with-dyns [:max-width max-width
              :max-height max-height]
    (var x 0)
    (var y 0)
    (var el-w 0)
    (var row-h 0)
    (loop [c :in cs
           :let [{:width w :height h} (apply-sizing c)]]
      (when (and (pos? x)
                 (>= (+ x w) max-width))
        (set x 0)
        (+= y row-h)
        (set row-h 0))

      (+= x w)
      (set row-h (max row-h h))

      (set el-w (max el-w x))
      #
)

    (-> el
        (put :width (or width el-w))
        (put :height (or height (+ y row-h))))))

(varfn apply-sizing
  [el]
  (def {:sizing sizing
        :width w
        :height h
        :min-width mw
        :min-height mh} el)

  (default mw 0)
  (default mh 0)

  (cond (and w h)
    el

    (case sizing
      :wrap (wrap-sizing el)
      :expand-w (-> (wrap-sizing el)
                    (put :width (dyn :max-width)))
      :expand-h (-> (wrap-sizing el)
                    (put :height (dyn :max-height)))
      :expand (-> el
                  (put :width (dyn :max-width))
                  (put :height (dyn :max-height)))
      (if (nil? sizing)
        (do
          (print (string "no sizing, using :wrap for " (string/format "%.40M" el)))
          (wrap-sizing el))
        (sizing el)))

    # set width to highest of current width and min-width
    (update el :width max mw)
    (update el :height max mh)

    el))

(var row-sizing nil)

(defn min-width
  ``
Returns the biggest min-width in an element tree.
``
  [el]

  (def {:min-width mw
        :children cs
        :sizing sizing} el)

  (max
    (or (when (number? mw) mw) 0)
    (or (when cs
          (case sizing
            :row (with-dyns [:max-width 0]
                   ((row-sizing el) :width))
            (max ;(map min-width cs))))
        0)))

(comment
  (min-width
    @{:children [@{:tag :img
                   :min-width 300
                   :props {:width 300}}
                 @{:min-width 200}]})
  #=> 300

  (min-width
    @{:min-width 900
      :children [@{:tag :img
                   :min-width 300
                   :props {:width 300}}
                 @{:sizing :row
                   :children [@{:min-width 200}
                              @{:min-width 200}]}]})
  #=> 900

  (min-width
    @{:min-width 200
      :children [@{:tag :img
                   :min-width 300
                   :width 500
                   :props {:width 300}}
                 @{:sizing :row
                   :children [@{:min-width 200}
                              @{:min-width 200}]}]})
  #=> 400

  #
)

(defn row-sizing
  [el]
  # l->r
  (def {:children children} el)

  (def total-width (dyn :max-width))

  (var tot-weight 0)
  (var size-leftover total-width)

  (loop [c :in children
         :let [{:width pw} (c :props)]]
    (if (indexed? pw)
      (+= tot-weight (first pw))

      (let [w (or (c :width) (min-width c))]
        (put c :width w)
        (-= size-leftover w))))

  (def weight-width (if (zero? tot-weight)
                      0
                      (/ size-leftover tot-weight)))

  (var el-w 0)
  (var el-h 0)

  (loop [c :in children
         :let [{:width w} (c :props)]]
    (with-dyns [:max-width
                (if (indexed? w)
                  (* (first w) weight-width)
                  (c :width))]
      (apply-sizing c)
      (+= el-w (c :width))
      (set el-h (max el-h (c :height)))))

  (-> el
      (put :width el-w)
      (put :height el-h))
  #
)

(defn text-sizing
  [el]
  (def words (string/split " " (el :text)))

  (-> el
      (put :width (min (max (* 10 (reduce |(max $0 (length $1)) 0 words)) # longest word
                            (dyn :max-width))
                       (* 10 (length (el :text)))))
      (put :height 14)))

(defn size
  [{:width w :height h}]
  [w h])

(comment
  (size (with-dyns [:max-width 300
                    :max-height 400]
          (row-sizing @{:children [@{:sizing text-sizing
                                     :text "aoeaoeaoeoaeoouhhue nsoaentshetnsoahutnse hoatnsuheaonsae"
                                     :props @{}
                                     :children []}
                                   @{:width 100
                                     :height 40
                                     :props {:width 100
                                             :height 40}
                                     :children []}]}
                      #
)))
  #=> [310 40]


  (size (tracev (with-dyns [:max-width 300
                    :max-height 400]
          (row-sizing @{:children [@{:width 40
                                     :sizing :wrap
                                     :props @{:width 40}
                                     :children [@{:sizing text-sizing
                                                  :text "aoeaoeaoeoaeoouhhue nsoaentshetnsoahutnse hoatnsuheaonsae"
                                                  :props @{}
                                                  :children []}]}
                                   @{:width 100
                                     :height 40
                                     :props {:width 100
                                             :height 40}
                                     :children []}]}
                      #
))))
  #=> [140 40]

  (let [res (with-dyns [:max-width 300
                        :max-height 400]
              (row-sizing @{:children [@{:props @{:width [1]}
                                         :sizing :expand-w
                                         :children []}
                                       @{:props @{:width 30
                                                  :height 40}
                                         :sizing :wrap
                                         :children []
                                         :width 30
                                         :height 40}
                                       @{:props @{:width [1]}
                                         :sizing :expand-w
                                         :children []}]}
                          #
))]
    (pp res)
    (size res))
  #=> [300 40]

  #
)

(setdyn :pretty-format "%.40M")

(defn vertical-sizing
  [el]
  # t->b
)

(defn block-sizing
  [el]
  # flow l->r
)
