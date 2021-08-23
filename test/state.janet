(use ../freja-layout/assert2)
(import ../freja-layout/compile-hiccup :prefix "" :fresh true)
(import ./test-tags :as jt :fresh true)
(import ../freja-layout/sizing/definite :as d :fresh true)
(import ../freja-layout/sizing/relative :prefix "" :fresh true)

(import freja/assets :as a)
(a/register-default-fonts)

(setdyn :pretty-format "%p")
(setdyn :text/get-font a/font)

# check that going from many children to fewer works

(let [to-init @[]
      hiccup (defn top [props & _]
               [:block {}
                "hej"
                (case (props :cool)
                  true "no")])
      el (-> (compile [hiccup {:cool true}]
                      :tags jt/tags)
             (d/set-definite-sizes 203 600)
             (set-relative-size 203 600))

      el (with-dyns [:freja/log false]
           (-> (compile [hiccup {:cool false}] # new props
                        :tags jt/tags
                        :element el)
               (d/set-definite-sizes 203 600)
               (set-relative-size 203 600)))]

  #(print-tree el)
  (assert2 (table? el))

  # when cool is false, only "hej" should exist as child
  (assert2 (= 1 (length (get-in el [:children])))))

# testing `init`
(do (var outer-el nil)
  (let [to-init @[]
        el (compile [:flow {:init (fn [self ev]
                                    (set outer-el self))}]
                    :tags jt/tags
                    :to-init to-init)
        with-sizes (d/set-definite-sizes el 203 600)
        with-sizes (set-relative-size el 203 600)]

    #(print-tree with-sizes)
    (assert2 (table? with-sizes))

    (init-all to-init)

    (assert2 (= outer-el el))))


(do (var nof-inits 0)
  (let [to-init @[]
        hiccup (defn top [props & _]
                 [:block {}
                  [:flow {:init (fn [self ev]
                                  # should run once since it is has same child index
                                  (++ nof-inits)
                                  #(print "initing!")
)}]])
        el (->
             (compile [hiccup @{}]
                      :tags jt/tags
                      :to-init to-init)
             (d/set-definite-sizes 203 600)
             (set-relative-size 203 600))

        _ (init-all to-init)

        _ (array/clear to-init)

        el (with-dyns [:freja/log false]
             (-> (compile [hiccup @{}] # new props
                          :tags jt/tags
                          :element el
                          :to-init to-init)
                 (d/set-definite-sizes 203 600)
                 (set-relative-size 203 600)))]

    #(print-tree el)
    (assert2 (table? el))

    (init-all to-init)

    (assert2 (= nof-inits 1) (print "nof inits is: " nof-inits))))


(do (var nof-inits 0)
  (let [to-init @[]
        props @{:extra-child nil}
        hiccup (fn [props & _]
                 [:flow {}
                  # do splicing to not get `nil`. nil is ok to have as child
                  # but then order won't be changed, which we want for this test
                  (props :extra-child)
                  [:flow {:init (fn [self ev]
                                  # will run twice due to no key set
                                  (++ nof-inits)
                                  # (print "initing!")
)}]])
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

    #(print-tree with-sizes)
    (assert2 (table? with-sizes))

    (init-all to-init)

    (assert2 (= nof-inits 2))))

# keyed elements should keep their state (e.g. not init twice)

(do
  (var nof-inits 0)
  (let [to-init @[]
        hiccup (defn top [props & _]
                 [:block {}
                  ;(if (props :yeah) ["yeah"] [])
                  [:flow {:key :thing
                          :init (fn [& _]
                                  (print "initing")
                                  (++ nof-inits))}]])

        el (-> (compile [hiccup {:yeah true}]
                        :tags jt/tags
                        :to-init to-init)
               (d/set-definite-sizes 203 600)
               (set-relative-size 203 600))

        _ (init-all to-init)

        to-init @[]
        el (with-dyns [:freja/log false]
             (-> (compile [hiccup {:yeah false}] # new props
                          :tags jt/tags
                          :element el
                          :to-init to-init)
                 (d/set-definite-sizes 203 600)
                 (set-relative-size 203 600)))]

    (init-all to-init)

    #(print-tree el)
    (assert2 (table? el))

    (assert2 (one? nof-inits))))

#
#
#
#
#
# just something random
#

(comment
  (let [v (math/floor (inc (* 20 (math/random))))]
    (print (string/repeat ":) " v))
    (when (= v 20)
      (print "You rock!")))
  #
)
