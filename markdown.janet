(import ./layouting2 :prefix "")

(defn header
  [{:level level} & children]
  [padding {:top 20
            :bottom (max 0 (- 6 (* (dec level) 4)))}
   [block {}
    [text {:size (max 20 (- 30 (* (dec level) 6)))
           :font "EBGaramond"}
     ;children]]])

(defn ul
  [props & children]
  [padding {:top 6 :bottom 6}
   [grid
    {:direction :vertical}
    ;children]])

(defn li
  [{:level level} & children]
  [padding {:left (* 12 (dec level))}
   [text
    {}
    "*"
    ;children]])

(def markdown-peg
  ~{:text (* (not :eolf)
             (accumulate
               (some (if-not (+ :new-paragraph
                                "\n*")
                       (+ ':newline
                          (if "\n" 1)
                          '1)))))
    :newline "  \n"
    :header (/ (* '(some "#")
                  :s*
                  :text
                  :eolf)
               ,(fn [header-level
                     m1]
                  [header
                   {:level (length header-level)}
                   m1]))
    :new-paragraph (* :eolf :eolf)
    :eolf (+ "\n" -1)
    :list (/ (some (* '(some "*") :text :eolf))
             ,(fn [& stuff]
                [ul {}
                 ;(seq [[lvl t] :in (partition 2 stuff)]
                    [li
                     {:level (length lvl)}
                     t])]))
    :main (any (+ :list
                  :header
                  (/ :text
                     ,(fn [t]
                        [block {}
                         [text {} t]]))
                  :eolf
                  1)) #(some (+ :header :eolf))
})

(defn md->hiccup
  [md]
  (peg/match markdown-peg md))

(comment
  (md->hiccup ``
* aoe
** b
``))

(defn markdown
  [props & children]
  (def md-string (string/join children "\n"))

  [block props
   ;(md->hiccup md-string)])
