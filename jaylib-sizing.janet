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

  (ch/put-many
    el
    :line-ys line-ys
    :lines lines
    :width w
    :height h))
