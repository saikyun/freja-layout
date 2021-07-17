(defmacro put-many
  [t & kvs]
  ~(-> ,t
       ,;(map (fn [[k v]]
                ~(put ,k ,v))
              (partition 2 kvs))))

(defn remove-keys
  [t ks]
  (def nt @{})
  (loop [[k v] :pairs t
         :when (not (ks k))]
    (put nt k v))
  nt)

(defn keep-keys
  [t ks]
  (loop [[k v] :pairs t
         :when (not (ks k))]
    (put t k nil))

  t)

(defn traverse-tree
  [f el]
  (loop [c :in (get el :children [])]
    (traverse-tree f c))

  (loop [c :in (get el :compilation/children [])]
    (traverse-tree f c))

  (when-let [ie (el :inner/element)]
    (traverse-tree f ie))

  (f el))

(defn map-tree
  [f el]
  (def cs (when-let [cs (el :children)]
            (map |(map-tree f $) cs)))

  (-> (table/clone el)
      (put :compilation/children nil)
      (put :inner/element nil)
      (put :compilation/f nil)
      (put :compilation/props nil)
      (put :compilation/nof-children nil)
      f
      (put :children cs)))


(defn print-tree
  [t]
  (pp (map-tree
        identity
        t)))

(defn in-rec?
  [[px py] x y w h]
  (and
    (>= px x)
    (<= px (+ x w))
    (>= py y)
    (<= py (+ y h))))

(defn add-default-props
  [e props]
  (def {:width width
        :height height
        :min-width min-width
        :min-height min-height
        :max-width max-width
        :max-height max-height
        :sizing sizing} props)

  (default sizing :wrap)

  (put-many e
            :sizing sizing
            :props props
            :preset-width width
            :preset-height height
            :max-width max-width
            :min-width min-width
            :min-width min-width
            :min-height min-height))

(defn block
  [props & children]
  (-> (dyn :element)
      (add-default-props props)
      (put :sizing :expand-w)))

(defn row
  [props & children]
  (-> (dyn :element)
      (add-default-props props)
      (put :sizing :row)))

(defn vertical
  [props & children]
  (-> (dyn :element)
      (add-default-props props)
      (put :sizing :vertical)))


