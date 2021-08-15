(use ../freja-layout/assert2)
(import ../freja-layout/compile-hiccup :prefix "" :fresh true)
(import ./test-tags :as jt :fresh true)
(import ../freja-layout/sizing/definite :as d :fresh true)
(import ../freja-layout/sizing/relative :prefix "" :fresh true)

(import freja/assets :as a)
(a/register-default-fonts)

(setdyn :pretty-format "%.40M")
(setdyn :text/get-font a/font)

# testing `init`
(do (var outer-el nil)
  (let [to-init @[]
        state @{}
        el (compile [:flow {:state state
                            :init (fn [self ev]
                                    (set outer-el self))}]
                    :tags jt/tags
                    :to-init to-init)
        with-sizes (d/set-definite-sizes el 203 600)
        with-sizes (set-relative-size el 203 600)]

    (print-tree with-sizes)
    (assert2 (table? with-sizes))

    (init-all to-init)

    (assert2 (= outer-el el))))


(do (var nof-inits 0)
  (let [to-init @[]
        props @{:extra-child nil}
        state @{}
        hiccup (fn [props & _]
                 [:flow {}
                  (props :extra-child)
                  [:flow {:state state
                          :init (fn [self ev]
                                  # should only run once
                                  (++ nof-inits)
                                  (print "initing!"))}]])
        el (compile [hiccup props]
                    :tags jt/tags
                    :to-init to-init)
        with-sizes (d/set-definite-sizes el 203 600)
        with-sizes (set-relative-size el 203 600)

        _ (put props :extra-child [:block {} "yeah!"])

        el (compile [hiccup props]
                    :tags jt/tags
                    :to-init to-init)
        with-sizes (d/set-definite-sizes el 203 600)
        with-sizes (set-relative-size el 203 600)]

    (print-tree with-sizes)
    (assert2 (table? with-sizes))

    (init-all to-init)

    (assert2 (= nof-inits 1))))

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
