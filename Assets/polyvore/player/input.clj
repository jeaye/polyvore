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

(defmacro case-enum
  "Like `case`, but explicitly dispatch on native enum ordinals."
  [e & clauses]
  (letfn [(enum-ordinal [e] `(let [^Enum e# ~e] (int e#)))]
    `(case ~(enum-ordinal e)
       ~@(concat
           (mapcat (fn [[test result]]
                     [(eval (enum-ordinal test)) result])
                   (partition 2 clauses))
           (when (odd? (count clauses))
             (list (last clauses)))))))

(def inc-float (comp float inc))
(def dec-float (comp float dec))

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

(defn move! [obj]
  (.. (cmpt obj UnityEngine.CharacterController)
      (Move (move (get-inputs!)))))
