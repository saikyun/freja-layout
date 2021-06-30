# freja-layouting
layouting library for freja

# dependencies

[freja](https://github.com/Saikyun/freja) installed

# instructions to try markdown example

```
git clone https://github.com/Saikyun/freja-layouting
cd freja-layouting
freja menu.janet
```

1. in freja, hit Ctrl/Cmd+L to load the file
2. some text should show up on the right side

# modifying the markdown

to find the source for the menu

1. hit Ctrl/Cmd+F
2. write `(def md ```, hit enter
3. there's the markdown, and just below, the hiccup to render the markdown

you can modify the markdown or hiccup and hit Ctrl/Cmd+L
