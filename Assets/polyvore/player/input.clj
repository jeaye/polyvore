(ns polyvore.player.input
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

(def speed 1.0)
(def jump-height 20.0)

(defn get-inputs! []
  (->> (mapv #(vector % (Input/GetKey %))
             [KeyCode/W KeyCode/A KeyCode/S KeyCode/D KeyCode/Space])
       (filter #(true? (second %)))
       (into {})))

(defn move [inputs]
  (let [diff (reduce (fn [acc v]
                       (case-enum (first v)
                         KeyCode/W (do (update! (.z acc) inc-float) acc)
                         KeyCode/S (do (update! (.z acc) dec-float) acc)
                         KeyCode/A (do (update! (.x acc) dec-float) acc)
                         KeyCode/D (do (update! (.x acc) inc-float) acc)
                         KeyCode/Space (do (update! (.y acc)
                                                    #(float (+ jump-height %)))
                                           acc)))
                     (v3 0.0 (.y Physics/gravity) 0.0)
                     inputs)
        adjusted-diff (v3* (v3* diff speed) Time/deltaTime)]
    adjusted-diff))

; TODO: Update ns name to move and call this fixed-update
(defn move! [^GameObject obj]
  (comment .. (cmpt obj CharacterController)
      (Move (move (get-inputs!)))))
