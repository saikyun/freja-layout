(import ./default-tags :prefix "" :fresh true)

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
  (print (string/format "%p"
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
                   :tags tags
                   :to-init to-init}]
  (def new-children (or old-children @[]))

  (var put-i 0)

  (loop [i :range [0 (length children)]
         :let [c (children i)
               key (cond (table? c)
                     (get c :key)

                     (tuple? c)
                     (get-in c [1 :key]))

               old-c (if key
                       (do (var oc nil)
                         # TODO: might not want linear search here, instead caching the keys
                         # but then you remove ability to
                         # recompile a child without involving parent
                         (each ioc (or old-children [])
                           (when (= key (ioc :key))
                             (set oc ioc)
                             (break)))
                         oc)
                       (get old-children i))]
         :when (not (nil? c))]
    (->> (compile c :element old-c
                  :tags tags
                  :to-init to-init)
         (put new-children put-i))
    (++ put-i))

  # this happens when `old-children` is longer than `children`
  # then we just trim it down to the size it should be
  (when (and old-children (< put-i (length old-children)))
    (array/remove new-children put-i (length new-children)))

  new-children)


(setdyn :pretty-format "%.4M")

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


(setdyn :pretty-format "%.40M")

(varfn compile
  [hiccup-or-table &keys {:element element
                          :tags tags
                          :to-init to-init}]
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
          (put element :compilation/children
               (compile-children children
                                 :old-children (element :compilation/children)
                                 :tags tags
                                 :to-init to-init))
          element)

        (let [elem (or (when element
                         (let [{:state state
                                :compilation/children oc
                                :inner/element ie} element

                               # when the f is the same, we count it as "the same element"...
                               same-element (= f
                                               (element :compilation/f))]

                           (table/clear element)

                           # ...which means state should be kept
                           (if same-element
                             (do
                               (when (dyn :freja/log)
                                 (print "same element"))
                               (-> element
                                   (put :state state)
                                   (put :inner/element ie)
                                   (put :compilation/children oc)))
                             element)))
                       @{})]

          (when (dyn :freja/log)
            (print "has element? " (truthy? element))
            (print "compiling: " f-or-kw))

          (with-dyns [:element elem]
            (def children (compile-children children
                                            :old-children (elem :compilation/children)
                                            :tags tags
                                            :to-init to-init))

            (when (dyn :freja/log)
              (pp hiccup))

            (def res (f props ;children))

            #(print "before")
            #(pp res)

            (def outer (cond
                         (string? res)
                         (do (def inner (compile res
                                                 :element (elem :inner/element)
                                                 :tags tags
                                                 :to-init to-init))

                           (merge-into elem inner)

                           (put elem :inner/element inner)

                           elem)

                         (indexed? res)
                         (do

                           (when (dyn :freja/log)
                             (print "going to inner"))
                           (def inner (compile res
                                               :element (elem :inner/element)
                                               :tags tags
                                               :to-init to-init))

                           (merge-into elem inner)

                           (put elem :inner/element inner)

                           elem)

                         # else
                         (do

                           (when (dyn :freja/log)
                             (print "innermost: " f-or-kw))

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

            (when (get outer :init)
              (unless (get outer :state)
                (-> (put outer :state @{})
                    (get :state)))
              (def state (or (get outer :state)))
              (unless (state :compilation/inited)
                (put state :compilation/inited true)
                (array/push to-init outer)))

            outer))))))

(defn init-all
  [es]
  (each e es
    (if (function? (e :init))
      (:init e [:init])
      (:on-event e [:init]))))
