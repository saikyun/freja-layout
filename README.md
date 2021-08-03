# freja-layouting
layouting library for freja

# dependencies (to try examples)

[freja](https://github.com/Saikyun/freja) installed



# instructions to try shell example (you need `sh`)


```
git clone https://github.com/Saikyun/freja-layouting
cd freja-layouting
freja examples/shell.janet
```

1. in freja, hit Ctrl/Cmd+L to load the file
2. some boxes should show up on the right side
3. click the bottom box, the write e.g. `ls`, then press `Enter`
4. you should now see something like this in the top box:
```
examples
freja-layout
project.janet
README.md
test
```
5. In the bottom box, write `freja README.md` to open the file inside freja



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
