(import ../compile-hiccup :as ch)
(import ../jaylib-sizing :as js :fresh true)
(import ../jaylib-rendering :as jr)

(def tags @{:block @{:f ch/block}
            :shrink @{:f ch/flow}
            :flow @{:f ch/flow}
            :clickable @{:f ch/clickable}
            :text @{:f ch/text
                    :definite-sizing js/text-sizing
                    :render jr/text-render}
            :align @{:f ch/align
                     #:sizing s/align-sizing
                     :render-children jr/align-render-children}
            :padding @{:f ch/padding}
            :row @{:f ch/row
                   # :definite-sizing ds/row-sizing
}
            :vertical @{:f ch/vertical}
            :background @{:f ch/background
                          :render jr/background-render}})

(def render jr/render)
