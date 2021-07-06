(import ./compile-hiccup :as ch)
(import ./sizing :as s :fresh true)
(import ./jaylib-sizing :as js :fresh true)

(setdyn :pretty-format "%.40M")


(def tags @{:block @{:f ch/block}
            :text @{:f ch/text
                    :sizing js/text-sizing}
            :padding @{:f ch/padding}
            :background @{:f ch/background}})


(def el
  (tracev
    (with-dyns [:tags tags
                :text/font "Poppins"]
      (ch/compile [:block {:width 100}
                   [:background {:color 0x00ff00ff}
                    [:padding {:left 30}
                     [:block {} "dog"]
                     "hej"]]]))))


(tracev
  (with-dyns [:max-width 400
              :max-height 800]
    (s/apply-sizing el)))
