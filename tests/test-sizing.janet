(import ../sizing :as s :fresh true)
(import ../compile-hiccup :as ch :fresh true)
(import ../jaylib-tags :as jt :fresh true)
(use jaylib)

(setdyn :pretty-format "%.40M")

(def print-tree ch/print-tree)

(defn hiccup
  [_ & _]
  [:block {} "apahaha a"])

(def org-tree
  (with-dyns [:text/font "Poppins"]
    (ch/compile [hiccup @{}]
                :tags jt/tags)))

(def sized-tree
  (with-dyns [:max-width 0 #(get-screen-width)
              :max-height (get-screen-height)
              :sized-width @{}
              :sized-height @{}]
    (s/apply-sizing org-tree)))

(defn hiccup->sized
  [hc &keys {:max-width max-width
             :max-height max-height
             :log log}]
  (default max-width (get-screen-width))
  (default max-height (get-screen-height))

  (with-dyns [:freja/log log]
    (def hiccup
      (if (function? hc)
        hc
        (defn hiccup
          [_ & _]
          hc)))

    (def org-tree
      (with-dyns [:text/font "Poppins"]
        (ch/compile [hiccup @{}]
                    :tags jt/tags)))

    (when (dyn :freja/log)
      (print)
      (print "### compilation res")
      (print-tree org-tree))

    (def sized-tree
      (with-dyns [:max-width max-width
                  :max-height max-height
                  :sized-width @{}
                  :sized-height @{}]
        (s/apply-sizing org-tree)))

    (when (dyn :freja/log)
      (print)
      (print "### sizing res")
      (print-tree sized-tree))

    sized-tree))


## despite max-width being 0
# width ends up being 54
# due to text being as wide as
# smallest word
(let [hc [:block {} "apahaha a"]
      w ((hiccup->sized hc
                        :max-width 0
                        :log true)
          :width)]
  (assert (= 54 w)))


# :weight 1 in a row that has 0 max-width
# nets you 0 width.
(let [hc [:block {}
          [:row {}
           "apahaha a"
           [:text {:weight 1
                   :text "bbb"}]]]
      tree (hiccup->sized hc
                          :max-width 0
                          :log true)]
  (assert (= 54 (tree :width))))


# blocks grow to the maximal width
(let [hc [:block {}]
      tree (hiccup->sized hc
                          :max-width 500
                          :log true)]
  (assert (= 500 (tree :width))))

# rows with `:weight`ed children grow to the maximal width
(let [hc [:row {}
          [:text {:weight 1
                  :text "haha"}]]
      tree (hiccup->sized hc
                          :max-width 500
                          :log true)]
  (assert (= 500 (tree :width))))


# weighted children share the total size
# of the row, based on the ratio
# between their weights
(let [hc [:row {}
          # total weight is 1 + 3 = 4
          [:text {:weight 1 # first child's share is: 1 / 4
                  :text "haha"}]
          [:text {:weight 3 # second child's share:   3 / 4
                  :text "haha"}]]
      tree (hiccup->sized hc
                          :max-width 400
                          :log true)
      c0 (get-in tree [:children 0])
      c1 (get-in tree [:children 1])]
  (assert (= 400 (tree :width)))
  (assert (= 100 (c0 :width))) # 400 * (1 / 4) = 100
  (assert (= 300 (c1 :width)))) # 400 * (3 / 4) = 300



(let [hc [:background {:color :red}
          [:row {}
           "first line\nwatter"
           [:block {}
            [:background {:color 0x00ff00ff}
             [:padding {:left 15}
              [:clickable {:on-click print}
               [:background {:color 0xffffffcc}

                "how sleepy?\n(click here)"]]]]]]]
      tree (hiccup->sized hc
                          :max-width 500
                          :log true)]
  #  (assert (= 500 (tree :width)))
)
