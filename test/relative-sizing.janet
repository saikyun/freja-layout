(use ../freja-layout/assert2)
(use ../freja-layout/compile-hiccup)
(import ./test-tags :as jt)
(import ../freja-layout/sizing/definite :as d :fresh true)
(use ../freja-layout/sizing/relative)

(import ../freja-layout/assets :as a)
(a/register-default-fonts)

(setdyn :pretty-format "%.40M")

(put-in jt/tags [:flow :relative-sizing] flow-sizing)
(put-in jt/tags [:block :relative-sizing] block-sizing)
(put-in jt/tags [:padding :definite-sizing] d/padding-sizing)
(put-in jt/tags [:padding :relative-sizing] padding-sizing)
(put-in jt/tags [:row :definite-sizing] d/row-sizing)
(put-in jt/tags [:row :relative-sizing] row-sizing)
(put-in jt/tags [:background :relative-sizing] flow-sizing)

(let [el (compile [:flow {}
                   "hej"
                   [:block {}]
                   [:flow {:width 100 :height 100}]]
                  :tags jt/tags)
      with-sizes (d/set-definite-sizes el 800 600)
      with-sizes (set-relative-size el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  # size is 800 due to :block growing to max-width
  (assert2 (= (with-sizes :width) 800))

  # three lines since block becomes its own line
  (assert2 (= 3 (length (with-sizes :layout/lines)))))


(let [el (compile [:flow {}
                   "hej"
                   [:flow {:width 100 :height 100}]]
                  :tags jt/tags)
      with-sizes (d/set-definite-sizes el 800 600)
      with-sizes (set-relative-size el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  # width is the width of children
  (assert2 (= (with-sizes :width) 116))

  # three lines since block becomes its own line
  (assert2 (= 1 (length (with-sizes :layout/lines)))))


(let [el (compile [:padding {:left 500}
                   [:block {}]]
                  :tags jt/tags)
      with-sizes (d/set-definite-sizes el 800 600)
      with-sizes (set-relative-size el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  (assert2 (= 300 (get-in el [:children 0 :width])))

  (var all-have-size true)
  (d/traverse-render-tree |(set all-have-size (and all-have-size
                                                   ($ :width)
                                                   ($ :height)))
                          with-sizes)

  (assert2 all-have-size (print-tree with-sizes))

  # should be same when compiling again with caching
  (let [el (compile [:padding {:left 490 :right 10}
                     [:block {}]]
                    :tags jt/tags
                    :element el)
        with-sizes (d/set-definite-sizes el 800 600)
        with-sizes (set-relative-size el 800 600)]

    (print-tree with-sizes)
    (assert2 (table? with-sizes))

    (assert2 (= 300 (get-in el [:children 0 :width])))

    (var all-have-size true)
    (d/traverse-render-tree |(set all-have-size (and all-have-size
                                                     ($ :width)
                                                     ($ :height)))
                            with-sizes)

    (assert2 all-have-size (print-tree with-sizes))))


(let [el (compile [:padding {:left 500}
                   [:row {}
                    [:block {}
                     "a"]
                    [:block {:weight 1}]]]
                  :tags jt/tags)
      with-sizes (d/set-definite-sizes el 800 600)
      with-sizes (set-relative-size el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes)))



(put-in jt/tags [:shrink :relative-sizing] shrink-sizing)

(let [el (compile [:padding {:left 500}
                   [:shrink {}
                    [:block {}
                     "hello"]
                    [:block {:width 100}]]]
                  :tags jt/tags)
      with-sizes (d/set-definite-sizes el 800 600)
      with-sizes (set-relative-size el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  # shrinks to biggest child width
  (assert2 (= 100 (get-in with-sizes [:children 0 :width]))))


(let [el (compile [:padding {:left 500}
                   [:shrink {}
                    [:block {}
                     "hello"]
                    [:block {:width 10}]]]
                  :tags jt/tags)
      with-sizes (d/set-definite-sizes el 800 600)
      with-sizes (set-relative-size el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  # shrinks to biggest child width ("hello" in this case)
  (assert2 (= 26 (get-in with-sizes [:children 0 :width]))))


(let [el (compile
           [:shrink {}
            [:padding {:top 6 :bottom 6}
             "a"]
            [:block {}]]
           :tags jt/tags)
      with-sizes (d/set-definite-sizes el 800 600)
      with-sizes (set-relative-size el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  # height equal to the padding-part, since the block has 0 height
  (assert2 (= (get-in with-sizes [:children 0 :height])
              (with-sizes :height))))


#### TEXT

(let [el (compile
           [:background {:color 0x00ff00ff}
            "a"]
           :tags jt/tags)
      with-sizes (d/set-definite-sizes el 800 600)
      with-sizes (set-relative-size el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  # height equal to the padding-part, since the block has 0 height
  (assert2 (= (get-in with-sizes [:children 0 :height])
              (with-sizes :height))))


#
#
#
#
#
# just something random
#

(let [v (math/floor (inc (* 20 (math/random))))]
  (print (string/repeat ":) " v))
  (when (= v 20)
    (print "You rock!")))
