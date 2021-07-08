(import ../compile-hiccup :as ch :fresh true)
(import ../sizing :as s :fresh true)
(import ../jaylib-sizing :as js :fresh true)
(import ../jaylib-rendering :as jr :fresh true)
(import ../assets :as a)

(import freja/frp)
(use freja/defonce)
(use jaylib)

(print)
(print "beginning of test-hiccup")

(setdyn :pretty-format "%.40M")


(defn in-rec?
  [[px py] x y w h]
  (and
    (>= px x)
    (<= px (+ x w))
    (>= py y)
    (<= py (+ y h))))


(defn clickable
  [props & _]
  (-> (dyn :element)
      (ch/add-default-props props)
      (put :on-event
           (fn [self ev]
             #(print "testing " (get-in self [:props :id]))

             (def [kind] ev)
             (def pos (if (= kind :scroll)
                        (ev 2)
                        (ev 1)))

             (def in?
               (in-rec? pos
                        (dyn :offset-x)
                        (dyn :offset-y)
                        (self :width)
                        (self :height)))

             (match ev
               [:press pos]
               (when in?
                 (put self :down true)
                 true)

               [:release pos]
               (when (self :down)
                 (when in? ((props :on-click) ev))

                 (put self :down false)

                 true)

               false)))))

(def tags @{:block @{:f ch/block}
            :clickable @{:f clickable}
            :text @{:f ch/text
                    :sizing js/text-sizing
                    :render jr/text-render}
            :padding @{:f ch/padding}
            :row @{:f ch/row}
            :vertical @{:f ch/vertical}
            :background @{:f ch/background
                          :render jr/background-render}})

(defmacro with-matrix
  [& body]
  ~(do (rl-push-matrix)

     (try (do ,;body
            (rl-pop-matrix))
       ([err]
         (do
           (rl-pop-matrix)
           (error err))))))

(defmacro with-translation
  [[s v] & body]

  ~(let [,s ,v]
     (if ,s
       (with-matrix
         (if (= 4 (length ,s))
           (rl-translatef (,s 3) (,s 0) 0)
           (rl-translatef (,s 0) (,s 1) 0))
         ,;body)
       (do ,;body))))

(var flow-render-children nil)

(defn noop
  [_]
  nil)

(defn render
  [el]
  (def {:render-children render-children
        :render render}
    el)

  (default render noop)
  (default render-children flow-render-children)

  #(print (el :tag))
  #(tracev p)
  (render el)

  (with-translation [o (el :offset)]
    #(tracev o)
    (render-children el)))

(varfn flow-render-children
  [{:children cs
    :tag tag
    :content-width content-width}]

  (unless (empty? cs)
    #(print "gonna print children")

    (var x 0)
    (var y 0)
    (var row-h 0)

    (rl-push-matrix)

    (rl-push-matrix)
    (loop [c :in cs
           :let [{:width w
                  :height h} c]]

      #(print "tag: " (c :tag))

      (when (and (pos? x)
                 (> (+ x w) content-width))
        (rl-pop-matrix)

        (set x 0)
        (+= y row-h)

        (rl-translatef 0 row-h 0)

        (set row-h 0)

        (rl-push-matrix))

      (render c)

      # (print "pos: " x " " y)

      (rl-translatef w 0 0)

      (+= x w)

      (set row-h (max row-h h))
      #
)
    (rl-pop-matrix)
    (rl-pop-matrix)))


(def el123
  (tracev
    (with-dyns [:tags tags
                :text/font "Poppins"
                :text/size 14]
      (ch/compile
        [:padding {:left 700 :top 35}
         #[:block {:width 100}
         [:background {:color 0xff000011}
          [:padding {:left 30 :bottom 20 :right 30 :top 100}
           [:block {} "dog"]
           [:clickable {:on-event (fn [ev] (print "hello: ")
                                    (pp ev))}
            "Cool"]
           [:block {:width 50}
            [:row {} "a " "b " "c " "d " "f " "h " "i " "j " "k " "l " "i "]
            [:vertical {} "a " "b " "c " "d " "f " "h " "i " "j " "k " "l " "i "]]
           #[:block {}
           [:background {:color :red}
            [:padding {:top 20
                       :left 10}
             "hahahahaahhceohhu"]]
           #]
           "yo"
           [:background {:color :blue}
            "hej"]]] #]
]))))

(defonce lul (do
               (init-audio-device)
               :audio-inited))

(def bajs (-> (load-wave "bajs.wav")
              (load-sound-from-wave)))
(def bajs2 (-> (load-wave "bajs2.wav")
               (load-sound-from-wave)))

