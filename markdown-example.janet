(use jaylib)
(import ./layouting2 :prefix "" :fresh true)
(import freja/events :as e)
(import ./hiccup)
(import ./markdown :prefix "")
(use freja/defonce)

# example markdown
(def md ``
# hello

the above is a header

and this is just some 
markdown text

## another header

well aint that nice

### a list too

* the first point
* the second point
** and some subpoints
``)

# our "dom" tree
(defn hiccup
  [props & _]
  [padding
   {:right 10
    :left 500
    :top 40}

   [padding {:top 30}
    [grid {:spacing 2}
     [markdown {} (props :md)]]]
   #
])

# our state
(defonce state @{})

# reset it when we hit ctrl+l
(loop [k :in (keys state)]
  (e/put! state k nil))

(e/put! state :md md)

# register our component
(hiccup/new-component
  :markdown-rendering
  hiccup
  state)