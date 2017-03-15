(ns polyvore.camera.follow
  (:import [UnityEngine GameObject Vector3 Quaternion Time])
  (:require [arcadia
             [core :refer :all]
             [linear :refer :all]]
            [polyvore.util.lang :refer :all]))

(defn init-state! [^GameObject obj]
  (doto obj
    (set-state! ::target (.transform (object-named "player")))
    (set-state! ::distance 10.0)
    (set-state! ::height 3.0)
    (set-state! ::translation-damping 1.0)
    (set-state! ::rotation-damping 1.0)
    (set-state! ::smooth-rotation? true)
    (set-state! ::behind? true)))

(defn fixed-update! [^GameObject obj]
  (let [obj-state (state obj)
        target (::target obj-state)
        transform (.transform obj)
        behind (if (::behind? obj-state) -1.0 1.0)
        wanted (.. target (TransformPoint 0.0
                                          (::height obj-state)
                                          (* behind (::distance obj-state))))]
    (update! (.position transform)
             #(Vector3/Lerp % wanted (* Time/deltaTime
                                        (::translation-damping obj-state))))
    (if (::smooth-rotation? obj-state)
      (let [wanted-rotation (Quaternion/LookRotation (v3- (.position target)
                                                          (.position transform))
                                                     (.up target))]
        (update! (.rotation transform)
                 #(Quaternion/Slerp % wanted-rotation
                                    (* Time/deltaTime
                                       (::rotation-damping obj-state))))))
      (.. transform (LookAt target (.up target)))))
