(use ../freja-layout/compile-hiccup)
(use ../freja-layout/default-tags)

(setdyn :pretty-format "%.40M")


################### assertions
(use ../freja-layout/put-many)

(assert (deep= @{:a 10 :b 20} (put-many @{} :a 10 :b 20)))

(comment
  (assert (deep= (compile [text {} "Hej"]
                          :element @{})
                 (compile [text {} "Hej"]))))


(comment
  (with-dyns [:tags tags]
    (compile [:block {:width 100}
              [:background {:color 0x00ff00ff}
               [:padding {:left 30}
                [:block {:width 30}]
                "hej"]]])))


#
#
#
#
#
# trying to get caching to work


(assert (same? [:a {}]
               [:a {}]))
(assert (not (same? [:a {}]
                    [:b {}])))

# as long as number of children are the same
# the hiccup forms are considered to be the same
(assert (same? [:a {} "lul"]
               [:a {} "hej"]))

(let [props @{:haha true}]
  (assert (same? [:a props "lul"]
                 [:a props "lul"])))


(let [props @{:haha [:b {} "wat"]
              :x :ok}]
  (assert (same? [:a {:x (props :x)}
                  (props :haha)]
                 [:a {:x (props :x)}
                  (props :haha)])))

(let [props @{:haha [:b {} "wat"]
              :x :ok}
      f (fn [props & children]
          [:a {:x (props :x)}
           (props :haha)])
      e1 [f props]

      # to change props, create a new object
      props (merge-into @{}
                        props
                        @{:haha "nope"})
      e2 [f props]]
  (assert (not (same? e1 e2))))


# if only children change, but not the number
# of children, the hiccup is considered to be the same
(let [props @{:haha [:b {} "wat"]
              :x :ok}
      f (fn [props & children]
          [:a {:x (props :x)}
           (props :haha)
           ;children])
      e1 [f props [:a {}]]
      e2 [f props [:a {}]]]
  (assert (same? e1 e2)))

#
###
##
#
#



(defn q
  [props & children]
  #(print "q")
  #(pp props)
  (-> (dyn :element)
      (add-default-props props)))


(defn a
  [props & children]
  #(print "a")
  #(pp props)
  (-> (dyn :element)
      (add-default-props props)))

(defn b
  [props & children]
  #(print "a")
  #(pp props)
  [a props])

(defn c
  [props & children]
  #(print "a")
  #(pp props)
  [b props])

(defn thing
  [props & children]
  [q {:cat (props :size)}
   ;children])

(defn child
  [props & children]
  (print "child")
  [c {:size :child-thing}
   [a {:size :lllllllllllol}]])
(comment
  (import spork/test)

  (def props @{:size 1337
               :size2 123})

  (print)
  (print "step1")

  (def hc123 [thing props
              [child {:size-child (props :size)}
               [a {}] [a props]]])

  (defmacro hc
    []
    ~[thing props
      [child {:outer-props :outer}]])

  (defmacro hc
    []
    ~[thing props
      [c {:outer-props (props :size2)}]])

  (def el #(test/timeit
    (compile (hc)
             :tags @{})) #)
  #(pp el)


  (def props @{:size 0 :size2 0})

  (print)
  (print "step2")
  (def el
    #(test/timeit
    (compile (hc)
             :element el
             :tags tags)) #)

  (defn print-and-destroy-tags-and-children
    [el]
    (traverse-tree
      |(keep-keys $ {:compilation/children 1
                     :children 1
                     :inner/element 1
                     :tag 1
                     :f 1})
      el)

    (pp el))

  (defn print-and-destroy-no-inner
    [el]
    (traverse-tree
      |(keep-keys $ {:children 1
                     :tag 1
                     :f 1})
      el)

    (pp el)))
