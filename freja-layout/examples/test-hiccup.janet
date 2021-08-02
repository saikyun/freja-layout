(import ./compile-hiccup :as ch :fresh true)
(import ./sizing :as s :fresh true)
(import ./jaylib-sizing :as js :fresh true)
(import ./jaylib-rendering :as jr :fresh true)
(import ./assets :as a)
(import ./hiccup2 :as h)
(import freja/events :as e)
(import freja/frp)
(use freja/defonce)
(use freja-jaylib)

(setdyn :pretty-format "%.40M")

(defonce state1234 @{:cat "Truls"
                     :a 10})

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

(defn other-thing
  [props & children]
  (print "other thing")
  (ev/sleep 1)

  [:background {:color 0x00ff00ff}
   [:padding {:left 30 :top 20}
    [:clickable
     {:id "yeah"
      :on-click (comptime (fn [ev]
                            (e/put! state1234 :cat "Kebabsan")
                            (print "YEAAAH")))}
     "YEAH"]]])

(defn hiccup
  [props]
  #(pp props)

  [:padding {:top 30 :left 700}
   "habaaaoehcreohcaoehehlh"
   [:text {:size 40
           :text (props :cat)}]
   [:clickable {:id "cool"
                :on-click (comptime (fn [ev]
                                      (e/put! state1234 :cat "Wat")
                                      (e/put! state1234 :a "Wat")
                                      (print "hello")))}
    [:background {:color 0xff0000ff}
     "Cool"]]
   [other-thing {:a (props :a)}]
   [:block {} "hahaha"]
   "k"
   "meh"])


(defonce state123 @{})

(defn sleeper
  [props & children]
  #(ev/sleep 1) # SLEEP
  [:text {:text (if (props :pills)
                  (string/repeat "z" (props :pills))
                  "so tired")}])

(defn hiccup
  [props]
  [:padding {:top 30 :left 700}
   [:background {:color :green}
    [:block {}
     [:clickable {:on-click
                  (comptime (fn [ev]
                              (print "lul")
                              (tracev
                                (e/put! state123 :hour
                                        (math/floor (* 20000000 (math/random)))))))}
      "Change time soo\nbig wow watter "]
     "wat aoe aoe "
     (string (props :hour))]]

   [:background {:color :red}
    [:clickable {:on-click
                 (comptime (fn [ev]
                             (e/put! state123 :sleeping-pills
                                     (math/floor (+ 1 (* 10 (math/random)))))))}
     "Give sleeping pills "
     [sleeper {:pills (props :sleeping-pills)}]]]

   [:block {}]])

(comment
  (defn hiccup
    [props]
    (print "hiccup!!!")
    (pp props)
    [:padding {:top 30 :left 700}
     [:block {}
      "wat aoe aoe aoe "
      (string (props :hour))]
     [:background {:color :red}
      "aoe"]])
  #
)
(comment
  (e/put! state123 :hour
          (string/repeat "z" (math/floor (* 30 (math/random)))))

  #
)


(defn remove-keys
  [t ks]
  (def nt @{})
  (loop [[k v] :pairs t
         :when (not (ks k))]
    (put nt k v))
  nt)


(defn traverse-tree
  [f el]
  (f el)

  (loop [c :in (el :children)]
    (traverse-tree f c)))

(comment
  (traverse-tree
    |(-> (remove-keys $ {:children 1
                         :compilation/children 1})
         pp)
    (c :root))

  (pp (c :root))
  #
)

(defonce props @{:cat "Truls"})
(defonce el @{})
(ch/compile [hiccup props]
            :tags tags
            :element el)

#(comment
(def c (h/new-layer :test-layer
                    hiccup
                    state123
                    :render jr/render
                    :tags tags
                    :text/font "Poppins"
                    :text/size 24
                    :max-width (get-screen-width)
                    :max-height 600))
#
#)

