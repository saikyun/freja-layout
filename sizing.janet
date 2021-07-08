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

      #(put c :position (or (c :position) @[0 0]))
      #(put-in c [:position 0] x)
      #(put-in c [:position 1] y)

      (+= x w)
      (set row-h (max row-h h))

      (set el-w (max el-w x))
      #
)

    (-> el
        (put :width (or width (+ left right el-w)))
        (put :content-width max-width)
        (put :height (or height (+ top bottom row-h y))))))

(var row-sizing nil)
(var vertical-sizing nil)

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
      :row (row-sizing el)
      :vertical (vertical-sizing el)
      (if (nil? sizing)
        (do
          (print (string "no sizing, using :wrap for " (string/format "%.40M" el)))
          (wrap-sizing el))
        (sizing el)))

    # set width to highest of current width and min-width
    (update el :width max mw)
    (update el :height max mh)

    el))

(defn min-width
  ``
Returns the biggest min-width in an element tree.
``
  [el]

  (def {:min-width mw
        :width width
        :children cs
        :sizing sizing} el)

  (if width
    width
    (max
      (or (when (number? mw) mw) 0)
      (or (case sizing
            :row (with-dyns [:max-width 0]
                   ((row-sizing el) :width))
            (max ;(map min-width cs)))
          0))))

(defn min-height
  ``
Returns the biggest min-height in an element tree.
``
  [el]

  (def {:min-height mh
        :height height
        :children cs
        :sizing sizing} el)

  (if height
    height
    (max
      (or (when (number? mh) mh) 0)
      (or (case sizing
            :vertical (with-dyns [:max-height 0]
                        ((vertical-sizing el) :height))
            (max ;(map min-height cs)))
          0))))


(defn axis-sizing
  [el axis]
  # l->r
  (def {:children children} el)

  (assert (or (= axis :width)
              (= axis :height)) (string "axis must be :heigth or :width, is: " axis))

  (def width? (= :width axis))

  (def total-size (if width?
                    (dyn :max-width)
                    (dyn :max-height)))

  (var tot-weight 0)
  (var size-leftover total-size)

  (loop [c :in children
         :let [props (c :props)
               size (props axis)]]
    (if (indexed? size)
      (+= tot-weight (first size))

      (let [s (or (c axis) ((if width?
                              min-width
                              min-height) c))]
        (put c axis s)
        (-= size-leftover s))))

  (def weight-size (if (zero? tot-weight)
                     0
                     (/ size-leftover tot-weight)))

  (var el-w 0)
  (var el-h 0)

  (loop [c :in children
         :let [props (c :props)
               size (props axis)
               new-size (if (indexed? size)
                          (* (first size) weight-size)
                          (c axis))]]
    (put c axis new-size)
    (with-dyns [:max-width (if width?
                             new-size
                             (dyn :max-width))
                :max-height (if (not width?)
                              new-size
                              (dyn :max-height))]
      (apply-sizing c)
      (if width?
        (do
          (+= el-w (c :width))
          (set el-h (max el-h (c :height))))
        (do
          (set el-w (max el-w (c :width)))
          (+= el-h (c :height))))))

  (-> el
      (put :content-width el-w)
      (put :content-height el-h)
      (put :width el-w)
      (put :height el-h))
  #
)

(varfn row-sizing
  [el]
  (axis-sizing el :width))

(varfn vertical-sizing
  [el]
  (axis-sizing el :height))

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

(setdyn :pretty-format "%.40M")

################# row-sizing

(assert (= [310 40]
           (size (with-dyns [:max-width 300
                             :max-height 400]
                   (row-sizing @{:sizing :wrap
                                 :children [@{:sizing text-sizing
                                              :text "aoeaoeaoeoaeoouhhue nsoaentshetnsoahutnse hoatnsuheaonsae"
                                              :props @{}
                                              :children []}
                                            @{:width 100
                                              :sizing :wrap
                                              :height 40
                                              :props {:width 100
                                                      :height 40}
                                              :children []}]}
                               #
)))))

(assert (= [40 400]
           (size (with-dyns [:max-width 300
                             :max-height 400]
                   (vertical-sizing
                     @{:sizing :wrap
                       :children [@{:props @{:height [1]}
                                    :sizing :wrap
                                    :children []}
                                  @{:props @{:height 30}
                                    :sizing :wrap
                                    :height 30
                                    :width 40
                                    :children []}
                                  @{:props @{:height [1]}
                                    :sizing :wrap
                                    :children []}]}
                     #
)))))


(assert (= [140 40]
           (size (with-dyns [:max-width 300
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
)))))


(assert (= [300 40]
           (size (with-dyns [:max-width 300
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
)))))


#
#
#
#
#


################# min-width

(assert (= 300
           (min-width
             @{:props {}
               :children [@{:tag :img
                            :children []
                            :min-width 300
                            :props {:width 300}}
                          @{:min-width 200
                            :props @{}
                            :children []}]})))


(with-dyns [:max-width 400
            :max-height 500]
  (let [row-thing @{:sizing :row
                    :props {}
                    :children [@{:min-width 200
                                 :sizing :wrap
                                 :props {}
                                 :children []}
                               @{:min-width 200
                                 :sizing :wrap
                                 :props {}
                                 :children []}]}]
    (assert (= [400 0] (size (row-sizing row-thing))))

    (assert (= 900
               (min-width
                 @{:min-width 900
                   :children [@{:tag :img
                                :min-width 300
                                :children []
                                :props {:width 300}}
                              row-thing]})))

    (= 500
       (min-width
         @{:min-width 200
           :children [@{:tag :img
                        :min-width 300
                        :width 500
                        :props {:width 300}}
                      row-thing]}))

    #
))