(use profiling/profile)

(var apply-sizing nil)

(defnp preset-width
  ``
In order to avoid caching problems,
widths and heights that have been compiled after tree
compilation but before rendering (i.e. before the whole tree is resized),
are stored in (dyn :sized-width) and (dyn :sized-height).

So what does this mean?
It means that if an element has a width is (dyn :sized-width),
it doesn't need to be recalculated.
``
  [el]
  (or ((dyn :sized-width) el)
      (when-let [w (get el :preset-width)]
        (when (number? w)
          (put (dyn :sized-width) el w)
          (put el :width w)
          w))))

(defnp preset-height
  [el]
  (or
    ((dyn :sized-height) el)
    (when-let [h (get el :preset-height)]
      (when (number? h)
        (put (dyn :sized-height) el h)
        (put el :height h)
        h))))

(defnp el-min-width
  [el]
  (with-dyns [:max-width 0]
    (apply-sizing el))
  (el :width))

(defnp cs-min-width
  ``
Gets the width of the widest child, using :max-width 0.
If :min-width is set, and it is bigger than widest child,
use that instead.
``
  [el]
  (def {:min-width min-width
        :children cs} el)

  (var mw (or min-width 0))

  (loop [c :in cs
         :let [cmw (el-min-width c)]]
    (set mw (max mw cmw)))

  mw)


(defnp wrap-sizing
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
        :props props} el)

  (def width #(preset-width el)
    (props :width))

  (def height
    (props :height)
    #(preset-height el)
)

  (def [top right bottom left] (or offset [0 0 0 0]))

  (def min-width (or (get (get (dyn :sized-width) :min) el)
                     (max (or min-width 0)
                          (let [res (cs-min-width el)]
                            (put (get (dyn :sized-width) :min) el res)
                            res))))

  (def max-width (- (max min-width
                         (or width (dyn :max-width)))
                    left
                    right))

  (def max-height (- (or height (dyn :max-height))
                     top
                     bottom))

  (with-dyns [:max-width max-width
              :max-height max-height]
    (var x 0)
    (var y 0)
    (var lines @[])
    (var el-w 0)
    (var row-h 0)

    (p :going-through-children

       (loop [i :range [0 (length cs)]
              :let [c (cs i)
                    {:width w
                     :height h} (apply-sizing c)]]
         #(print (c :f))
         (when (and (pos? x)
                    (>= (+ x w) max-width))
           (array/push lines i)
           (set x 0)
           (+= y row-h)
           (set row-h 0))

         #(put c :position (or (c :position) @[0 0]))
         #(put-in c [:position 0] x)
         #(put-in c [:position 1] y)

         (+= x w)
         (set row-h (max row-h h))

         (set el-w (max el-w x))))

    (array/push lines (length cs))

    (def w (or width (+ left right el-w)))
    (def h (or height (+ top bottom row-h y)))
    #(put (dyn :sized-width) el w)
    #(put (dyn :sized-height) el h)

    (-> el
        (put :layout/lines lines)
        (put :width (max min-width w))
        (put :content-width max-width)
        (put :height h))))

(defnp align-sizing
  [el]
  (wrap-sizing el)

  (when (el :horizontal)
    (def w (max (el :width)
                (dyn :max-width)))
    (put el :width w))

  #  (when (el :vertical)
  #    (put el :height (put (dyn :sized-height) el (dyn :max-height))))

  el)

(var row-sizing nil)
(var vertical-sizing nil)

(import spork/test)

(defmacro put-in*
  [t path v]
  ~(do
     (def fp ,(first path))
     (def t ,t)
     (def t2 (get t fp))
     (def t2 (if t2
               t2
               (let [new-t @{}]
                 (put t fp new-t)
                 new-t)))

     (put t2 ,(path 1) ,v)

     t))

