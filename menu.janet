(use jaylib)
(import freja/input :as i)
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
  (def off 0x00110033)
  (def down 0x00ff00ff)
  (def outside 0xff0000ff)

  (def bg (compile props
                   [background
                    {:color off}
                    ;children]))

  (defn button-on-event [self ev]
    (match ev
      [:press pos]
      (when (in-rec? pos
                     (dyn :offset-x)
                     (dyn :offset-y)
                     (self :width)
                     (self :height))
        (put bg :color down)
        (put self :down true))

      [:drag pos]
      (when (self :down)
        (put bg :color outside)
        (when
          (in-rec? pos
                   (dyn :offset-x)
                   (dyn :offset-y)
                   (self :width)
                   (self :height))
          (put bg :color down))

        true)

      [:double-click pos]
      (when (in-rec? pos
                     (dyn :offset-x)
                     (dyn :offset-y)
                     (self :width)
                     (self :height))
        (put bg :color 0x000000ff)
        (put self :down true))

      [:triple-click pos]
      (when (in-rec? pos
                     (dyn :offset-x)
                     (dyn :offset-y)
                     (self :width)
                     (self :height))
        (put bg :color 0x000000ff)
        (put self :down true))

      [:release pos]
      (when (self :down)
        (put bg :color off)
        (when (in-rec? pos
                       (dyn :offset-x)
                       (dyn :offset-y)
                       (self :width)
                       (self :height))

          (when-let [cb (props :on-press)]
            (cb self ev)))
        (put self :down false)
        true)))

  [@{:on-event button-on-event}
   {}
   bg])


## yay!

# our state
(defonce state @{})

(loop [k :in (keys state)]
  (put state k nil))

(merge-into state
            {:menu :file
             :event/changed true})

# our "dom" tree
(defn tree
  [props & _]
  [padding
   {:right 10
    :left 500
    :top 40}
   [background {:color 0x00000011}
    [block {}
     [padding {:all 5}
      [button {:on-press (fn [self ev]
                           (e/put! state :menu :file))}
       [padding {:all 10}
        [text {:size 15
               :color 0x00ff00ff}
         "File"]]]]

     [padding {:all 5}
      [button {:on-press (fn [self ev]
                           (e/put! state :menu :edit))}
       [padding {:all 10}
        [text {:size 15
               :color 0x00ff00ff}
         "Edit"]]]
      #
]]

    (when (props :menu)
      [background {:color 0x0000ff33}
       [block {:max-width 200}
        (case (props :menu)
          :file
          [block {}
           [button {:on-press
                    (fn [self ev]
                      (i/open-file (frp/text-area :gb))
                      (e/put! state :menu nil))}
            [grid {:space-between true}
             "Open"
             "Ctrl+O"]]
           [button {:on-press (fn [& _]
                                (i/quit (frp/text-area :gb)))}
            [grid {:space-between true}
             "Quit"
             "Ctrl+Q"]]]

          :edit
          [text {} "Undo"])]])

    [block {}
     [text {} (string/format "%.40m" props)]]
    #
]])

# hitting ctrl+l ... 



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
