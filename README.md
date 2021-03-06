# freja-layouting
layouting library for freja

# ascii-example

No extra dependencies needed. Needs a terminal with support for ansi escape codes.

## Turn strings into columns

```
git clone https://github.com/Saikyun/freja-layouting
cd freja-layouting

janet test/ascii-layouting.janet \
'there was a little girl, who liked to eat the world. but then a mad guy came, and shouted "NO!"' \
'she was so distraught, that she started running toward the man. he understood that he had made a mistake.' \
'this was not any little girl, I mean, she could eat the world. so he bailed.'

# prints


 there was a little      she was so distraught,   this was not any little
 girl, who liked to eat  that she started         girl, I mean, she could
 the world. but then a   running toward the man.  eat the world. so he
 mad guy came, and       he understood that he    bailed.
 shouted "NO!"           had made a mistake.




```

The important bits of the code, resulting in the above:
```
(defn main
  [& args]
  
  (def props @{:columns (drop 1 args)})

  (defn hiccup
    # props are fed in as an argument
    [{:columns cs}]
    # :row layouts horizontally
    [:row {}
     ;(seq [c :in cs]
        [:block {:weight 1}
         [:padding {:all 1}
          c]])])
          
  # ...compilation & rendering (printing)
)
```


<!--
# dependencies (to try graphical examples)

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


-->
