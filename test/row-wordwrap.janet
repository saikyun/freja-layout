(import ../freja-layout/jaylib-tags :as jt)
(import ../freja-layout/sizing/relative :as rs)
(import freja/hiccup :as h)
(import freja/events :as e)
(use freja/defonce)
(use freja-jaylib)

(defonce my-props @{})

(defn hiccup
  [props & children]
  [:padding {:left 500
             :top 30}
   [:background {:color :green}
    [:row {}
     [:block {}
      "hello"]
     [:block {:weight 1}
      "right yeah that is not ok anytime whatever man"]]]])

(comment
  (import ../freja-layout/compile-hiccup :as ch :fresh true)
  (import ../freja-layout/sizing/definite :as ds :fresh true)
  (import ../freja-layout/sizing/relative :as rs :fresh true)

  (let [el (ch/compile [hiccup my-props]
                       :tags jt/tags)
        el (ds/set-definite-sizes el 800 600)
        el (rs/set-relative-size el 800 600)]
    (ch/print-tree el))

  (import freja/assets :as a)

  (with-dyns [:text/get-font a/font]
    (def root
      (ch/compile [hiccup my-props]
                  :tags jt/tags))

    (def root-with-sizes
      (-> root
          (ds/set-definite-sizes (get-screen-width) 600)
          (rs/set-relative-size (get-screen-width) 600)))

    root-with-sizes)

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

