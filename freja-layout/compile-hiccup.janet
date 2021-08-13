(use ./default-tags)

(use profiling/profile)


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
  (print (string/format "%.40M"
                        (map-tree
                          identity
                          t))))

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

(defn nof-no-nil-children
  [hiccup]
  (var nof 0)
  (loop [i :range [2 (length hiccup)]
         :let [c (get hiccup i)]
         :when (not (nil? c))]
    (++ nof))
  nof)

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
          #(print (string/format "%.40M" h1))
          (set tag1 (h1 :tag))
          (set f1 (h1 :compilation/f))
          (set props1 (h1 :compilation/props))
          (set nof-children1 (h1 :compilation/nof-children)))
        (do
          #(tracev h1)
          (set tag1 (h1 0))
          (set f1 (h1 0))
          (set props1 (h1 1))
          (set nof-children1 (nof-no-nil-children h1))))

      (var tag2 nil)
      (var f2 nil)
      (var props2 nil)
      (var nof-children2 nil)

      (if (table? h2)
        (do
          #(print (string/format "%.40M" h2))
          (set tag2 (h2 :tag))
          (set f2 (h2 :compilation/f))
          (set props2 (h2 :compilation/props))
          (set nof-children2 (h2 :compilation/nof-children)))
        (do

          #(tracev h2)
          (set tag2 (h2 0))
          (set f2 (h2 0))
          (set props2 (h2 1))
          (set nof-children2 (nof-no-nil-children h2))))
      ### end of extraction

      (and (same-except-children? tag1 f1 props1
                                  tag2 f2 props2)
           (= nof-children1
              nof-children2)))))

(var compile nil)

(defn compile-children
  [children &keys {:old-children old-children
                   :tags tags}]
  (def new-children (or old-children @[]))

  (var put-i 0)

  (loop [i :range [0 (length children)]
         :let [c (children i)
               old-c (get old-children i)]
         :when (not (nil? c))]
    (->> (compile c :element old-c
                  :tags tags)
         (put new-children put-i))
    (++ put-i))

  new-children)


(setdyn :pretty-format "%.4M")

(defn clear-table
  [t]
  #(print "clearing table!")
  #(pp t)
  (loop [k :keys t]
    (put t k nil))

  t)

(def lul @{})

(defmacro assertm
  [check &opt err]
  (with-syms [v]
    ~(let [,v ,check]
       (if ,v
         ,v
         (error ,(if err err "assert failure"))))))

(defn nof-non-nil
  [es]
  (var i 0)
  (each e es
    (when e (++ i))
    i))

(varfn compile
  [hiccup-or-table &keys {:element element
                          :tags tags}]
  #(print "compiling...")
  #(pp hiccup)
  #(print "old: ")
  #(pp element)

  (if (table? hiccup-or-table)
    # this means it's already compiled, e.g. a precompiled child
    hiccup-or-table
    (do
      (def hiccup (if (string? hiccup-or-table)
                    [:text {:text hiccup-or-table}]
                    hiccup-or-table))

      (assertm tags "need :tags for compiling")

      (def [f-or-kw props] hiccup)

      (def tag-data (when (keyword? f-or-kw)
                      (tags f-or-kw)))

      (def f (if tag-data
               (tag-data :f)
               f-or-kw))

      (def children (drop 2 hiccup))

      (assertm (dictionary? props)
               (string/format
                 ``props must be table or struct, was:
%.40M

hiccup was:
%.40M
``
                 props
                 hiccup))

      (if (and element
               (same? element
                      hiccup))
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
            (def children (compile-children children
                                            :old-children (elem :compilation/children)
                                            :tags tags))

            (when (dyn :freja/log)
              (pp hiccup))
            (def res (f props ;children))

            #(print "before")
            #(pp res)

            (def outer (if (indexed? res)
                         (do

                           (def inner (compile res
                                               :element (elem :inner/element)
                                               :tags tags))

                           (put lul :a res)

                           (merge-into elem inner)

                           (put elem :inner/element inner)

                           elem)

                         (do
                           (when tag-data
                             (put res :tag f-or-kw))

                           (-> res
                               (put :f f)
                               (put :children children)))))

            (-> outer
                (put :compilation/children children)
                (put :compilation/nof-children (nof-non-nil children))
                (put :compilation/props props)
                (put :compilation/f f))

            #(print "after")
            #(pp outer)

            (when tag-data (merge-into outer tag-data))

            outer))))))
