(import ../compile-hiccup :as ch)
(import ../default-tags :as dt)
(import ../jaylib-sizing :as js :fresh true)
(import ../jaylib-rendering :as jr)

(def tags @{:block @{:f dt/flow}
            :shrink @{:f dt/flow}
            :flow @{:f dt/flow}
            :clickable @{:f dt/clickable}
            :text @{:f dt/text
                    :definite-sizing js/text-sizing
                    :render jr/text-render}
            :align @{:f dt/align
                     #:sizing s/align-sizing
                     :render-children jr/align-render-children}
            :padding @{:f dt/padding}
            :row @{:f dt/row
                   # :definite-sizing ds/row-sizing
}
            :background @{:f dt/background
                          :render jr/background-render}})

(def render jr/render)
