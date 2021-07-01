(merge-into state
            {#:menu :file  #uncomment to have a menu always open
             :event/changed true})

(defn menu
  [props & _]
  [background {:color 0x00000011}
   [block {}
    [padding {:all 5}
     [button {:on-press (fn [self ev]
                          (e/put! state :menu :file))}
      [padding {:all 10}
       [text {:size 24
              :font "Poppins"}
        "File"]]]]

    [padding {:all 5}
     [button {:on-press (fn [self ev]
                          (e/put! state :menu :edit))}
      [padding {:all 10}
       [text {:size 24}
        "Edit"]]]
     #
]]

   (when (props :menu)
     [background {:color 0x0000ff33}
      [block {:max-width 200}
       (case (props :menu)
         :file
         [block {}
          [button {:on-press
                   (fn [self ev]
                     (i/open-file (frp/text-area :gb))
                     (e/put! state :menu nil))}
           [grid {:space-between true}
            "Open"
            [text {:font "MplusCode"}
             "Ctrl+O"]]]
          [button {:on-press (fn [& _]
                               (i/quit (frp/text-area :gb)))}
           [grid {:space-between true}
            "Quit"
            [text {:font "MplusCode"}
             "Ctrl+Q"]]]]

         :edit
         [text {} "Undo"])]])])
