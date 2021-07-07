(import ../compile-hiccup :as ch :fresh true)
(import ../sizing :as s :fresh true)
(import ../jaylib-sizing :as js :fresh true)
(import ../jaylib-rendering :as jr :fresh true)
(import ../assets :as a)
(import freja/frp)
(use jaylib)

(setdyn :pretty-format "%.40M")

(def tags @{:block @{:f ch/block}
            :text @{:f ch/text
                    :sizing js/text-sizing
                    :render jr/text-render}
            :padding @{:f ch/padding}
            :row @{:f ch/row}
            :vertical @{:f ch/vertical}
            :background @{:f ch/background
                          :render jr/background-render}})

(do
  (def hiccup [:block {} [:text {:size 20} "Hello sogaiu"]])
  #=> (:block {} (:text {:size 20} "Hello sogaiu"))
  (def element (with-dyns [# tags map e.g. :text to relevant rendering function
                           :tags tags
                           # default font
                           :text/font "Poppins"]
                 (ch/compile hiccup)))
  #=>
  ``
  {:children @[
    @{:children ()
      :color 255
      :f <function text>
      :font "Poppins"
      :line-height 1
      :lines @["Hello sogaiu"]
      :props {:size 20}
      :render <function text-render>
      :size 20
      :sizing <function text-sizing>
      :spacing 2
      :tag :text
      :text "Hello sogaiu"}]
  :f <function block>
  :props {}
  :sizing :expand-w
  :tag :block}
``

  (def element-with-size
    (with-dyns [:max-width 800
                :max-height 600]
      (s/apply-sizing element)))
  #=>
  ``
  @{:children @[
    @{:children ()
      :color 255
      :f <function text>
      :font "Poppins"
      :height 20                       # calculated height of :text
      :line-height 1
      :line-ys @[0 20]
      :lines @["Hello sogaiu"]
      :props {:size 20}
      :render <function text-render>
      :size 20
      :sizing <function text-sizing>
      :spacing 2
      :tag :text
      :text "Hello sogaiu"
      :width 103}]                     # calculated width of :text
  :content-width 800                   # inner width of :block
  :f <function block>
  :height 20                           # :block height wraps children
  :props {}
  :sizing :expand-w
  :tag :block
  :width 800}                          # :block gets max-width
``

  # now it's ready for rendering!
  # positioning is done based off of
  # data in the element e.g. :content-width and
  # the :width of children are used for wrapping
  #
  #(render element-with-size)
)
