(import ./compile-hiccup :as ch :fresh true)
(import ./sizing :as s :fresh true)
(import ./jaylib-sizing :as js :fresh true)
(import ./jaylib-rendering :as jr :fresh true)
(import ./assets :as a)
(import ./hiccup2 :as h)
(import freja/events :as e)
(import freja/frp)
(use jaylib)


(setdyn :pretty-format "%.40M")

(def tags @{:block @{:f ch/block}
            :clickable @{:f ch/clickable}
            :text @{:f ch/text
                    :sizing js/text-sizing
                    :render jr/text-render}
            :padding @{:f ch/padding}
            :row @{:f ch/row}
            :vertical @{:f ch/vertical}
            :background @{:f ch/background
                          :render jr/background-render}})

(defn hiccup
  [props]
  (pp props)

  [:padding {:top 30 :left 700}
   "habaaaoehcreohcaoehehlh"
   [:text
    {:size 40}
    (props :cat)]
   [:clickable {:id "cool"
                :on-click (fn [ev]
                            (e/put! props :cat "Wat")
                            (print "hello"))}
    [:background {:color 0xff0000ff}
     "Cool"]]
   [:background {:color 0x00ff00ff}
    [:padding {:left 30 :top 20}
     [:clickable
      {:id "yeah"
       :on-click (fn [ev]
                   (e/put! props :cat "Kebabsan")
                   (print "YEAAAH"))}
      "YEAH"]]]
   [:block {} "hahaha"]
   "k"
   "meh"])

(h/new-layer :test-layer
             hiccup
             @{:cat "Truls"}
             :render jr/render
             :tags tags
             :text/font "Poppins"
             :max-width 800
             :max-height 600)
