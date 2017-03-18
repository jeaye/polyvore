(ns polyvore.solar-system
  (:import [UnityEngine Transform GameObject Vector3])
  (:require [arcadia
             [core :refer :all]]
            [polyvore.util
             [lang :refer :all]
             [arcadia :refer :all]]))

(defn init-state! [^GameObject obj]
  (doto obj
    (set-state! ::planets {::home (placeholder GameObject)})))

(def system-state (delay (state (object-named "solar-system"))))

(defn closest-planet [^Transform transform]
  ; TODO: optimize in one of two ways:
  ;  1. cache closest planet in an atom
  ;  2. convert position to quadrant and memoize lookup
  (let [planets (::planets @system-state)
        position (.position transform)
        distances (mapv #(vector (first %)
                                 (Vector3/Distance position
                                                   (.. (second %)
                                                       transform
                                                       position)))
                        (seq planets))
        sorted (sort-by second distances)
        closest-key (ffirst sorted)]
    (get planets closest-key)))
