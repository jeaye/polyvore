(ns polyvore.util.lang)

(defmacro update! [field fun]
  `(set! ~field (~fun ~field)))

(defmacro case-enum
  "Like `case`, but explicitly dispatch on native enum ordinals."
  [e & clauses]
  (letfn [(enum-ordinal [e] `(let [^Enum e# ~e] (int e#)))]
    `(case ~(enum-ordinal e)
       ~@(concat
           (mapcat (fn [[test result]]
                     [(eval (enum-ordinal test)) result])
                   (partition 2 clauses))
           (when (odd? (count clauses))
             (list (last clauses)))))))

(def inc-float (comp float inc))
(def dec-float (comp float dec))
