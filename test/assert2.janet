(defmacro assert2
  [form &opt fail-form]
  ~(try
     (assert ,form
             (string/format "%p %s" ',form "is not truthy"))

     ([err fib]
       (when-let [v ,fail-form]
         (print "relevant data:")
         (pp v))
       (debug/stacktrace fib err)
       (propagate err fib))))