(def tri @{:pos @[0 0]})


(def rutor @[])

(defn rand-clr
  []
  (+ 0.1 (* 0.8 (math/random))))

(defn new-ruta
  [pos]
  @{:draw (fn [self]
            (update-in self [:vel 1] + 0.1)

            (update self :pos
                    |(-> $
                         (update 0 + ((self :vel) 0))
                         (update 1 + ((self :vel) 1))))

            (draw-rectangle-rec [;(self :pos)
                                 ;(self :size)]
                                (self :color)))

    :pos pos

    :size @[7 10]

    :vel @[0 0]

    :color [(+ 0.3 (* 0.1 (rand-clr)))
            (+ 0.2 (* 0.1 (rand-clr)))
            (rand-clr)]})

(defn draw
  [self]
  (draw-rectangle-rec
    [100 100
     200 200]
    :purple)

  #(pp (get-mouse-position))

  (def [x y] (and #(mouse-button-down? 0)
                  (get-mouse-position)))
  (put-in tri [:pos 0] x)
  (put-in tri [:pos 1] y)

  (rl-push-matrix)
  (rl-load-identity)
  (def pos (tri :pos))

  (put tri :color :pink)
  (when
    (and (>= (+ x 25) (+ 500 100))
         (< (- x 25) (+ 500 300)))
    #    (print "x")
    (when (and (>= (+ y 25) (+ 60 100))
               (< (- y 25) (+ 60 300)))
      (if (> 0.5 (math/random))
        (play-sound bajs2)
        (play-sound bajs))
      (put tri :color :green)
      (array/push rutor (new-ruta @[x y]))
      #      (print "y")
))

  (rl-translatef (pos 0) (pos 1) 0)

  (when (> x 450)
    (draw-triangle
      [-50 50]
      [50 50]
      [0 -50]
      (tri :color)))

  (rl-load-identity)

  (each r rutor (:draw r))

  (rl-pop-matrix)
  #
)

(defn bounce
  [props & children]
  (-> (dyn :element)
      (ch/add-default-props props)
      (put :render draw)))

(def el
  (with-dyns [:tags tags
              :text/font "Poppins"
              :text/size 30
              :text/line-height 1]
    (ch/compile
      [:padding {:top 30 :left 500}

       [:background {:color :pink}
        [:block {:height 800}
         [:text {:color :blue}
          "dhhjdjfdjdjkdjdfkkjfkkffkdokfssssssiiifk"
          "gtglfllgogl"]
         [bounce {}]]]])))

(import freja/defonce :prefix "")

(defonce render-tree @{})


(var children-on-event nil)

(defn elem-on-event
  [e ev]
  # traverse children first
  # will return true if the event is taken
  (if (with-dyns [:offset-x (+ (dyn :offset-x)
                               (get-in e [:offset 3] 0))
                  :offset-y (+ (dyn :offset-y)
                               (get-in e [:offset 0] 0))]
        (children-on-event e ev))
    true

    (when (e :on-event)
      (:on-event e ev))))

(varfn children-on-event
  [{:children cs
    :content-width content-width} ev]
  (var taken false)

  (var x 0)
  (var y 0)
  (var row-h 0)

  (loop [c :in cs
         :let [{:width w
                :height h} c]
         :until taken]

    #(print "tag: " (c :tag))

    (when (and (pos? x)
               (> (+ x w) content-width))
      (set x 0)
      (+= y row-h)
      (set row-h 0))

    (with-dyns [:offset-x (+ (dyn :offset-x) x)
                :offset-y (+ (dyn :offset-y) y)]
      (set taken (elem-on-event c ev)))

    # (print "pos: " x " " y)

    (+= x w)

    (set row-h (max row-h h))
    #
)

  taken)

(defn handle-ev
  [tree ev]
  (with-dyns [:offset-x 0
              :offset-y 0]
    (when (elem-on-event tree ev)
      (frp/push-callback! ev (fn [])))))

#(tracev
(with-dyns [:max-width (get-screen-width)
            :max-height (get-screen-height)]
  (s/apply-sizing el)) #)

(merge-into
  render-tree
  @{:draw (fn [self dt]
            #(print)
            #(print "start")
            #(draw-rectangle-rec [720 44 5 20] :green)
            (render el)
            #
)
    :on-event (fn [self ev]
                (match ev
                  [:dt dt] (:draw self dt)
                  (handle-ev el ev)))})

(frp/subscribe-finally! frp/frame-chan render-tree)
(frp/subscribe! frp/mouse render-tree)
