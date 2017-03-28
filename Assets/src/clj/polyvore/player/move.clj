(ns polyvore.player.move
  (:import [UnityEngine
            GameObject
            Input KeyCode
            Vector3
            CharacterController
            Time Physics])
  (:require [arcadia
             [core :refer :all]
             [linear :refer :all]]
            [polyvore.util.lang :refer :all]))

(defn init-state! [^GameObject obj]
  (doto obj
    (set-state! ::speed 1.0)
    (set-state! ::jump-height 20.0)))

(defn get-inputs! []
  (->> (mapv #(vector % (Input/GetKey %))
             [KeyCode/W KeyCode/A KeyCode/S KeyCode/D KeyCode/Space])
       (filter #(true? (second %)))
       (into {})))

(defn calculate-diff [obj-state inputs]
  (let [diff (reduce (fn [acc v]
                       (case-enum (first v)
                         KeyCode/W (do (update! (.z acc) inc-float) acc)
                         KeyCode/S (do (update! (.z acc) dec-float) acc)
                         KeyCode/A (do (update! (.x acc) dec-float) acc)
                         KeyCode/D (do (update! (.x acc) inc-float) acc)
                         KeyCode/Space (do
                                         (update! (.y acc)
                                                  #(-> (::jump-height obj-state)
                                                       (+ %)
                                                       float))
                                           acc)))
                     (v3 0.0)
                     inputs)
        adjusted-diff (v3* (v3* diff (::speed obj-state)) Time/deltaTime)]
    adjusted-diff))

(defn fixed-update! [^GameObject obj]
  ; TODO: Apply diff
  (let [diff (calculate-diff (state obj) (get-inputs!))]
    ;(.Move (ensure-cmpt obj CharacterController) diff)
    ))
