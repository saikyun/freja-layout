(import ./compile-hiccup :as ch)
(import ./sizing :as s)
(import ./jaylib-sizing :as js :fresh true)
(import ./jaylib-rendering :as jr)

(def tags @{:block @{:f ch/block}
            :clickable @{:f ch/clickable}
            :text @{:f ch/text
                    :sizing js/text-sizing
                    :render jr/text-render}
            :oneliner @{:f ch/text
                        :sizing js/oneliner-sizing
                        :render jr/oneliner-render}
            :align @{:f ch/align
                     :sizing s/align-sizing
                     :render-children jr/align-render-children}
            :padding @{:f ch/padding}
            :row @{:f ch/row}
            :vertical @{:f ch/vertical}
            :background @{:f ch/background
                          :render jr/background-render}})

(def render jr/render)
