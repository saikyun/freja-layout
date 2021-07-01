(use jaylib)
(import freja/frp)
(import freja/events :as e)
(import ./layouting2 :prefix "")
(import ./render-layouting2 :as r)

(defn compile-tree
  [props hiccup]
  (with-dyns [:text/font "Poppins"
              :text/size 20]
    (compile
      {:max-width (get-screen-width)
       :max-height (get-screen-height)}
      [hiccup props])))


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

# table with all components that have names
# if a new component is created with a name
# it is added to named-components
# if it already exists in named-components,
# instead the component to be added is merged into
# the component already existing
(def named-components @{})

(defn new-component
  [name
   hiccup
   state
   &keys {:initial-state is}]
  (def render-tree (or (named-components name)
                       (let [c @{}]
                         (put named-components name c)
                         c)))

  # reset the component
  (loop [k :keys render-tree]
    (put render-tree k nil))

  # insert initial state
  (merge-into render-tree (or is {}))

  (put render-tree
       :hiccup hiccup)

  (put render-tree
       :tree (compile-tree state hiccup))

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
           (put self :tree (compile-tree
                             state
                             (self :hiccup))))))

  (put-in frp/deps [:deps state] [render-tree])
  (frp/subscribe! frp/mouse render-tree)
  (frp/subscribe-finally! frp/frame-chan render-tree))