(varfnp apply-sizing
        [el]
        (def {:sizing sizing
              :min-width mw
              :min-height mh} el)

        (def width (preset-width el))
        (def height (preset-height el))

        (default mw 0)
        (default mh 0)

        (def lul-w (-> (dyn :sized-width)
                       (get (dyn :max-width))
                       (get el)))

        (def lul-h (-> (dyn :sized-height)
                       (get (dyn :max-height))
                       (get el)))

        (cond
          (and lul-w lul-h)
          (do
            (put el :width lul-w)
            (put el :height lul-h))

          #(and (= (dyn :max-width) 0)
          #     (get (get (dyn :sized-width) :min) el))
          #el

          #(and width
          #     height)
          #el

          (do
            (case sizing
              :wrap (wrap-sizing el)
              :expand-w (with-dyns [:max-width (min (get-in el [:props :max-width] 999999)
                                                    (dyn :max-width))]
                          (wrap-sizing el)
                          (put el :width
                               (max (el :width)
                                    (dyn :max-width)))) # if max-width is lower than actual width
              #                                         # we retain the actual width
              #                                         # this can happen when children are big
              :expand-h (do (wrap-sizing el)
                          (put el :height (dyn :max-height)))
              :row (row-sizing el)
              :vertical (vertical-sizing el)
              (if (nil? sizing)
                (do
                  (print (string "no sizing, using :wrap for " (string/format "%.40M" el)))
                  (wrap-sizing el))
                (sizing el)))

            (p :inner-apply-sizing
               (do
                 # set width to highest of current width and min-width
                 (def width (or (get el :preset-width)
                                (get el :width)
                                (max mw (preset-width el))))

                 (def height (or (get el :preset-height)
                                 (get el :height)
                                 (max mh (preset-height el))))

                 (put-in* (dyn :sized-width) [(dyn :max-width) el] width)
                 (put-in* (dyn :sized-height) [(dyn :max-height) el] height)

                 #(put (dyn :sized-width) el width)
                 #(put (dyn :sized-height) el height)

                 (put el :width width)
                 (put el :height height)

                 el)))))


(comment
  (defnp min-width
    ``
Returns the biggest min-width in an element tree.
``
    [el]

    (def {:min-width mw
          :children cs
          :sizing sizing} el)

    (if-let [w (preset-width el)]
      w
      (max
        (or (when (number? mw) mw) 0)
        (or (case sizing
              :row (with-dyns [:max-width 0]
                     (row-sizing el)
                     (preset-width el))
              (max ;(map min-width cs)))
            0)))))

(defnp min-height
  ``
Returns the biggest min-height in an element tree.
``
  [el]

  (def {:min-height mh
        :children cs
        :sizing sizing} el)

  (if-let [h (preset-height el)]
    h
    (max
      (or (when (number? mh) mh) 0)
      (or (case sizing
            :vertical (with-dyns [:max-height 0]
                        (vertical-sizing el)
                        (preset-height el))
            (max ;(map min-height cs)))
          0))))


