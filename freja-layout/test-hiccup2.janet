(import ./jaylib-tags :as jt :fresh true)
(import ./hiccup2 :as h)
(import freja/events :as e)
(use freja/defonce)
(use freja-jaylib)

(setdyn :pretty-format "%.40M")

(defonce my-props @{})

(defn hiccup
  [props]
  [:padding {:top 30 :left 700}
   [:block {}
    "how sleepy? "
    (string (props :zeds))]])

(comment
  (e/put! my-props :zeds
          (string/repeat "z" (math/floor (* 30 (math/random)))))

  #
)

(def c (h/new-layer :test-layer
                    hiccup
                    my-props
                    :render jt/render
                    :tags jt/tags
                    :text/font "Poppins"
                    :text/size 24
                    :max-width (get-screen-width)
                    :max-height 600))
