;;;; ***********************************************************************
;;;; FILE IDENTIFICATION
;;;;
;;;; Name:          package.lisp
;;;; Project:       folio - Bard features in Common Lisp
;;;; Purpose:       taps package
;;;; Author:        mikel evins
;;;; Copyright:     2013 by mikel evins
;;;;
;;;; ***********************************************************************

(in-package :cl-user)

(defpackage :net.bardcode.folio.taps
  (:use :cl :net.bardcode.folio.as :net.bardcode.folio.make)
  (:export
   :characters
   :elements
   :lines
   :octets
   :slots
   :tokens))


