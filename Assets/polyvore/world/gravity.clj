(ns polyvore.world.gravity
  (:import [UnityEngine GameObject Time Mathf Physics Collider Rigidbody ForceMode])
  (:require [arcadia
             [core :refer :all]
             [linear :refer :all]]
            [polyvore.util.lang :refer :all]))

; TODO: state
(def radius 110.0)
(def mass 100000.0)
(def G 1.0)

(defn gravitation [mass-1 mass-2 distance]
  (* G (/ (* mass-1 mass-2)
          (* distance distance))))

(defn fixed-update! [^GameObject world]
  (let [world-transform (.transform world)
        world-position (.position world-transform)
        affected (Physics/OverlapSphere world-position radius)]
    (doseq [^Collider collider affected]
      (let [difference (v3- world-position (.. collider transform position))]
        (when-let [body (.attachedRigidbody collider)]
          (let [g-force (gravitation mass (.mass body) (.magnitude difference))
                normal-force (-> (.normalized difference)
                                 (v3* g-force))]
            (.. body (AddForce (v3* normal-force Time/deltaTime)))))))))
