(use jaylib)
(import ./layouting2 :prefix "" :fresh true)
(import ./render-layouting2 :as r :fresh true)
(import freja/events :as e)

(defn in-rec?
  [[px py] x y w h]
  (and
    (>= px x)
    (<= px (+ x w))
    (>= py y)
    (<= py (+ y h))))

(comment
  (def tree
    [block {}
     [padding
      {:padding-left 20}
      [align-right
       {}
       [text {} "hello"]]]]))

(defn button
  [props & children]
  [@{:render r/background-render
     :background 0x00000088
     :on-event
     (fn [self ev]
       (match ev
         [:press pos]
         (when (in-rec? pos
                        (dyn :offset-x)
                        (dyn :offset-y)
                        (self :width)
                        (self :height))
           (put self :background 0x000000ff)
           (put self :down true))

         [:drag pos]
         (when (self :down)

           (if
             (in-rec? pos
                      (dyn :offset-x)
                      (dyn :offset-y)
                      (self :width)
                      (self :height))
             (put self :background 0x000000ff)
             (put self :background 0x00000088))

           true)

         [:double-click pos]
         (when (in-rec? pos
                        (dyn :offset-x)
                        (dyn :offset-y)
                        (self :width)
                        (self :height))
           (put self :background 0x000000ff)
           (put self :down true))

         [:triple-click pos]
         (when (in-rec? pos
                        (dyn :offset-x)
                        (dyn :offset-y)
                        (self :width)
                        (self :height))
           (put self :background 0x000000ff)
           (put self :down true))

         [:release pos]
         (when (self :down)
           (put self :background 0x00000088)
           (when (in-rec? pos
                          (dyn :offset-x)
                          (dyn :offset-y)
                          (self :width)
                          (self :height))

             (when-let [cb (props :on-press)]
               (cb self ev))
             (put self :down false))
           true)))}
   {}
   ;children])


## yay!

# our state
(defonce state @{})

# our "dom" tree
(defn tree
  [props & _]
  [padding
   {:padding-right 10
    :padding-left 500
    :padding-top 40}

   [padding {:all 5}
    [button {:on-press (fn [self ev]
                         (e/put! state :cat "Pixie"))}
     [padding {:all 10}
      [text {:size 15
             :color 0x00ff00ff}
       "Pixie"]]]]

   [padding {:all 5}
    [button {:on-press (fn [self ev]
                         (e/put! state :cat "Skrot"))}
     [padding {:all 10}
      [text {:size 15
             :color 0x00ff00ff}
       "Skrot"]]]
    #
]

   [padding {:all 10}
    [text {:size 20
           :color 0x000000ff}
     (get props :cat "")]]])

# hitting ctrl+l ... 



(loop [k :in (keys state)]
  (put state k nil))


#
#   [align-right {}
#    [text {} "Hello!"]]

## TODO: recompile when props change
(defn tree-compiled
  [props]
  (compile
    {:max-width (get-screen-width)
     :max-height (get-screen-height)}
    (tree props)))

(pp (tree-compiled state))

(defonce render-tree @{})

(var children-on-event nil)

(defn elem-on-event
  [e ev]
  (with-dyns [:offset-x (+ (dyn :offset-x)
                           (get-in e [:offset 0] 0))
              :offset-y (+ (dyn :offset-y)
                           (get-in e [:offset 1] 0))]

    # traverse children first
    # will return true if the event is taken
    (if (children-on-event e ev)
      true

      (do
        (def {:width w
              :height h}
          e)

        (when (e :on-event)
          (:on-event e ev))))))

(varfn children-on-event
  [{:children children} ev]
  (var taken false)
  (loop [c :in (or children [])
         :until taken]
    (set taken (elem-on-event c ev)))
  taken)

(defn handle-ev
  [tree ev]
  (with-dyns [:offset-x 0
              :offset-y 0]
    (when (elem-on-event tree ev)
      (frp/push-callback! ev (fn [])))))

(put render-tree
     :tree (tree-compiled {}))

(put render-tree
     :on-event
     (fn [self ev]
       #(unless (= :dt (first ev)) (pp ev))

       (match ev
         [:press _]
         (handle-ev (self :tree) ev)

         [:double-click _]
         (handle-ev (self :tree) ev)

         [:triple-click _]
         (handle-ev (self :tree) ev)

         [:release _]
         (handle-ev (self :tree) ev)

         [:drag _]
         (handle-ev (self :tree) ev)

         [:dt dt]
         (with-dyns [:dt dt]
           (r/render-elem (self :tree)))

         '(= ev state)
         (put self :tree (tree-compiled state)))))

(put-in frp/deps [:deps state] [render-tree])
(frp/subscribe! frp/mouse render-tree)
(frp/subscribe-finally! frp/frame-chan render-tree)

(comment
  (compile
    {:max-width 800
     :max-height 600}
    [padding {}])
  #
)

(comment

  (compile
    {:max-width 800
     :max-height 600}
    [block {:max-width 400}])
  #=> @{:children @[] :height 0 :width 400}


  (compile
    {:max-width 800
     :max-height 600}
    [padding {:padding-left 10
              :padding-top 10}
     [block {}]])

  #
)
