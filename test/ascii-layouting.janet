(use ./../freja-layout/put-many)

(import ./../freja-layout/compile-hiccup :as ch)
(import ./../freja-layout/default-tags :as dt)
(import ./../freja-layout/sizing/definite :as def-siz)
(import ./../freja-layout/sizing/relative :as rel-siz)

(defmacro eol
  []
  ~(unless (zero? x)
     (-= x space-w) # remove the size of the space
     (set w (max w x))
     (set x 0)
     (array/push new-lines current-line)
     (set current-line @"")))

(defn text-sizing
  ``
By default, the minimal width of a text is
the width of the biggest word. This means sentences will be wrapped,
but words won't be broken up.

To add no word wrapping, one could add a "no-break" option.
``
  [el context-max-width context-max-height]
  (def {:lines lines
        :max-width max-width
        :line-height line-height} el)

  (default max-width context-max-width)

  (def line-ys (array/new (length lines)))
  (array/push line-ys 0)

  (var w 0)
  (var h 0)
  (var x 0)
  (def lh 1)

  (def new-lines @[])
  (var current-line @"")

  (def space-w 1)

  (each l lines
    (let [words (string/split " " l)]
      (each word words
        (let [ww (length word)]
          (when (and (pos? x) (> (+ ww x) max-width))
            # if we end up here, a line was too long
            (eol))

          (unless (empty? current-line)
            (buffer/push-string current-line " "))

          (buffer/push-string current-line word)

          (+= x ww)
          (+= x space-w)
          x)))
    # here is just end of line due to a newline character
    (eol))

  (put-many
    el
    :lines new-lines
    :width w
    :height (length new-lines)))

(defn text-render
  [{:text text} x y]
  (prin text))

(defn text
  [props & _]
  (def {:text text
        :definite-sizing text-sizing
        :render text-render} props)

  (-> (dyn :element)
      (dt/add-default-props props)
      (put-many :text text
                :lines (string/split "\n" text))))

(def ascii-tags
  @{:text {:f text
           :definite-sizing text-sizing
           :render text-render}
    :row {:f dt/row
          :definite-sizing def-siz/row-sizing
          :relative-sizing rel-siz/row-sizing}
    :block {:f dt/flow
            :relative-sizing rel-siz/block-sizing}})

(defn hiccup
  [_]
  [:row {}
   [:block {:weight 2}
    "hello1"]
   [:block {:weight 2}
    "hello2"]])

(def props @{})

(defn get-font
  []
  "lul")

(defn compile-tree
  [hiccup props &keys {:max-width max-width
                       :max-height max-height
                       :tags tags
                       :old-root old-root}]

  (let [to-init @[]]
    (put props :compilation/changed true)

    (with-dyns [:text/font "Poppins"
                :text/size 24
                :text/get-font get-font]
      # (print "compiling tree...")
      (def root #(test/timeit
        (ch/compile [hiccup props]
                    :tags tags
                    :element old-root
                    :to-init to-init)
        #)
)

      #(print "sizing tree...")
      (def root-with-sizes
        #(test/timeit
        (-> root
            (def-siz/set-definite-sizes max-width max-height)
            (rel-siz/set-relative-size max-width max-height))
        #)
)

      (put props :compilation/changed false)

      (ch/init-all to-init)

      root-with-sizes))

  #
)

(setdyn :pretty-format "%P")

(defn terminal-width
  []
  # dependent on tput
  (def p (os/spawn ["tput" "cols"] :p {:in :pipe :out :pipe})) # define core/process with selfpipe
  (def res (:read (p :out) :all)) # => prints the ls output
  (pp (:wait p))
  (pp res)
  (scan-number (slice res 0 -2)))

(def tree (compile-tree hiccup props
                        :max-width (terminal-width)
                        :max-height 30
                        :tags ascii-tags))
(ch/print-tree tree)

(var flow-render-children nil)

(defn noop
  [_ _ _])

(defn render
  [el x y]
  (def {:render-children render-children
        :render render}
    el)

  (default render noop)
  (default render-children flow-render-children)

  (render el x y)

  (render-children el
                   (+ (get-in el [:offset 3] 0) x)
                   (+ (get-in el [:offset 0] 0) y)))


(varfn flow-render-children
  [{:children children
    :layout/lines lines
    :f f}
   parent-x
   parent-y]

  (default lines [0 (length children)])

  (var line-start 0)
  (var y 0)

  (loop [line-end :in lines
         # probably good to re-add
         #:while (< (+ parent-y y) screen-h)
]
    #
    (def buf @"")
    (var line-h 0)
    (var x 0)

    (loop [i :range [line-start line-end]
           :let [c (children i)
                 {:width w
                  :height h} c]]
      (put c :left x)
      (put c :top y)

      (def buf2 @"")

      (with-dyns [:out buf2]
        (render c
                (+ x
                   parent-x)
                (+ y
                   parent-y)))

      (prin buf2)

      (buffer/push buf buf2)

      (+= x w)

      (loop [_ :range [0 (- x (length buf))]]
        # padding
        (prin " "))

      (set line-h (max line-h h)))

    (+= y line-h)

    (unless (= line-end (last lines))
      (print))

    (set line-start line-end)

    #
))


(render tree 0 0)
(print)
