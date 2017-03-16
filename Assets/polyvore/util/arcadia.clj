(ns polyvore.util.arcadia
  (:import [UnityEngine GameObject]
           [System.Reflection BindingFlags]))

(defn placeholder [^Type expected-type]
  (if true ;(isa? expected-type UnityEngine.Object)
    (-> (if (= expected-type GameObject)
          UnityEngine.Object
          expected-type)
        (.GetConstructors (enum-or BindingFlags/Public
                                   BindingFlags/NonPublic
                                   BindingFlags/Instance))
        (aget 0)
        (.Invoke Type/EmptyTypes))
    (throw (Exception. "Placeholders are only defined for Object types"))))
