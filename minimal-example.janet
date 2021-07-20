(import ./jaylib-tags :as jt :fresh true)
(import ./hiccup2 :as h)
(import freja/events :as e)
(use freja/defonce)
(use jaylib)

(use profiling/profile)

(comment
  (print-results)

  #
)

(setdyn :pretty-format "%.40M")

(defonce my-props @{})

(defn sleep
  [_ev] # we ignore the event
  (e/put! my-props :weight (* 10 (math/random)))
  (e/put! my-props :zeds
          (string/repeat "z"
                         (math/floor (* 30 (math/random))))))

(defn bg
  [props & children]
  [:background {:color 0x00ff0033
                :weight (props :weight)}
   [:padding {:right 0}
    [:background (struct :color 0x00ff00ff
                         ;(flatten (pairs props)))
     [:padding {:all 0}
      [:block {}
       ;children]]]]])

(defn list123
  [props & _]

  [:block {}
   ;(seq [_ :range [0 10]]
      [:row {}
       [:background {:weight nil :color :blue}
        [:padding {:right 10}
         [:clickable {:on-click |(do (pp $)
                                   (e/put! (props :p) :a 10))}
          [:block {} "Open"]]]]
       [:background {:weight 1 :color :green}
        [:block {:weight 1}
         [:background {:color :orange}
          [:align {:horizontal :right}
           "Ctrl+O"]]]]])])


(defn hiccup
  [props & children]
  [:padding {:left 600 :top 30}
   #"hej"
   #[:block {}]
   [:background {:color :red}
    [:block {:max-width 0}
     "a"

     [list123 {:p props}]

     [:row {}
      [:background {:weight nil :color :pink}
       [:padding {:right 10}
        [:block {} "Open"]]]
      [:background {:weight 1 :color :orange}
       [:block {}
        [:align {:horizontal :right}
         "Ctrl+OOOxdO"]]]]]]])

(comment

  [:row {}
   [:background {:weight nil
                 :color :blue}
    [:block {} "Open"]]
   [:background {:weight 1 :color :green}
    [:block {:weight 1}
     [:align {:horizontal :right}
      "Ctrl+O"]]]]
  [:row {}
   [:background {:weight 1 :color :pink}
    [:block {:weight 1} "Open"]]
   [:background {:weight 1 :color :orange}
    [:block {:weight 1}
     [:align {:horizontal :right}
      "Ctrl+OO"]]]]

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