(defn clickable
  [props & _]
  (-> (dyn :element)
      (add-default-props props)
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

(defn text
  [props & children]

  (def {:size size
        :font font
        :line-height line-height
        :color color
        :spacing spacing
        :text text} props)

  (default size (dyn :text/size 14))
  (default font (dyn :text/font))
  (default line-height (dyn :text/line-height 1))
  (default spacing (dyn :text/spacing 2))
  (default color 0x000000ff)

  (def t text)
  (def lines (string/split "\n" t))

  (-> (dyn :element)
      (add-default-props props)
      (put-many
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

(defn align
  [props & children]
  (def {:vertical v
        :horizontal h} props)

  (-> (dyn :element)
      (add-default-props props)
      (put-many :horizontal h
                :vertical v
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


#
#
#
########################## Compilation
#
#
#
#



(defn same-except-children?
  [t1 f1 p1
   t2 f2 p2]
  (and (or (and t1 t2 (= t1 t2))
           (and f1 f2 (= f1 f2)))
       (not (p1 :compilation/changed))
       (not (p2 :compilation/changed))
       (= p1 p2)))

(defn same?
  [h1 h2]
  (cond (string? h1)
    (= h1 h2)

    (or (nil? h1)
        (nil? h2))
    (do
      (eprint "STRANGE NIL IN SAME?")
      (tracev h1)
      (tracev h2)
      false)

    (do
      ### this part just extracts the right parts of the hiccup or table
      (var tag1 nil)
      (var f1 nil)
      (var props1 nil)
      (var nof-children1 nil)

      (if (table? h1)
        (do
          (set tag1 (h1 :tag))
          (set f1 (h1 :compilation/f))
          (set props1 (h1 :compilation/props))
          (set nof-children1 (h1 :compilation/nof-children)))
        (do
          (set tag1 (h1 0))
          (set f1 (h1 0))
          (set props1 (h1 1))
          (set nof-children1 (- (length h1) 2))))

      (var tag2 nil)
      (var f2 nil)
      (var props2 nil)
      (var nof-children2 nil)

      (if (table? h2)
        (do
          (set tag2 (h2 :tag))
          (set f2 (h2 :compilation/f))
          (set props2 (h2 :compilation/props))
          (set nof-children2 (h2 :compilation/nof-children)))
        (do
          (set tag2 (h2 0))
          (set f2 (h2 0))
          (set props2 (h2 1))
          (set nof-children2 (- (length h2) 2))))
      ### end of extraction

      (and (same-except-children? tag1 f1 props1
                                  tag2 f2 props2)
           (= nof-children1
              nof-children2)))))

(var compile nil)

(defn compile-children
  [children &keys {:old-children old-children
                   :tags tags}]
  #(tracev element)
  #(tracev old-children)

  #(put el :children
  (seq [i :range [0 (length children)]
        :let [c (children i)
              old-c (get old-children i)]
        :when c]
    (compile c :element old-c
             :tags tags))
  #)

  #(put el :nof-children (length (el :children)))

  #el
)


(setdyn :pretty-format "%.4M")

(defn clear-table
  [t]
  #(print "clearing table!")
  #(pp t)
  (loop [k :keys t]
    (put t k nil))

  t)

(def lul @{})

(varfn compile
  [hiccup &keys {:element element
                 :tags tags}]
  #(print "compiling...")
  #(pp hiccup)
  #(print "old: ")
  #(pp element)

  (if (table? hiccup)
    # this means it's already compiled, e.g. a precompiled child
    hiccup
    (do
      (def hiccup (if (string? hiccup)
                    [:text {:text hiccup}]
                    hiccup))

      (assert tags "need :tags for compiling")

      (def [f-or-kw props] hiccup)
      (def tag-data (when (keyword? f-or-kw)
                      (tags f-or-kw)))
      (def f (if tag-data
               (tag-data :f)
               f-or-kw))
      (def children (drop 2 hiccup))

      (assert (dictionary? props)
              (string/format
                ``props must be table or struct, was:
%.40M

hiccup was:
%.40M
``
                props
                hiccup))

      #(print "compiling...")
      #(pp hiccup)

      (if (and element
               (# tracev
               do
 (same? (#tracev
        do
 element)
        (#tracev
        do
 hiccup))))
        (do
          (compile-children children
                            :old-children (element :compilation/children)
                            :tags tags)
          element)
        (let [elem (or element
                       @{})]
          (clear-table elem)

          (when (dyn :freja/log)
            (print "compiling: " f-or-kw))

          (with-dyns [:element elem]
            (def children
              (compile-children children
                                :old-children (elem :compilation/children)
                                :tags tags))

            (when (dyn :freja/log)
              (pp hiccup))
            (def res (f props ;children))

            #(print "before")
            #(pp res)

            (def outer (if (indexed? res)
                         (do

                           ### TODO: probably need to rethink this
                           # need to come up with small example
                           # that breaks

                           (def inner (compile res
                                               :element (elem :inner/element)
                                               :tags tags))

                           #(print "inside index, after compi")
                           #(pp inner)

                           (put lul :a res)

                           (merge-into elem inner)

                           (put elem :inner/element inner)

                           elem)

                         (do
                           (when tag-data
                             (put elem :tag f-or-kw))

                           (-> elem
                               (put :f f)
                               (put :children children)))))

            (-> outer
                (put :compilation/children children)
                (put :compilation/nof-children (length children))
                (put :compilation/props props)
                (put :compilation/f f))

            #(print "after")
            #(pp outer)

            (when tag-data (merge-into outer tag-data))

            outer))))))

(setdyn :pretty-format "%.40M")


################### assertions
(assert (deep= @{:a 10 :b 20} (put-many @{} :a 10 :b 20)))

(comment
  (assert (deep= (compile [text {} "Hej"]
                          :element @{})
                 (compile [text {} "Hej"]))))


(comment
  (with-dyns [:tags tags]
    (compile [:block {:width 100}
              [:background {:color 0x00ff00ff}
               [:padding {:left 30}
                [:block {:width 30}]
                "hej"]]])))


#
#
#
#
#
# trying to get caching to work


(assert (same? [:a {}]
               [:a {}]))
(assert (not (same? [:a {}]
                    [:b {}])))

# as long as number of children are the same
# the hiccup forms are considered to be the same
(assert (same? [:a {} "lul"]
               [:a {} "hej"]))

(let [props @{:haha true}]
  (assert (same? [:a props "lul"]
                 [:a props "lul"])))


(let [props @{:haha [:b {} "wat"]
              :x :ok}]
  (assert (same? [:a {:x (props :x)}
                  (props :haha)]
                 [:a {:x (props :x)}
                  (props :haha)])))

(let [props @{:haha [:b {} "wat"]
              :x :ok}
      f (fn [props & children]
          [:a {:x (props :x)}
           (props :haha)])
      e1 [f props]

      # to change props, create a new object
      props (merge-into @{}
                        props
                        @{:haha "nope"})
      e2 [f props]]
  (assert (not (same? e1 e2))))


# if only children change, but not the number
# of children, the hiccup is considered to be the same
(let [props @{:haha [:b {} "wat"]
              :x :ok}
      f (fn [props & children]
          [:a {:x (props :x)}
           (props :haha)
           ;children])
      e1 [f props [:a {}]]
      e2 [f props [:a {}]]]
  (assert (same? e1 e2)))

#
###
##
#
#



(defn q
  [props & children]
  #(print "q")
  #(pp props)
  (-> (dyn :element)
      (add-default-props props)))


(defn a
  [props & children]
  #(print "a")
  #(pp props)
  (-> (dyn :element)
      (add-default-props props)))

(defn b
  [props & children]
  #(print "a")
  #(pp props)
  [a props])

(defn c
  [props & children]
  #(print "a")
  #(pp props)
  [b props])

(defn thing
  [props & children]
  [q {:cat (props :size)}
   ;children])

(defn child
  [props & children]
  (print "child")
  [c {:size :child-thing}
   [a {:size :lllllllllllol}]])
(comment
  (import spork/test)

  (def props @{:size 1337
               :size2 123})

  (print)
  (print "step1")

  (def hc123 [thing props
              [child {:size-child (props :size)}
               [a {}] [a props]]])

  (defmacro hc
    []
    ~[thing props
      [child {:outer-props :outer}]])

  (defmacro hc
    []
    ~[thing props
      [c {:outer-props (props :size2)}]])

  (def el #(test/timeit
    (compile (hc)
             :tags @{})) #)
  #(pp el)


  (def props @{:size 0 :size2 0})

  (print)
  (print "step2")
  (def el
    #(test/timeit
    (compile (hc)
             :element el
             :tags tags)) #)

  (defn print-and-destroy-tags-and-children
    [el]
    (traverse-tree
      |(keep-keys $ {:compilation/children 1
                     :children 1
                     :inner/element 1
                     :tag 1
                     :f 1})
      el)

    (pp el))

  (defn print-and-destroy-no-inner
    [el]
    (traverse-tree
      |(keep-keys $ {:children 1
                     :tag 1
                     :f 1})
      el)

    (pp el)))
