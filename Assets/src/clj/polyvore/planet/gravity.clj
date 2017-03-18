(ns polyvore.planet.gravity
  (:import [UnityEngine GameObject
            Time Mathf Physics Collider Rigidbody ForceMode])
  (:require [arcadia
             [core :refer :all]
             [linear :refer :all]]
            [polyvore.util.lang :refer :all]))

(defn init-state! [^GameObject obj]
  (doto obj
    (set-state! ::radius 100.0)
    (set-state! ::mass 100000.0)
    (set-state! ::G 1.0)))

(defn gravitation [mass-1 mass-2 distance G]
  (* G (/ (* mass-1 mass-2)
          (* distance distance))))

(defn fixed-update! [^GameObject planet]
  (let [planet-state (state planet)
        planet-transform (.transform planet)
        planet-position (.position planet-transform)
        affected (Physics/OverlapSphere planet-position (::radius planet-state))]
    (doseq [^Collider collider affected]
      (let [difference (v3- planet-position (.. collider transform position))]
        (when-let [body (.attachedRigidbody collider)]
          (let [g-force (gravitation (::mass planet-state) (.mass body)
                                     (.magnitude difference) (::G planet-state))
                normal-force (-> (.normalized difference)
                                 (v3* g-force))]
            (.. body (AddForce (v3* normal-force Time/deltaTime)))))))))
