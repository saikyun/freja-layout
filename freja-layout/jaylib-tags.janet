(import ./compile-hiccup :as ch)
(import ./sizing/definite :as ds)
(import ./sizing/relative :as rel)
(import ./jaylib-sizing :as js :fresh true)
(import ./jaylib-rendering :as jr)

(def tags @{:block @{:f ch/block
                     :relative-sizing rel/block-sizing}
            :shrink @{:f ch/flow
                      :relative-sizing rel/shrink-sizing}
            :flow @{:f ch/flow
                    :relative-sizing rel/flow-sizing}
            :clickable @{:f ch/clickable
                         :relative-sizing rel/flow-sizing}
            :text @{:f ch/text
                    :definite-sizing js/text-sizing
                    :render jr/text-render}
            :align @{:f ch/align
                     :relative-sizing rel/block-sizing
                     :render-children jr/align-render-children}
            :padding @{:f ch/padding
                       :definite-sizing ds/padding-sizing
                       :relative-sizing rel/padding-sizing}
            :row @{:f ch/row
                   :definite-sizing ds/row-sizing
                   :relative-sizing rel/row-sizing}
            :vertical @{:f ch/vertical}
            :background @{:f ch/background
                          :render jr/background-render
                          :relative-sizing rel/flow-sizing}})

(def render jr/render)
