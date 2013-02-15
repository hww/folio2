;;;; ***********************************************************************
;;;; FILE IDENTIFICATION
;;;;
;;;; Name:          package-common.lisp
;;;; Project:       folio - the Bard runtime
;;;; Purpose:       all external names used by folio packages 
;;;; Author:        mikel evins
;;;; Copyright:     2013 by mikel evins
;;;;
;;;; ***********************************************************************

(in-package :cl-user)

(defpackage :net.bardcode.folio.common
  (:shadow :adjoin :append :apply :find :first :get :last :length :map :merge :position :put 
           :reduce :remove :rest :reverse :second :sequence :sort :union)
  (:use :cl)
  (:export :$ :^ :-> :> :>= :< :<=
           :adjoin :add-first :add-last :alist :alist->plist :any :append :append2 :apply :as :associate
           :box :box? :by
           :cascade :coalesce :combined-type :compose :concat :conjoin :contains-key? :contains-value? :cycle
           :difference :disjoin :dissociate :drop :dropn :drop-while 
           :element :empty? :every? 
           :filter :find :first :flip :fn 
           :generate :get-key
           :indexes :interleave :interpose :intersect
           :join :join2 :join-text
           :keys
           :last :left :length
           :make :map :merge
           :next-last
           :ordered-map
           :pair :pair? :partial :partition :plist :plist->alist :position :position-if :put-key
           :range :range-from :reduce :remove :repeat :rest :reverse :right :rotate-left :rotate-right :rpartial
           :scan :scan-map :second :select :sequence :sequence? :set-box! :shuffle :slice :some?
           :sort :split :split-text :subsequence :subset?
           :table :tails :take :take-by :take-while :taken :type-for-copy
           :unbox :union :unique :unzip
           :vals
           :zip :zipmap))
