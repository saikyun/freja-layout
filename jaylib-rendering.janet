(use jaylib)
(import ./assets :as a)

(defn text-render
  [{:color color
    :text text
    :font font
    :size size
    :spacing spacing
    :lines lines
    :line-ys line-ys
    :line-height line-height}]

  (def f (a/font font size))

  (loop [i :range [0 (length lines)]
         :let [l (lines i)
               ly (line-ys i)]]
    (draw-text-ex f l [0 ly] size spacing color)))

(defn background-render
  [{:width width
    :height height
    :color color}]
  (draw-rectangle 0 0 width height color))
