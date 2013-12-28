;;;; ***********************************************************************
;;;; FILE IDENTIFICATION
;;;;
;;;; Name:          package.lisp
;;;; Project:       folio - the Bard runtime
;;;; Purpose:       scanning streams
;;;; Author:        mikel evins
;;;; Copyright:     2013 by mikel evins
;;;;
;;;; ***********************************************************************

(defpackage :net.bardcode.folio.streams
  (:use :cl :net.bardcode.folio.common)
  (:shadowing-import-from :net.bardcode.folio.common
                          :> :>= :< :<=
                          :adjoin :append :apply :find :first :get :intersection :last :length :merge :position :position-if :put 
                          :reduce :remove :rest :reverse :search :second :sequence :sort :union)
  (:import-from :net.bardcode.folio.common
                :as))



