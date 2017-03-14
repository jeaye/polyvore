(ns polyvore.camera.follow
  (:import [UnityEngine Vector3 Quaternion Time])
  (:require [arcadia
             [core :refer :all]
             [linear :refer :all]]
            [polyvore.util.lang :refer :all]))

(def distance 10.0)
(def height 3.0)
(def damping 1.0)
(def smooth-rotation true)
(def follow-behind true)
(def rotation-damping 1.0)

(defn fixed-update! [obj]
  (let [target (.transform (object-named "player")) ; TODO state
        transform (.transform obj)
        behind (if follow-behind -1.0 1.0)
        wanted (.. target (TransformPoint 0.0 height (* behind distance)))]
    (update! (.position transform)
             #(Vector3/Lerp % wanted (* Time/deltaTime damping)))
    (if smooth-rotation
      (let [wanted-rotation (Quaternion/LookRotation (v3- (.position target)
                                                          (.position transform))
                                                     (.up target))]
        (update! (.rotation transform)
                 #(Quaternion/Slerp % wanted-rotation
                                    (* Time/deltaTime rotation-damping)))))
      (.. transform (LookAt target (.up target)))))
