;;;; ***********************************************************************
;;;;
;;;; Name:          folio-as.asd
;;;; Project:       folio - Functional idioms for Common Lisp
;;;; Purpose:       folio-as: an extensible type-conversion utility
;;;; Author:        mikel evins
;;;; Copyright:     2015 by mikel evins
;;;;
;;;; ***********************************************************************

(in-package :cl-user)

;;; system
(asdf:defsystem :folio-as
  :serial t
  :description "uniform tools for converting values from one type to another"
  :author "mikel evins <mevins@me.com>"
  :license "Lisp Lesser GNU Public License"
  :components ((:module "src"
                        :serial t
                        :components ((:file "as-package")
                                     (:file "as-functions")))))

;;; (asdf:load-system :folio-as)