(defnp axis-sizing
  [el axis]
  # l->r
  (def {:children children} el)

  (assert (or (= axis :width)
              (= axis :height)) (string "axis must be :heigth or :width, is: " axis))

  (def width? (= :width axis))

  (def sized (if width?
               (dyn :sized-width)
               (dyn :sized-height)))

  (def max-size
    (if width?
      (dyn :max-width)
      (dyn :max-height)))

  (var total-calculated-size 0)

  (var tot-weight 0)
  (var size-eaten 0)

  (var minimum-weight-size 0)

  (loop [c :in children
         :let [props (c :props)
               size (props axis)
               weight (props :weight)
               #               c (with-dyns [(if width?
               #                               :max-width
               #                               :max-height) 0]
               #                   (apply-sizing c))
               minimum
               (if width?
                 (el-min-width c)
                 (error "no el-min-height implemented"))]]
    (+= total-calculated-size minimum)

    (if (and (not size) weight)
      (do
        (set minimum-weight-size
             (max minimum-weight-size
                  (/ minimum weight)))
        (+= tot-weight weight))
      (+= size-eaten minimum)))

  (set total-calculated-size
       (max
         total-calculated-size
         max-size))

  (def size-leftover (max 0 (- total-calculated-size size-eaten)))

  (def weight-size
    (max minimum-weight-size
         (if (zero? tot-weight)
           0
           (/ size-leftover tot-weight))))

  (var el-w 0)
  (var el-h 0)

  (loop [c :in children
         :let [props (c :props)
               size (props axis)
               weight (props :weight)
               new-size (if (and (not size) weight)
                          #TODO: need to take care of remainder
                          (math/floor (* weight weight-size))
                          (c axis))]]
    (put c axis new-size)
    (put-in* sized [max-size c] new-size)
    (with-dyns [:max-width (if width?
                             new-size
                             (dyn :max-width))
                :max-height (if (not width?)
                              new-size
                              (dyn :max-height))]
      (apply-sizing c)
      (when (and (not size) weight)
        (put c axis new-size)
        (put-in* sized [max-size c] new-size))
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

(varfnp row-sizing
        [el]
        (axis-sizing el :width))

(varfnp vertical-sizing
        [el]
        (axis-sizing el :height))

(defnp text-sizing
  [el]
  (def words (string/split " " (el :text)))

  (def w (min (max (* 10 (reduce |(max $0 (length $1)) 0 words)) # longest word
                   (dyn :max-width))
              (* 10 (length (el :text)))))

  (-> el
      (put :width w)
      (put :height 14)))

(defnp size
  [{:width w :height h}]
  [w h])

(setdyn :pretty-format "%.40M")

################# row-sizing

(assert (= [310 40]
           (size (with-dyns [:max-width 300
                             :max-height 400
                             :sized-width @{:min @{}}
                             :sized-height @{}]
                   (row-sizing @{:sizing :wrap
                                 :children [@{:sizing text-sizing
                                              :text "aoeaoeaoeoaeoouhhue nsoaentshetnsoahutnse hoatnsuheaonsae"
                                              :props @{}
                                              :children []}
                                            @{:preset-width 100
                                              :sizing :wrap
                                              :preset-height 40
                                              :props {:width 100
                                                      :height 40}
                                              :children []}]}
                               #
)))))

(comment
  #TODO : fix vertical
  (assert (= [40 400]
             (size (with-dyns [:max-width 300
                               :max-height 400
                               :sized-width @{:min @{}}
                               :sized-height @{}]
                     (vertical-sizing
                       @{:sizing :wrap
                         :children [@{:props @{:weight 1}
                                      :sizing :wrap
                                      :children []}
                                    @{:props @{:height 30
                                               :width 40}
                                      :sizing :wrap
                                      :height 30
                                      :width 40
                                      :children []}
                                    @{:props @{:weigth 1}
                                      :sizing :wrap
                                      :children []}]}
                       #
)))))
  #
)


(assert (= [140 40]
           (size (with-dyns [:max-width 300
                             :max-height 400
                             :sized-width @{:min @{}}
                             :sized-height @{}]
                   (row-sizing @{:children [@{:preset-width 40
                                              :sizing :wrap
                                              :props @{:width 40}
                                              :children [@{:sizing text-sizing
                                                           :text "aoeaoeaoeoaeoouhhue nsoaentshetnsoahutnse hoatnsuheaonsae"
                                                           :props @{}
                                                           :children []}]}
                                            @{:preset-width 100
                                              :preset-height 40
                                              :sizing :wrap
                                              :props {:width 100
                                                      :height 40}
                                              :children []}]}
                               #
)))))


(assert (= [300 40]
           (size (with-dyns [:max-width 300
                             :max-height 400
                             :sized-width @{:min @{}}
                             :sized-height @{}]
                   (row-sizing @{:children [@{:props @{:weight 1}
                                              :sizing :expand-w
                                              :children []}
                                            @{:props @{:width 30
                                                       :height 40}
                                              :sizing :wrap
                                              :children []
                                              :preset-width 30
                                              :preset-height 40}
                                            @{:props @{:weight 1}
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
           (with-dyns [:sized-width @{:min @{}}
                       :sized-height @{}
                       :max-width 900
                       :max-height 400]
             (cs-min-width
               @{:props {}
                 :children [@{:tag :img
                              :children []
                              :min-width 300
                              :props {:width 300}}
                            @{:min-width 200
                              :props @{}
                              :children []}]}))))


(with-dyns [:max-width 400
            :max-height 500
            :sized-width @{:min @{}}
            :sized-height @{}]
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
               (cs-min-width
                 @{:min-width 900
                   :props {}
                   :children [@{:tag :img
                                :min-width 300
                                :children []
                                :props {:width 300}}
                              row-thing]})))

    (= 500
       (cs-min-width
         @{:min-width 200
           :props {}
           :children [@{:tag :img
                        :min-width 300
                        :width 500
                        :children []
                        :props {:width 300}}
                      row-thing]}))

    #
))
