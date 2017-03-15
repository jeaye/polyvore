(ns polyvore.world.gravity
  (:import [UnityEngine GameObject Time Mathf Physics Collider Rigidbody ForceMode])
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

(defn fixed-update! [^GameObject world]
  (let [world-state (state world)
        world-transform (.transform world)
        world-position (.position world-transform)
        affected (Physics/OverlapSphere world-position (::radius world-state))]
    (doseq [^Collider collider affected]
      (let [difference (v3- world-position (.. collider transform position))]
        (when-let [body (.attachedRigidbody collider)]
          (let [g-force (gravitation (::mass world-state) (.mass body)
                                     (.magnitude difference) (::G world-state))
                normal-force (-> (.normalized difference)
                                 (v3* g-force))]
            (.. body (AddForce (v3* normal-force Time/deltaTime)))))))))
