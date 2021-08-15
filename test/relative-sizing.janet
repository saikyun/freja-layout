(use ../freja-layout/assert2)
(import ../freja-layout/compile-hiccup :prefix "" :fresh true)
(import ./test-tags :as jt :fresh true)
(import ../freja-layout/sizing/definite :as d :fresh true)
(import ../freja-layout/sizing/relative :prefix "" :fresh true)

(import freja/assets :as a)
(a/register-default-fonts)

(setdyn :pretty-format "%.40M")
(setdyn :text/get-font a/font)

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


### shrink + row


(let [el (compile [:background {:color :red}
                   [:shrink {}
                    [:row {}
                     [:flow {:weight 1}
                      [:align {:horizontal :left}
                       [:padding {:right 200}
                        "Open"]]]

                     [:flow {:weight 1}
                      "wat"]]]]
                  :tags jt/tags)
      with-sizes (d/set-definite-sizes el 200 600)
      with-sizes (set-relative-size el 200 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  # since the first child is bigger than the max-width
  # it will grow outside the bounds
  (assert2 (= 247 (el :width))))


(let [el (compile [:shrink {}
                   [:row {}
                    [:flow {:weight 1}
                     [:align {:horizontal :left}
                      [:padding {:right 100}
                       "Open"]]]

                    [:flow {:weight 1}
                     "wat"]]]
                  :tags jt/tags)
      with-sizes (d/set-definite-sizes el 200 600)
      with-sizes (set-relative-size el 200 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  # weight 1 on both children should mean a width of 100
  # but due to the padding being 100, plus the size of "Open"
  # the width grows bigger than that
  (assert2 (= 128 (get-in el [:children 0 :children 0 :width])))
  (assert2 (= 19 (get-in el [:children 0 :children 1 :width]))))


(let [el (compile [:row {}
                   [:flow {:weight 1}
                    [:align {:horizontal :left}
                     [:padding {:right 100}
                      "Open"]]]

                   [:flow {:weight 1}
                    "wat"]]
                  :tags jt/tags)
      with-sizes (d/set-definite-sizes el 200 600)
      with-sizes (set-relative-size el 200 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  # weight 1 on both children should mean a width of 100
  # but due to the padding being 100, plus the size of "Open"
  # the width grows bigger than that
  (assert2 (= 128 (get-in el [:children 0 :width])))
  # the second child gets the rest (lonely weight 1 of 72px = 72px)
  (assert2 (= 72 (get-in el [:children 1 :width]))))


(let [el (compile [:row {}
                   [:flow {:weight 1}]
                   [:flow {:width 1}]
                   [:flow {:weight 1}]]
                  :tags jt/tags)
      with-sizes (d/set-definite-sizes el 200 600)
      with-sizes (set-relative-size el 200 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  # even if children can't get even distribution of pixels
  # it should always add upp to the width
  (assert2 (= (el :width) (+ ;(map |($ :width) (el :children))))))


(let [el (compile [:row {}
                   [:flow {:weight 1}]
                   [:flow {:width 1}]
                   [:flow {:weight 4}]
                   [:flow {:width 2}]
                   [:flow {:weight 4}]
                   [:flow {:width 3}]
                   [:flow {:weight 9}]
                   [:flow {:width 4}]
                   [:flow {:weight 999}]
                   [:flow {:width 1}]]
                  :tags jt/tags)
      with-sizes (d/set-definite-sizes el 203 600)
      with-sizes (set-relative-size el 203 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  # even if children can't get even distribution of pixels
  # it should always add upp to the width
  (assert2 (= (el :width) (+ ;(map |($ :width) (el :children))))))


# testing `init`
(do (var outer-el nil)
  (let [to-init @[]
        el (compile [:flow {:init (fn [self ev]
                                    (set outer-el self))}]
                    :tags jt/tags
                    :to-init to-init)
        with-sizes (d/set-definite-sizes el 203 600)
        with-sizes (set-relative-size el 203 600)]

    (print-tree with-sizes)
    (assert2 (table? with-sizes))

    (init-all to-init)

    (assert2 (= outer-el el))))

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
