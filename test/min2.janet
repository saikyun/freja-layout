(import ../freja-layout/jaylib-tags :as jt)
(import ../freja-layout/sizing/relative :as rs)
(import freja/hiccup :as h)
(import freja/events :as e)
(use freja/defonce)
(use freja-jaylib)

(setdyn :pretty-format "%.40M")

(defonce my-props @{})

(defn list123
  [props & _]

  [:block {}
   ;(seq [_ :range [0 100]]
      [:row {}
       [:background {:weight nil :color :blue}
        [:padding {:all 10}
         [:clickable {:on-click |(do (pp $)
                                   (e/put! (props :p) :a 10))}
          [:block {} "Open"]]]]
       [:background {:weight 1 :color :green}
        [:block {:weight 1}
         [:background {:color :orange}
          [:align {:horizontal :right}
           "Ctrl+O"]]]]])])

(defn inline
  [props & _children]
  (def w 100)
  (def h 50)
  (tracev
    (merge-into (dyn :element)
                @{:render (fn [{:width w :height h} x y]
                            (draw-rectangle 0 0 w h :yellow))
                  :relative-sizing rs/block-sizing
                  :children []
                  :preset-width (tracev w)
                  :preset-height h
                  :props {:width w :height h}})))

(defn hiccup
  [props & children]
  [:event-handler {:on-event (fn [self ev] (pp ev))}
   [:padding {:left 600 :top 30}
    #"hej"
    #[:block {}]

    [inline {}]

    [:background {:color :green}
     [:shrink {}
      [:row {}
       [:block {:weight 1}
        "a"]
       [:block {:width 100}
        [:align {:horizontal :left}
         "b"]]]]]
    [:block {}]
    [:shrink {}
     [:row {}
      [:background {:weight nil :color :pink}
       [:padding {:all 10}
        [:clickable {:on-click |(do (pp $)
                                  (e/put! props :a 10))}
         [:block {} "Open"]]]]

      [:background {:weight 1 :color :orange}
       [:block {}
        [:align {:horizontal :right}
         "Ctrl+OOOxdO"]]]]
     [:row {}
      [:background {:weight nil :color :pink}
       [:padding {:all 10}
        [:clickable {:on-click |(do (pp $)
                                  (e/put! props :a 10))}
         [:block {} "Open"]]]]

      [:background {:weight 1 :color :orange}
       [:block {}
        [:align {:horizontal :right}
         "Ctrl+O"]]]]]

    [:block {}]

    [:background {:color :red}

     [:block {}
      [:row {}
       [:background {:weight nil :color :pink}
        [:padding {:all 10}
         [:clickable {:on-click |(do (pp $)
                                   (e/put! props :a 10))}
          [:block {} "Open YEAH"]]]]

       [:background {:weight 1 :color :orange}
        [:block {}
         [:align {:horizontal :right}
          "Ctrl"]]]]

      [list123 {:p props}]]]]])


(comment
  (import ./compile-hiccup :as ch :fresh true)
  (import ./sizing/definite :as ds :fresh true)
  (import ./sizing/relative :as rs :fresh true)

  (let [el (ch/compile [hiccup my-props]
                       :tags jt/tags)
        el (ds/set-definite-sizes el 800 600)
        el (rs/set-relative-size el 800 600)]
    (ch/print-tree el))
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

