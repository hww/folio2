;;;; ***********************************************************************
;;;; FILE IDENTIFICATION
;;;;
;;;; Name:          functions.lisp
;;;; Project:       folio - the Bard runtime
;;;; Purpose:       functions that accept and produce
;;;;                sequences, series, generators, and streams
;;;; Author:        mikel evins
;;;; Copyright:     2013 by mikel evins
;;;;
;;;; ***********************************************************************

;;; ---------------------------------------------------------------------
;;; ABOUT
;;; ---------------------------------------------------------------------
;;; operations on sequences as sets

(in-package #:net.bardcode.folio.sets)

;;; ---------------------------------------------------------------------
;;; function adjoin 
;;; ---------------------------------------------------------------------
;;;
;;; (adjoin item set1) => set2
;;; ---------------------------------------------------------------------
;;; returns a new set that contains X prepended to the elements of
;;; SET

(defmethod adjoin (item (set null) &key test key)
  (declare (ignore item set))
  (list item))

(defmethod adjoin (item (set cl:cons) &key (test 'equal) key)
  (cl:adjoin item set :test test :key key))

(defmethod adjoin (item (set cl:vector) &key (test 'equal) key)
  (let ((already (cl:find item set :key key :test test)))
    (if already
        set
        (coerce (cons item (coerce set 'cl:list)) 'cl:vector))))

(defmethod adjoin (item (set cl:string) &key (test 'equal) key)
  (error "no applicable method for ADJOIN with arguments: (~S ~S)"
         (class-of item)(class-of set)))

(defmethod adjoin ((item cl:character) (set cl:string) &key (test 'equal) key)
  (let ((already (cl:find item set :key key :test test)))
    (if already
        set
        (coerce (cons item (coerce set 'cl:list)) 'cl:string))))

(defmethod adjoin (item (set fset:set) &key (test 'equal) key)
  (let ((already (fset:find item set :key key :test test)))
    (if already
        set
        (fset:with-first set item))))

(defmethod adjoin (item (set foundation-series) &key (test 'equal) key)
  (error "no applicable method for ADJOIN with arguments: (~S ~S)"
         (class-of item)(class-of set)))

;;; function as
;;;
;;; (as 'set x) => an instance of type
;;; ---------------------------------------------------------------------

(defmethod as ((type (eql 'cl:set)) (val cl:sequence) &key &allow-other-keys)
  (cl:remove-duplicates (coerce val 'cl:list)
                        :test 'cl:equal))

;;; ---------------------------------------------------------------------
;;; function difference
;;; ---------------------------------------------------------------------
;;;
;;; (difference set1 set2) => set3
;;; ---------------------------------------------------------------------
;;; returns a new set that contains the elements of SET1 that are
;;; not in SET2

(defmethod difference ((set1 null) set2 &key key test) 
  (declare (ignore set1))
  nil)

(defmethod difference (set1 (set2 null) &key key test) 
  (declare (ignore set2))
  set1)

(defmethod difference ((set1 cl:sequence) (set2 cl:sequence) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:set-difference (cl:coerce set1 'cl:list)
                     (cl:coerce set2 'cl:list)
                     :key key :test test))

(defmethod difference ((set1 cl:sequence) (set2 seq) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:set-difference (cl:coerce set1 'cl:list)
                     (fset:convert 'cl:list set2)
                     :key key :test test))

(defmethod difference ((set1 cl:sequence) (set2 foundation-series) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:set-difference (cl:coerce set1 'cl:list)
                     (series:collect 'cl:list set2)
                     :key key :test test))

(defmethod difference ((set1 seq) (set2 cl:sequence) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:set-difference (fset:convert 'cl:list set1)
                     (cl:coerce set2 'cl:list)
                     :key key :test test))

(defmethod difference ((set1 seq) (set2 seq) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:set-difference (fset:convert 'cl:list set1)
                     (fset:convert 'cl:list set2)
                     :key key :test test))

(defmethod difference ((set1 seq) (set2 foundation-series) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:set-difference (fset:convert 'cl:list set1)
                     (series:collect 'cl:list set2)
                     :key key :test test))

(defmethod difference ((set1 foundation-series) (set2 cl:sequence) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:set-difference (series:collect 'cl:list set1)
                     (cl:coerce set2 'cl:list)
                     :key key :test test))

(defmethod difference ((set1 foundation-series) (set2 seq) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:set-difference (series:collect 'cl:list set1)
                     (fset:convert 'cl:list set2)
                     :key key :test test))

(defmethod difference ((set1 foundation-series) (set2 foundation-series) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:set-difference (series:collect 'cl:list set1)
                     (series:collect 'cl:list set2)
                     :key key :test test))


;;; ---------------------------------------------------------------------
;;; function intersection
;;; ---------------------------------------------------------------------
;;;
;;; (intersection set1 set2) => set3
;;; ---------------------------------------------------------------------
;;; returns a sequence that contains those elements that appear in both 
;;; SET1 and SET2

(defmethod intersection ((set1 null) set2 &key key test) 
  (declare (ignore set1))
  nil)

(defmethod intersection (set1 (set2 null) &key key test) 
  (declare (ignore set2))
  set1)

(defmethod intersection ((set1 cl:sequence) (set2 cl:sequence) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:intersection (cl:coerce set1 'cl:list)
                   (cl:coerce set2 'cl:list)
                   :key key :test test))

(defmethod intersection ((set1 cl:sequence) (set2 seq) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:intersection (cl:coerce set1 'cl:list)
                   (fset:convert 'cl:list set2)
                   :key key :test test))

(defmethod intersection ((set1 cl:sequence) (set2 foundation-series) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:intersection (cl:coerce set1 'cl:list)
                   (series:collect 'cl:list set2)
                   :key key :test test))

(defmethod intersection ((set1 seq) (set2 cl:sequence) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:intersection (fset:convert 'cl:list set1)
                   (cl:coerce set2 'cl:list)
                   :key key :test test))

(defmethod intersection ((set1 seq) (set2 seq) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:intersection (fset:convert 'cl:list set1)
                   (fset:convert 'cl:list set2)
                   :key key :test test))

(defmethod intersection ((set1 seq) (set2 foundation-series) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:intersection (fset:convert 'cl:list set1)
                   (series:collect 'cl:list set2)
                   :key key :test test))

(defmethod intersection ((set1 foundation-series) (set2 cl:sequence) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:intersection (series:collect 'cl:list set1)
                   (cl:coerce set2 'cl:list)
                   :key key :test test))

(defmethod intersection ((set1 foundation-series) (set2 seq) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:intersection (series:collect 'cl:list set1)
                   (fset:convert 'cl:list set2)
                   :key key :test test))

(defmethod intersection ((set1 foundation-series) (set2 foundation-series) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:intersection (series:collect 'cl:list set1)
                   (series:collect 'cl:list set2)
                   :key key :test test))


;;; ---------------------------------------------------------------------
;;; function make
;;; ---------------------------------------------------------------------
;;;
;;; (make 'set &rest args) => args'
;;; ---------------------------------------------------------------------
;;; create a set

(defmethod make ((type (eql 'set)) &key (elements nil) &allow-other-keys)
  (cl:remove-duplicates elements :test 'equal))

;;; ---------------------------------------------------------------------
;;; function union
;;; ---------------------------------------------------------------------
;;;
;;; (union set1 set2) => set3
;;; ---------------------------------------------------------------------
;;; returns a set that contains all elements that appear either in
;;; SET1 or in SET2

(defmethod union ((set1 null) set2 &key key test) 
  (declare (ignore set1))
  nil)

(defmethod union (set1 (set2 null) &key key test) 
  (declare (ignore set2))
  set1)

(defmethod union ((set1 cl:sequence) (set2 cl:sequence) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:union (cl:coerce set1 'cl:list)
                   (cl:coerce set2 'cl:list)
                   :key key :test test))

(defmethod union ((set1 cl:sequence) (set2 seq) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:union (cl:coerce set1 'cl:list)
                   (fset:convert 'cl:list set2)
                   :key key :test test))

(defmethod union ((set1 cl:sequence) (set2 foundation-series) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:union (cl:coerce set1 'cl:list)
                   (series:collect 'cl:list set2)
                   :key key :test test))

(defmethod union ((set1 seq) (set2 cl:sequence) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:union (fset:convert 'cl:list set1)
                   (cl:coerce set2 'cl:list)
                   :key key :test test))

(defmethod union ((set1 seq) (set2 seq) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:union (fset:convert 'cl:list set1)
                   (fset:convert 'cl:list set2)
                   :key key :test test))

(defmethod union ((set1 seq) (set2 foundation-series) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:union (fset:convert 'cl:list set1)
                   (series:collect 'cl:list set2)
                   :key key :test test))

(defmethod union ((set1 foundation-series) (set2 cl:sequence) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:union (series:collect 'cl:list set1)
                   (cl:coerce set2 'cl:list)
                   :key key :test test))

(defmethod union ((set1 foundation-series) (set2 seq) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:union (series:collect 'cl:list set1)
                   (fset:convert 'cl:list set2)
                   :key key :test test))

(defmethod union ((set1 foundation-series) (set2 foundation-series) &key (key 'cl:identity) (test 'cl:equal)) 
  (cl:union (series:collect 'cl:list set1)
                   (series:collect 'cl:list set2)
                   :key key :test test))