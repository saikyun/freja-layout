# hitting ctrl+l
(import ../freja-layout/jaylib-tags :as jt)
(import ../freja-layout/sizing/relative :as rs)
(import ../freja-layout/default-tags :as dt)
(import freja/hiccup :as h)
(import freja/events :as e)
(import freja/new_gap_buffer :as gb)
(import freja/frp)
(use freja/defonce)
(use freja-jaylib)

(defonce sh-state @{})

(def parse-spaces
  ~{:escaped-string ``\"``
    :fake-string (* "\"" '(any (+ (if ``\"`` 1)
                                  (if-not ``"`` 1)))
                    ``"``)
    :real-string (* "'" '(any (if-not ``'`` 1))
                    ``'``)
    :other '(some :S)
    :main (any (+ :real-string :fake-string :other :s+))})

(pp (peg/match parse-spaces ``clj -e '"123 \" HAHA"'``))

#(peg/match '(* (if-not ``\`` 1) ``\"``) `` \"``)

(defn run!
  [state in]
  (try (do
         (def p (os/spawn #(peg/match parse-spaces in)
                          (tracev ["sh" "-c" (string in)])
                          :p {:in :pipe :out :pipe}))
         (def res (:read (p :out) :all))
         (:wait p)

         (gb/replace-content
           (get-in state [:text-area :gb])
           res))
    ([err fib]
      (debug/stacktrace fib err)
      (gb/replace-content
        (get-in state [:text-area :gb])
        err))))

(defonce text-area-state (frp/default-text-area))
(put-in text-area-state [:gb :text] @"Welcome! :)")
(put text-area-state :id :history)


(print "hej")
(defonce input-state
  @{})
(merge-into input-state
            (frp/default-text-area
              :extra-binds @{:enter
                             (fn [self]
                               (run! sh-state (gb/content self)))}))
(put-in input-state [:gb :background] 0x00000011)
(put input-state :id :input)

(put sh-state :text-area text-area-state)

(update sh-state :input |(or # @"" # uncomment to reset input
                             $ @""))

(update sh-state :history |(or # @[] # uncomment to reset history
                               $ @[]))

(var c nil)

(do #(run! (put sh-state :input "ls"))
  :ok)

(use freja-jaylib)

(defn text-area
  [{:state state
    :max-width max-width
    :max-height max-height
    :height height} & _]

  (def width max-width)
  (def height (min max-height (or height 9999999)))

  (put-in state [:gb :size]
          [width
           height])

  [:block {:height height}
   @{:children []
     :props []
     :relative-sizing rs/block-sizing

     :render (fn [self]
               (:draw state)
               #(pp (get-in state [:gb :text]))
)

     :on-event (fn [self ev]

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
                   true))

     :width (get-in text-area-state [:gb :size 0])
     :height (get-in text-area-state [:gb :size 1])}])


(defn shell
  [props & _]
  [:padding
   {:top 30
    :left 600}
   [:background {:color 0x11111111}
    [:padding {:all 5}
     [:block {:height 660
              :direction :vertical
              :space-between true
              #:spacing 2
}

      [text-area {:state text-area-state}]

      [text-area {:height 20
                  :state input-state}]]]]])


(set c (h/new-layer
         :shell
         shell
         sh-state))
