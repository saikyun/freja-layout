(import ./compile-hiccup :as ch)
(import jaylib)
(import ./assets :as a)

(defn text-sizing
  [el]
  (def {:lines lines
        :font font
        :size size
        :spacing spacing
        :line-height line-height} el)

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

  #                 #TODO: this should be minimal char (word?) width instead
  (def w #(if no-break
    w
    #(min w (max 10
    #              (dyn :max-width))))
)
  (def h #(if no-break
    h
    #  (min h (dyn :max-height)))
)

  (put (dyn :sized-width) el w)
  (put (dyn :sized-height) el h)

  (ch/put-many
    el
    :line-ys line-ys
    :lines lines
    :width w
    :height h))


(defn oneliner-sizing
  [el]
  (def {:text text
        :font font
        :size size
        :spacing spacing
        :line-height line-height} el)

  (def [w h] (jaylib/measure-text-ex (a/font font size) text size spacing))

  (put (dyn :sized-width) el w)
  (put (dyn :sized-height) el h)

  (ch/put-many
    el
    :width w
    :height h))
