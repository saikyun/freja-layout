(use ../freja-layout/assert2)
(use ../freja-layout/compile-hiccup)
(import ../freja-layout/default-tags :as dt :fresh true)
(import ./test-tags :as jt :fresh true)
(import ../freja-layout/sizing/definite :as d :fresh true)
(import ../freja-layout/sizing/relative :prefix "" :fresh true)

(import freja/assets :as a)
(a/register-default-fonts)

(use profiling/profile)

(setdyn :pretty-format "%.40M")
(setdyn :text/get-font a/font)

(reset-profiling!)

(def props @{})

(defn inner-inner
  [props & _]
  (def {:state state
        :text/color text/color
        :text/size text/size
        :text/font text/font
        :text/line-height text/line-height
        :text/spacing text/spacing
        :show-line-numbers show-line-numbers} props)

  (default text/size (dyn :text/size 14))
  (default text/font (dyn :text/font "Poppins"))
  (default text/line-height (dyn :text/line-height 1))
  (default text/spacing (dyn :text/spacing 1))
  (default text/color (dyn :text/color 0x000000ff))

  (put-in state [:gb :text/size] text/size)
  (put-in state [:gb :text/font] text/font)
  (put-in state [:gb :text/line-height] text/line-height)
  (put-in state [:gb :text/spacing] text/spacing)
  (put-in state [:gb :text/color] text/color)
  (put-in state [:gb :show-line-numbers] show-line-numbers)

  #(put-in state [:gb :changed] true)

  (when show-line-numbers
    (put-in state [:gb :offset] [12 0]))

  (-> (dyn :element)
      (dt/add-default-props props)
      (merge-into
        @{:children []
          :relative-sizing
          (defn textarea-sizing [el max-width max-height]
            # TODO: something strange happens when width / height is too small
            # try removing 50 then resize to see
            (-> el
                (put :width (max 50 (or (el :preset-width) max-width)))
                (put :height (max (get-in state [:gb :conf :size] 0)
                                  (or (el :preset-height) max-height)))
                (put :content-width (el :width))
                (put :layout/lines nil))

            (def [old-w old-h] (get-in state [:gb :size] [0 0]))

            (unless (and (= old-w (el :width))
                         (= old-h (el :height)))
              (put-in state [:gb :size]
                      [(math/floor (el :width))
                       (math/floor (el :height))])
              (put-in state [:gb :changed] true)
              (put-in state [:gb :resized] true))

            el)

          :render (fn [self]
                    #                    (print "text area render")
                    (:draw state)
                    #(pp (get-in state [:gb :text]))
)

          :on-event (fn [self ev]
                      #(pp self)
                      #(print "start " (state :id))

                      #(tracev [(dyn :offset-x) (dyn :offset-y)])

                      (defn update-pos
                        [[x y]]
                        [(- x
                            (dyn :offset-x 0))
                         (- y
                            (dyn :offset-y 0))])

                      (def new-ev (if (= (first ev) :scroll)
                                    [(ev 0)
                                     (ev 1)
                                     (update-pos (ev 2))]
                                    [(ev 0)
                                     (update-pos (ev 1))]))

                      #(text-area-on-event state new-ev)
                      (:on-event state new-ev)

                      (def pos (new-ev
                                 (if (= :scroll (first new-ev))
                                   2
                                   1)))

                      (when (dt/in-rec? pos
                                        0
                                        0
                                        (self :width)
                                        (self :height))
                        true))})))

(defn default-textarea-state [& args]
  @{})

(def file-open-binds @{})
(def search-binds @{})

(defn inner
  [props & _]
  (def {:open open
        :set-open set-open
        :state state
        :initial-path initial-path
        :id id} props)

  (assert state "Must define :state")

  (unless (state :file-open)
    (put state :file-open (default-textarea-state :binds file-open-binds)))

  (unless (state :search)
    (put state :search (default-textarea-state :binds search-binds)))

  (unless (state :editor)
    (put state :editor (default-textarea-state))

    (when initial-path
      (print (state :editor) initial-path)))

  (def {:file-open file-open
        :search search-state
        :editor editor-state} state)

  (when id
    (put editor-state :id id))

  (put-in editor-state [:gb :open-file]
          (fn [_]
            (set-open :file-open)
            (put props :focus file-open)))

  (put-in editor-state [:gb :search]
          (fn [_]
            (set-open :search)
            (put props :focus search-state)))

  (put-in file-open [:gb :escape]
          (fn [props]
            (set-open false)
            (put props :focus editor-state)))

  (put-in file-open [:gb :enter]
          (fn [props]
            (set-open false)
            (print editor-state (string "HAHAHAHA"))
            (put props :focus editor-state)))

  (put-in search-state [:gb :search-target] (editor-state :gb))

  (put-in search-state [:gb :escape]
          (fn [props]
            (print "ESCAPE!")
            (set-open false)
            (put props :focus editor-state)))

  (put-in search-state [:gb :search] print)
  (put-in search-state [:gb :search-backwards] print)

  [:block {}
   (when-let [c (props :open)]
     [:background {:color :purple}
      [:padding {:all 4}
       (case c
         :file-open
         [:row {}
          [:text {:size 22
                  :text "Open: "}]
          [inner-inner {:weight 1
                        :text/size 22
                        :height 28
                        :state file-open}]]

         :search
         [:row {}
          [:text {:size 22
                  :text "Search: "}]
          [inner-inner {:weight 1
                        :text/size 22
                        :height 14
                        :state search-state}]])]]
     #
)

   [:background {:color :red}
    [:padding {:left 6 :top 6}
     [inner-inner {:text/spacing 0.5
                   :text/size 20
                   :text/font "MplusCode"
                   :text/color :blue
                   :state editor-state
                   :show-line-numbers true}]]]

   #
])

(defn thing
  [props & _]

  (unless (props :left-state)
    (put props :left-state @{}))

  (unless (props :right-state)
    (put props :right-state @{}))

  [:background {:color :green}
   [:padding {:left 0 :top 30}
    [:row {}
     [:block {:weight 1}
      [inner {:state (props :left-state)
              :id :left
              :initial-path "measure-stuff.janet"
              :open (props :left-open)
              :set-open |(put props :left-open $)}]]
     [:block {:width 2}]
     [:block {:weight 1}
      [inner @{:state (props :right-state)
               :id :right
               :initial-path "freja/render_new_gap_buffer.janet"
               :open (props :right-open)
               :set-open |(put props :right-open $)}]]

     #
]]])

(var eeel nil)

(loop [i :range [0 100]]
  (let [el (compile [thing props]
                    :tags jt/tags
                    :element eeel)
        with-sizes (d/set-definite-sizes el 203 600)
        with-sizes (set-relative-size el 203 600)]

    (update props :left-open not)
    (put props :compilation/changed true)

    (set eeel with-sizes)

    #(print-tree with-sizes)
    #(assert2 (table? with-sizes))

    # even if children can't get even distribution of pixels
    # it should always add upp to the width
    #(assert2 (= (el :width) (+ ;(map |($ :width) (el :children)
))


(print-results)
