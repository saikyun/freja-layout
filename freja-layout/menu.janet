#TODO: "install" freja-layout

(import freja-layout/jaylib-tags :as jt)
(import freja-layout/hiccup2 :as h)
(import freja-layout/sizing/relative :as rs)

(import freja/events :as e)
(import freja/frp)
(import freja/input :as i)
(import freja/new_gap_buffer :as gb)
(use freja/defonce)
(use freja-jaylib)

(use profiling/profile)

(setdyn :pretty-format "%.40M")

(defonce my-props @{})

(def label-color 0xffffffee)
(def hotkey-color 0xffffffbb)
(def damp-color 0xffffff88)
(def highlight-color 0xffffffee)
(def bar-bg 0x2D2D2Dff)
(def dropdown-bg 0x3E3E3Eff)

(def kws {:control "Ctrl"})

(defn kw->string
  [kw]
  (get kws
       kw
       (let [s (string kw)]
         (if (one? (length s))
           (string/ascii-upper s)
           s))))

(defn hotkey->string
  [hk]
  (string/join (map kw->string hk) "+"))

(defn menu-row
  [{:f f
    :label label
    :hotkey hotkey}]

  (default hotkey (i/get-hotkey ((frp/text-area :gb) :binds) f))
  (assert hotkey (string "no hotkey for " f))

  [:row {}
   [:padding {:right 40}
    [:clickable {:on-click (fn [_]
                             (e/put! my-props :open-menu nil)
                             (f (frp/text-area :gb)))}
     [:text {:color label-color
             :size 22
             :text label}]]]

   [:block {:weight 1}
    [:align {:horizontal :right}
     [:text {:color hotkey-color
             :size 22
             :text (hotkey->string hotkey)}]]]])

(defn file-menu
  [props]
  [:shrink {}
   [menu-row
    {:f i/open-file
     :label "Open"}]
   [menu-row
    {:f i/save-file
     :label "Save"}]
   [menu-row
    {:f i/quit
     :label "Quit"}]])

(defn edit-menu
  [props]
  [:shrink {}
   [menu-row
    {:f i/undo!2
     :label "Undo"}]
   [menu-row
    {:f i/redo!
     :label "Redo"}]
   [menu-row
    {:f i/cut!
     :label "Cut"}]
   [menu-row
    {:f gb/copy
     :label "Copy"}]
   [menu-row
    {:f i/paste!
     :label "Paste"}]

   [:padding {:all 8}
    @{:render (fn [{:width w :height h}]
                (draw-rectangle 0 0 w (inc h) 0xffffff22))
      :relative-sizing rs/block-sizing
      :children []
      :props {}}]

   [menu-row
    {:f i/search2
     :label "Search"}]])

(defn hiccup
  [props & children]
  [:block {#:on-click (fn [_]
           #            (e/put! props :open-menu nil))
}

   [:padding {:left 0 :top 0}
    [:background {:color bar-bg}
     [:padding {:all 8 :top 4 :bottom 4}
      [:block {}
       [:row {}
        [:padding {:right 8}
         [:clickable {:on-click (fn [_]
                                  (e/put! props :open-menu :file))}
          [:text {:color (if (= (props :open-menu) :file)
                           highlight-color
                           damp-color)
                  :size 22
                  :text "File"}]]]
        [:clickable {:on-click (fn [_]
                                 (e/put! props :open-menu :edit))}
         [:text {:color (if (= (props :open-menu) :edit)
                          highlight-color
                          damp-color)
                 :size 22
                 :text "Edit"}]]]]]]

    (when-let [om (props :open-menu)]
      [:background {:color dropdown-bg}
       [:padding {:all 8
                  :top 3}
        (case om
          :file
          [file-menu props]
          :edit
          [edit-menu props])]])]])


(comment
  (import ./compile-hiccup :as ch :fresh true)
  (import ./sizing/definite :as ds :fresh true)
  (import ./sizing/relative :as rs :fresh true)

  (let [el (ch/compile [hiccup my-props]
                       :tags jt/tags)
        el (ds/set-definite-sizes el 800 600)
        el (rs/set-relative-size el 800 600)]
    (ch/print-tree el))
  #
)

#(comment
(def c (h/new-layer :test-layer2
                    hiccup
                    my-props
                    :render jt/render
                    :tags jt/tags
                    :text/font "Poppins"
                    :text/size 22
                    :max-width (get-screen-width)
                    :max-height (get-screen-height)))
#)

