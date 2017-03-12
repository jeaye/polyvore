(ns polyvore.player.input
  (:import [UnityEngine Input KeyCode
            Vector3
            CharacterController
            Time Physics])
  (:require [arcadia
             [core :refer :all]
             [linear :refer :all]]))

(defmacro update! [field fun]
  `(set! ~field (~fun ~field)))

(def inc-float (comp float inc))
(def dec-float (comp float dec))

(def speed 1.0)

(defn move! [obj]
  (let [pressed (->> (mapv #(vector % (Input/GetKey %))
                           [KeyCode/W KeyCode/A KeyCode/S KeyCode/D])
                     (filter #(true? (second %)))
                     (into {}))
        diff (reduce (fn [acc v]
                       (condp = (first v)
                         KeyCode/W (do (update! (.z acc) inc-float) acc)
                         KeyCode/S (do (update! (.z acc) dec-float) acc)
                         KeyCode/A (do (update! (.x acc) dec-float) acc)
                         KeyCode/D (do (update! (.x acc) inc-float) acc)))
                     (v3 0.0 (.y Physics/gravity) 0.0)
                     pressed)
        adjusted-diff (v3* (v3* diff speed) Time/deltaTime)]
    (.. (cmpt obj UnityEngine.CharacterController) (Move adjusted-diff))))
