(import ../jaylib-tags :as jt :fresh true)
(import ../hiccup2 :as h)
(import freja/events :as e)
(use freja/defonce)
(use jaylib)

(setdyn :pretty-format "%.40M")

(defonce my-props @{})

(defn sleep
  [_ev] # we ignore the event
  (e/put! my-props :zeds
          (string/repeat "z"
                         (math/floor (* 30 (math/random))))))


(defn hiccup
  [props]
  [:padding {:top 35 :left 700 :right 5}
   [:background {:color 0x44ccccff}
    [:clickable {:on-click sleep}
     [:block {}
      [:padding {:all 5}
       [:background {:color 0xffffff55}
        "how sleepy?\n(click here)"]]
      (string (props :zeds))]]]])

(def c (h/new-layer :test-layer
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
