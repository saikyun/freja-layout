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


(use jaylib)

(defmacro with-matrix
  [& body]
  ~(do (rl-push-matrix)

     (try (do ,;body
            (rl-pop-matrix))
       ([err fib]
         (do
           (rl-pop-matrix)
           (debug/stacktrace fib err)
           #(error err)
)))))

(defmacro with-translation
  [[s v] & body]

  ~(let [,s ,v]
     (if ,s
       (with-matrix
         (if (= 4 (length ,s))
           (rl-translatef (,s 3) (,s 0) 0)
           (rl-translatef (,s 0) (,s 1) 0))
         ,;body)
       (do ,;body))))

(var flow-render-children nil)

(defn noop
  [_]
  nil)

(defn render
  [el]
  (def {:render-children render-children
        :render render}
    el)

  (default render noop)
  (default render-children flow-render-children)

  #(print (el :tag))
  #(tracev p)
  (render el)

  (with-translation [o (el :offset)]
    #(pp (el :offset))
    #(tracev o)
    (render-children el)))

(varfn flow-render-children
  [{:children cs
    :tag tag
    :content-width content-width}]

  (unless (empty? cs)
    #(print "gonna print children")

    (var x 0)
    (var y 0)
    (var row-h 0)

    (try
      (do
        (rl-push-matrix)

        (rl-push-matrix)

        (loop [c :in cs
               :let [{:width w
                      :height h} c]]

          #(print "tag: " (c :tag))

          (when (and (pos? x)
                     (> (+ x w) content-width))
            (rl-pop-matrix)

            (set x 0)
            (+= y row-h)

            (rl-translatef 0 row-h 0)

            (set row-h 0)

            (rl-push-matrix))

          (render c)

          # (print "pos: " x " " y)

          (rl-translatef w 0 0)

          (+= x w)

          (set row-h (max row-h h))
          #
)
        (rl-pop-matrix)
        (rl-pop-matrix))
      ([err fib]
        (rl-pop-matrix)
        (rl-pop-matrix)
        #        (error err)
        (debug/stacktrace fib err)))))
