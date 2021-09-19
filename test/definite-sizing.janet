(use ../freja-layout/assert2)
(use ../freja-layout/compile-hiccup)
(import ./test-tags :as jt :fresh true)
(import ../freja-layout/sizing/definite :prefix "" :fresh true)
(import freja/assets :as a)

(a/register-default-fonts)
(setdyn :text/get-font a/font)

(setdyn :pretty-format "%.40M")


# basic test
(let [el (compile [:block {}
                   "hej"]
                  :tags jt/tags)
      with-sizes (set-definite-sizes el 800 600)]
  (assert2 (table? el))

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  #(print-tree (get-in with-sizes [:children 0]))
  (let [c (get-in with-sizes [:children 0])
        {:width w :height h} c]
    (assert2 (and (= w 17) (= h 14)) (pp c))))


(put-in jt/tags [:padding :definite-sizing] padding-sizing)

### PADDING test

(let [el (compile [:padding {:left 10 :right 5
                             :top 25
                             :bottom 20}
                   [:block {}
                    "hej"]]
                  :tags jt/tags)
      with-sizes (set-definite-sizes el 800 600)]

  (print "padding")
  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  # width is max-width - left - right
  (assert2 (= 555 (with-sizes :content-max-height)))

  # height is max-height - top - bottom
  (assert2 (= 785 (with-sizes :content-max-width))))


(put-in jt/tags [:row :definite-sizing] row-sizing)

### ROW test

(let [el (compile [:row {}
                   [:block {:width 100} "hej pa dig"]
                   [:block {:weight 1}
                    [:padding {:left 200}]]
                   [:block {:weight 2}]]
                  :tags jt/tags)
      with-sizes (set-definite-sizes el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes)))

(let [el (compile [:row {}
                   [:block {:width 100} "hej pa dig"]
                   [:block {:weight 1}
                    [:padding {}
                     [:block {} "hej"]]]
                   [:block {:weight 2}]]
                  :tags jt/tags)
      with-sizes (set-definite-sizes el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  (assert2 (not (get-in el [:children 1 :width]))
           (print-tree (get-in el [:children 1])))

  (assert2 (= 117 (el :min-width))))


(let [el (compile [:row {}
                   [:block {:width 100} "hej pa dig"]
                   [:block {:weight nil}
                    [:padding {:right 300}
                     [:block {} "hej"]]]
                   [:block {:weight 2}]]
                  :tags jt/tags)
      with-sizes (set-definite-sizes el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes)))

# TODO: add assertions about no fraction
(let [el (compile [:row {}
                   [:block {:weight nil}
                    [:block {} "hej"]]
                   [:block {:weight 1}
                    "wat"]
                   [:block {:weight 2}
                    "wat2"]]
                  :tags jt/tags)
      with-sizes (set-definite-sizes el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes)))


(let [el (compile [:row {}
                   [:block {:weight 1}
                    [:block {} "hej"]]
                   [:block {:weight 1}
                    "wat2 ntoseuha untsehoa sntueh oantsu hentsoa huntseoa hnsuteo"]]
                  :tags jt/tags)
      with-sizes (set-definite-sizes el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes)))

(let [el (compile [:column {}
                   [:block {:weight 1}
                    [:block {} "hej"]]
                   [:block {:weight 1}
                    "wat2 ntoseuha untsehoa sntueh oantsu hentsoa huntseoa hnsuteo"]]
                  :tags jt/tags)
      with-sizes (set-definite-sizes el 800 600)]

  (print-tree with-sizes)
  (assert2 (table? with-sizes))

  (let [c (get-in with-sizes [:children 0])
        {:content-max-height mh} c]
    (assert2 (= mh 300) (pp c)))

  (let [c (get-in with-sizes [:children 1])
        {:content-max-height mh} c]
    (assert2 (= mh 300) (pp c))))
