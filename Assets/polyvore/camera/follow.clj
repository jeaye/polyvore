(ns polyvore.camera.follow
  (:import [UnityEngine GameObject Transform Vector3 Quaternion Time])
  (:require [arcadia
             [core :refer :all]
             [linear :refer :all]]
            [polyvore.solar-system :as solar-system]
            [polyvore.util
             [lang :refer :all]
             [arcadia :refer :all]]))

(defn init-state! [^GameObject camera]
  (doto camera
    (set-state! ::target (placeholder Transform))
    (set-state! ::distance 10.0)
    (set-state! ::height 3.0)
    (set-state! ::translation-damping 1.0)
    (set-state! ::rotation-damping 1.0)
    (set-state! ::smooth-rotation? true)
    (set-state! ::behind? true)))

; TODO: Refactor into helper functions
; TODO: Using world space for up/forward is an issue while orbiting
(defn fixed-update! [^GameObject camera]
  (let [camera-state (state camera)
        target-transform (.transform (::target camera-state))
        cam-transform (.transform camera)
        planet-transform (.transform (solar-system/closest-planet target-transform))
        up (v3- (.position target-transform) (.position planet-transform))
        offset-direction (if (::behind? camera-state) -1.0 1.0)
        offset (let [off-up (v3* (.normalized up) (::height camera-state))
                     off-back (v3* (v3- (.forward target-transform))
                                   (* offset-direction (::distance camera-state)))]
                 (v3+ off-up off-back))
        wanted (.. target-transform (TransformPoint offset))]
    (update! (.position cam-transform)
             #(Vector3/Lerp % wanted (* Time/deltaTime
                                        (::translation-damping camera-state))))
    (if (::smooth-rotation? camera-state)
      (let [wanted-rotation (Quaternion/LookRotation (v3- (.position target-transform)
                                                          (.position cam-transform))
                                                     up)]
        (update! (.rotation cam-transform)
                 #(Quaternion/Slerp % wanted-rotation
                                    (* Time/deltaTime
                                       (::rotation-damping camera-state))))))
      (.. cam-transform (LookAt target-transform up))))
