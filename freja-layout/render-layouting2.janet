(use freja-jaylib)
(import ./assets :as a)

(defmacro with-matrix
  [& body]
  ~(do (rl-push-matrix)

     (try (do ,;body
            (rl-pop-matrix))
       ([err]
         (do
           (rl-pop-matrix)
           (error err))))))

(var render-children nil)

(defmacro wrap-offset
  [e & body]

  ~(if-let [[x y] (,e :offset)]
     (with-matrix
       (rl-translatef x y 0)
       ,;body)
     (do ,;body)))

(defmacro print-expansion-on-error
  [form]
  ~(try
     ,form
     ([err fib]
       (print "Error inside macro, this is the expansion:")
       (pp (macex ',form))
       (print "STACKTRACE")
       (debug/stacktrace fib err)
       #       (error err)
)))

(defn render-elem
  [e]
  #(print-expansion-on-error
    (wrap-offset
      e

      (when (e :render)
        (:render e))

      (unless (e :manually-render-children)
        (render-children e))))
#)

(varfn render-children
  [{:children children}]
  (map render-elem (or children [])))

(comment
  (defn padding-render
    [e]
    (def {:offset offset} e)
    (with-matrix
      (rl-translatef ;offset 0)
      (render-children e)))
  #
)

(defn background-render
  [{:color color
    :width width
    :height height}]
  (draw-rectangle 0 0 width height color))

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
    (draw-text-ex f l [0 ly] size spacing color))

)
