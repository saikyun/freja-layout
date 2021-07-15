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

  #  (e/put! my-props :zeds
  #         (string/repeat "z"
  #                        (math/floor (* 30 (math/random)))))
)

#(comment
(defn hiccup
  [props & children]
  #[:row {}
  #[:block {:weight 2}]
  #[:align {:horizontal :right}
  [:block {:width 300}
   [:background {:color 0x44ccccff}
    [:block {}
     [:padding {:all 5}
      # TODO: set aligning to width = 100%
      # TODO: fix rltranslatef for height
      "hello"
      [:align {:horizontal :right
               :width 180}
       [:background {:color 0x00ff00ff}
        [:padding {:left 15}
         [:clickable {:on-click sleep}
          [:background {:color 0xffffffcc}
           "how sleepy?\n(click here)"]]]]]
      (string (props :zeds))
      [:clickable {:on-click sleep}
       [:background {:color 0xffffff55}
        "how sleepy123?\n(click here)"]]
      #       
      #      "z"
      (string (props :zeds))]]]
   [:padding {:top 15}
    [:background {:color 0xcccc44ff}
     [:row {}
      [:background {:color 0x00ff00ff
                    :weight (props :weight)}
       [:padding {:all 3}
        [:oneliner {:text "hello"}]
        #[:align {:right true}
        #        [:text {:text "hej LUL"}]]
]]

      [:padding {:all 3
                 :weight 3}
       [:align {:horizontal :right}
        [:text {:text "hej2 ni"}]]]
      #"j haha XD"
]
     [:vertical {}
      # TODO: try vertical :)
]]]]
  #]
)

## TODO: fix offset-x problem
(defn hiccup
  [props]
  [:background {:color :red}
   [:row {}
    "how sleepy?\n(click here)"
    #[:block {}
     [:align {:horizontal :right}
      [:background {:color 0x00ff00ff}
       [:padding {:left 15}
        [:clickable {:on-click sleep}
         [:background {:color 0xffffffcc}

          "how sleepy?\n(click here)"]]]]]]]
#]
)

### TODO: fix this

(defn hiccup444444error
  [props]
  [:background {:color 0xcccc44ff}
   [:row {}
    [:background {:color 0x00ff00ff}
     [:oneliner {:text "aaohXDe 123 "}]]
    [:background {:color 0x00ff00ff}
     [:padding {:all 3}
      [:oneliner {:text "hello"}]
      #[:align {:right true}
      #        [:text {:text "hej LUL"}]]
]]

    [:padding {:all 3
               :weight 3}
     [:align {:horizontal :right}
      [:text {:text "hej2 ni"}]]]
    #"j haha XD"
]
   [:vertical {}
    # TODO: try vertical :)
]])


#)

(defn hiccup123
  [props & children]
  [:block {}
   "hej"])

(comment
  (import ./compile-hiccup :as ch :fresh true)

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

(def c (h/new-layer :test-layer2
                    hiccup
                    my-props
                    :render jt/render
                    :tags jt/tags
                    :text/font "Poppins"
                    :text/size 24
                    :max-width (get-screen-width)
                    :max-height 600))


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
