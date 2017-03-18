(ns polyvore.planet.orbit
  (:import [UnityEngine GameObject Transform])
  (:require [arcadia
             [core :refer :all]
             [linear :refer :all]]
            [polyvore.util
             [lang :refer :all]
             [arcadia :refer :all]]))

(def default-speed 0.25)
(def default-axis (v3 0.0 1.0 0.0))

(defn init-state! [^GameObject obj]
  (doto obj
    (set-state! ::self {::origin obj
                        ::active? true
                        ::speed default-speed
                        ::axis default-axis})
    (set-state! ::other {::origin (placeholder GameObject)
                         ::active? false
                         ::speed default-speed
                         ::axis default-axis})))

; TODO: Handle this with parenting -- the player must be added as a child of the planet
; TODO: Use colliders/triggers to determine which planet is active

(defn fixed-update! [^GameObject planet]
  (let [planet-state (state planet)]
    (doseq [orbit (mapv planet-state [::self ::other])]
      (when (::active? orbit)
        (.. planet
            transform
            (RotateAround (.. (::origin orbit) transform position)
                          (::axis orbit)
                          (::speed orbit)))))))
