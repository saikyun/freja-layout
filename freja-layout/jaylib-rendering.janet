(use freja-jaylib)

(defn text-render
  [props x y]
  (def {:color color
        :text text
        :font font
        :size size
        :spacing spacing
        :lines lines
        :line-ys line-ys
        :line-height line-height} props)

  (def f ((dyn :text/get-font) font size))

  (loop [i :range [0 (length lines)]
         :let [l (lines i)
               ly (line-ys i)]]
    (draw-text-ex f l [0 ly] size spacing color)))

(defn background-render
  [{:width width
    :height height
    :color color}
   x
   y]
  (draw-rectangle 0 0 width height color))


(use freja-jaylib)

(defmacro with-matrix
  [& body]
  ~(do (rl-push-matrix)

     (try (do ,;body
            (rl-pop-matrix))
       ([err fib]
         (do
           (rl-pop-matrix)
           #(debug/stacktrace fib err)
           (propagate err fib))))))

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
  [_ _ _]
  nil)

(defn render
  [el x y]
  (def {:render-children render-children
        :render render}
    el)

  (default render noop)
  (default render-children flow-render-children)

  #(print (el :tag))
  #(tracev p)
  (render el x y)

  (with-translation [o (el :offset)]
    #(pp (el :offset))
    #(tracev o)
    (render-children el
                     (+ (get-in el [:offset 3] 0)
                        x)
                     (+ (get-in el [:offset 0] 0)
                        y))))

(varfn flow-render-children
  [{:children children
    :layout/lines lines
    :f f}
   parent-x
   parent-y]

  (def screen-h (get-screen-height))

  #(print ">> rendering " (length children) " children for")
  #(print f)

  (default lines [0 (length children)])

  (var line-start 0)
  (var y 0)

  (loop [line-end :in lines
         :while (< (+ parent-y y) screen-h)]
    #
    (var line-h 0)
    (var x 0)

    (loop [i :range [line-start line-end]
           :let [c (children i)
                 {:width w
                  :height h} c]]
      #(print)
      #(print "new stuff wat")
      #(print (c :f))
      #(print "???" (c :width) "-" w)

      (put c :left x)
      (put c :top y)

      (render c (+ x
                   parent-x)
              (+ y
                 parent-y))

      #(print)

      #(print (c :f))


      #(tracev x) (tracev w)
      #(print (string/format "%.40M" c))
      (+= x w)

      (rl-translatef w 0 0)
      (set line-h (max line-h h)))

    # (print "end of line")

    (+= y line-h)

    (set line-start line-end)

    (rl-translatef (- x) line-h 0)
    #
)

  (rl-translatef 0 (- y) 0)

  #(print "<< done rendering children on y " y " / " screen-h)

  #
)

(defn align-render-children
  [el parent-x parent-y]
  (def {:children children
        :layout/lines lines
        :width width
        :horizontal hori} el)

  (def screen-h (get-screen-height))

  (if-not (= hori :right)
    (flow-render-children el parent-x parent-y)

    (do
      (var line-start 0)
      (var y 0)
      (loop [line-end :in lines
             :let [line-w (do
                            (var w 0)
                            (loop [i :range [line-start line-end]
                                   :let [c (children i)
                                         cw (c :width)]]
                              (+= w cw))
                            w)]
             :while (< (+ parent-y y) screen-h)]
        #
        (var line-h 0)
        (var x 0)
        #        (with-matrix
        (set x (- width line-w))
        (rl-translatef (- width line-w) 0 0)

        (loop [i :range [line-start line-end]
               :let [c (children i)
                     {:width w
                      :height h} c]]
          (put c :left x)
          (put c :top y)

          (render c (+ x parent-x) (+ y parent-y))

          (+= x w)

          (rl-translatef w 0 0)
          (set line-h (max line-h h)))

        (rl-translatef (- x) line-h 0)

        (+= y line-h)

        (set line-start line-end))

      (rl-translatef 0 (- y) 0)))
  #
)
