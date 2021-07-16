(import ./jaylib-tags :as jt :fresh true)
(import ./hiccup2 :as h)
(import freja/events :as e)
(use freja/defonce)
(use jaylib)

(setdyn :pretty-format "%.40M")

(defonce my-props @{})

(defn sleep
  [_ev] # we ignore the event
  (e/put! my-props :weight (* 10 (math/random)))

  (e/put! my-props :zeds
          (string/repeat "z"
                         (math/floor (* 30 (math/random))))))

(defn hiccup
  [props & children]
  [:block {:width 300}
   #[:background {:color 0x44ccccff}
   #   [:block {}
   [:padding {:all 5}
    "hello ueao ueoa ueoa"
    #      [:align {:horizontal :right}
    #       [:background {:color 0x00ff00ff}
    #        [:padding {:left 15}
    #         [:clickable {:on-click sleep}
    #          [:background {:color 0xffffffcc}
    #     "how sleepy?\n(click here)"]]]]]
    (string (props :zeds))
    [:clickable {:on-click (fn [& args]
                             (pp args)
                             (sleep ;args))}
     [:background {:color 0xffffff55}
      "how sleepy123?\n(click here)"]]
    #    (string (props :zeds))
] #]#]
   #   [:padding {:top 15}
   #    [:background {:color 0xcccc44ff}
   #     [:row {}
   #      [:background {:color 0x00ff00ff
   #                    :weight (props :weight)}
   #       [:padding {:all 3}
   #        [:oneliner {:text "hello"}]]]
   #
   #      [:padding {:all 3
   #                 :weight 3}
   #       [:align {:horizontal :right}
   #        [:text {:text "hej2 ni"}]]]]]]
])

(comment

  (import ./compile-hiccup :as ch :fresh true)

  (comment
    (h/remove-layer :test-layer2 nil)

    (ch/print-tree (c :root))
    #
)

  (import ./tests/test-sizing :as th :fresh true)

  (var t nil)

  (do
    (set t (th/hiccup->sized hiccup :log true))
    :ok)

  (def el (with-dyns [:text/font "Poppins"
                      :text/size 24]
            (ch/compile [hiccup {}]
                        :tags jt/tags
                        :element t)))

  (def root-with-sizes
    (with-dyns [:max-width (get-screen-width)
                :max-height 600
                :text/font "Poppins"
                :text/size 24
                :sized-width @{}
                :sized-height @{}]
      (s/apply-sizing el)))

  (ch/lul :a)
  (import ./sizing :as s)

  (do
    (def el (with-dyns [:text/font "Poppins"
                        :text/size 20]
              (ch/compile [hiccup my-props]
                          :tags jt/tags)))

    (def root-with-sizes
      (with-dyns [:max-width (get-screen-width)
                  :max-height 600
                  :text/font "Poppins"
                  :text/size 20
                  :sized-width @{}
                  :sized-height @{}]
        (s/apply-sizing el)))

    (def el (ch/compile [hiccup my-props]
                        :tags jt/tags
                        :element el))

    (ch/map-tree identity el))
  #
)

#(comment
(def c (h/new-layer :test-layer2
                    hiccup
                    my-props
                    :render jt/render
                    :tags jt/tags
                    :text/font "Poppins"
                    :text/size 24
                    :max-width (get-screen-width)
                    :max-height 600))
#)



#
#
#

(comment
  ## you can do the following to print the tree :)

  (import ../compile-hiccup :as ch)
  (ch/traverse-tree
    |(pp (ch/remove-keys $ {:children true
                            :compilation/children true}))
    (c :root))

  #
)
