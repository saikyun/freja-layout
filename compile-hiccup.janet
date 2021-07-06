(defmacro put-many
  [t & kvs]
  ~(-> ,t
       ,;(map (fn [[k v]]
                ~(put ,k ,v))
              (partition 2 kvs))))

(defn add-default-props
  [e props]
  (def {:width width
        :height height
        :min-width min-width
        :min-height min-height} props)

  (put-many e
            :props props
            :width width
            :height height
            :min-width min-width
            :min-height min-height))

(defn block
  [props & children]
  (-> (dyn :element)
      (add-default-props props)
      (put :sizing :expand-w)))

(defn text
  [props & children]

  (def {:size size
        :font font
        :line-height line-height
        :color color
        :spacing spacing} props)

  (default size (dyn :text/size 14))
  (default font (dyn :text/font))
  (default line-height (dyn :text/line-height 1))
  (default spacing (dyn :text/spacing 2))
  (default color 0x000000ff)

  (def t (string/join children ""))
  (def lines (string/split "\n" t))

  (-> (dyn :element)
      (add-default-props props)
      (put-many
        :children []
        :color color
        :size size
        :spacing spacing
        :font font
        :text t
        :line-height line-height
        :lines lines)))

(defn padding
  [props & children]
  (def {:all all
        :top top
        :right right
        :bottom bottom
        :left left} props)

  (default all 0)
  (default top all)
  (default right all)
  (default bottom all)
  (default left all)

  (-> (dyn :element)
      (add-default-props props)
      (put-many :offset [top right bottom left]
                :sizing :wrap)))

(defn background
  [props & children]
  (def {:color color} props)

  (-> (dyn :element)
      (add-default-props props)
      (put-many :color color
                :sizing :wrap)))

(def tags @{:block @{:f block}
            :text @{:f text}
            :padding @{:f padding}
            :background @{:f background}})

(defn compile
  [hiccup]
  (def hiccup (if (string? hiccup)
                [:text {} hiccup]
                hiccup))

  (def [f-or-kw props] hiccup)
  (def tag-data (when (keyword? f-or-kw)
                  ((dyn :tags) f-or-kw)))
  (def f (if tag-data
           (tag-data :f)
           f-or-kw))
  (def children (drop 2 hiccup))

  (def e @{})
  (with-dyns [:element e]
    (when tag-data
      (put e :tag f-or-kw))
    (put e :f f)
    (def e (f props ;children))

    (when tag-data (merge-into e tag-data))

    (unless (e :children)
      (put e :children (map compile children)))

    e))

(with-dyns [:tags tags]
  (compile [:block {:width 100}
            [:background {:color 0x00ff00ff}
             [:padding {:left 30}
              [:block {:width 30}]
              "hej"]]]))

(setdyn :pretty-format "%.40M")


################### assertions
(assert (deep= @{:a 10 :b 20} (put-many @{} :a 10 :b 20)))
