(import ./compile-hiccup :as ch)
(import jaylib)
(import ./assets :as a)

(defmacro eol
  []
  ~(do (-= x space-w) # remove the size of the space
     (set w (max w x))
     (set x 0)
     (+= h (* line-height lh))
     (array/push line-ys h)
     (array/push new-lines current-line)
     (set current-line @"")))

(defn text-sizing
  ``
By default, the minimal width of a text is
the width of the biggest word. This means sentences will be wrapped,
but words won't be broken up.

To add no word wrapping, one could add a "no-break" option.
``
  [el]
  (def {:lines lines
        :font font
        :size size
        :max-width max-width
        :spacing spacing
        :line-height line-height} el)

  (default max-width (dyn :max-width))

  (def line-ys (array/new (length lines)))
  (array/push line-ys 0)

  ## TODO: need to word wrap

  (var w 0)
  (var h 0)
  (var x 0)
  (var lh 0)

  (def new-lines @[])
  (var current-line @"")

  (def [space-w _] (jaylib/measure-text-ex (a/font font size) " " size spacing))

  (each l lines
    (let [words (string/split " " l)]
      (each word words
        (let [[ww wh] (jaylib/measure-text-ex (a/font font size) word size spacing)]
          (when (and (pos? x) (> (+ ww x) max-width))
            # if we end up here, a line was too long
            (eol))

          (unless (empty? current-line)
            (buffer/push-string current-line " "))

          (buffer/push-string current-line word)

          (set lh (max wh lh))
          (+= x ww)
          (+= x space-w))))
    # here is just end of line due to a newline character
    (eol))

  (comment
    (array/push new-lines current-line)
    (+= h (* line-height lh))
    (set w (max w x)))

  #  (+= h (* line-height (min 0 (dec (length lines)))))

  (put (dyn :sized-width) el w)
  (put (dyn :sized-height) el h)

  (ch/put-many
    el
    :line-ys line-ys
    :lines new-lines
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
