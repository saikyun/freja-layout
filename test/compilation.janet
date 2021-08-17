(use ../freja-layout/assert2)
(import ../freja-layout/compile-hiccup :prefix "" :fresh true)
(import ./test-tags :as jt :fresh true)
(import ../freja-layout/sizing/definite :as d :fresh true)
(import ../freja-layout/sizing/relative :prefix "" :fresh true)

(import freja/assets :as a)
(a/register-default-fonts)

(setdyn :pretty-format "%.40M")
(setdyn :text/get-font a/font)

# testing `function returning string`
(do (defn hello [props & _] "hello")
  (let [el (compile [:flow {} [hello {}]]
                    :tags jt/tags)
        with-sizes (d/set-definite-sizes el 203 600)
        with-sizes (set-relative-size el 203 600)]

    (print-tree with-sizes)
    (assert2 (table? with-sizes))

    (assert2 (= (hello nil) (get-in with-sizes [:children 0 :text])))))

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
