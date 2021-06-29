# freja-layouting
layouting library for freja

# dependencies

[freja](https://github.com/Saikyun/freja) installed

# instructions to try menu example

```
git clone https://github.com/Saikyun/freja-layouting
cd freja-layouting
freja menu.janet
```

1. in freja, hit Ctrl/Cmd+L to load the file
2. a menu should show up


# modifying the menu

to find the source for the menu

1. hit Ctrl/Cmd+F
2. write `(defn tree`, hit enter
3. there's the hiccup representing the menu

you can modify the hiccup and hit Ctrl/Cmd+L
for example, try changing the padding of the padding elements. or add a button that prints something :)
