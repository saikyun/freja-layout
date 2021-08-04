# freja-layouting123
layouting library for freja

# dependencies

[freja](https://github.com/Saikyun/freja) installed

# instructions to try a test

```
git clone https://github.com/Saikyun/freja-layouting
cd freja-layouting
freja test/min2.janet
```

1. in freja, hit Ctrl/Cmd+L to load the file
2. some boxes should show up on the right side

# to print render-tree
```

(comment
  # the below can be used to print the render tree
  (import freja-layout/compile-hiccup :as ch :fresh true)
  (import freja-layout/sizing/definite :as ds :fresh true)
  (import freja-layout/sizing/relative :as rs :fresh true)

  (let [el (ch/compile [hiccup my-props]
                       :tags jt/tags)
        el (ds/set-definite-sizes el 800 600)
        el (rs/set-relative-size el 800 600)]
    (ch/print-tree el))
  #
)
```
