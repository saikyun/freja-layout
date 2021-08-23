(import ./default-tags :as dt :fresh true)
(import ./sizing/definite :as ds)
(import ./sizing/relative :as rel)
(import ./jaylib-sizing :as js :fresh true)
(import ./jaylib-rendering :as jr)

(def tags @{:block @{:f dt/flow
                     :relative-sizing rel/block-sizing}
            :shrink @{:f dt/flow
                      :relative-sizing rel/shrink-sizing}
            :flow @{:f dt/flow
                    :relative-sizing rel/flow-sizing}
            :clickable @{:f dt/clickable
                         :relative-sizing rel/flow-sizing}
            :text @{:f dt/text
                    :definite-sizing js/text-sizing
                    :render jr/text-render}
            :align @{:f dt/align
                     :relative-sizing rel/block-sizing
                     :render-children jr/align-render-children}
            :padding @{:f dt/padding
                       :definite-sizing ds/padding-sizing
                       :relative-sizing rel/padding-sizing}
            :row @{:f dt/row
                   :definite-sizing ds/row-sizing
                   :relative-sizing rel/row-sizing}
            :background @{:f dt/background
                          :render jr/background-render
                          :relative-sizing rel/flow-sizing}
            :event-handler @{:f dt/event-handler
                             :relative-sizing rel/flow-sizing}})

(def render jr/render)
