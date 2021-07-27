(defmacro put-many
  [t & kvs]
  ~(-> ,t
       ,;(map (fn [[k v]]
                ~(put ,k ,v))
              (partition 2 kvs))))
