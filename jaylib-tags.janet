(import ./compile-hiccup :as ch)
(import ./jaylib-sizing :as js)
(import ./jaylib-rendering :as jr)

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

(def render jr/render)