;;;; ***********************************************************************
;;;;
;;;; Name:          package.lisp
;;;; Project:       folio2 - Functional idioms for Common Lisp
;;;; Purpose:       boxes package
;;;; Author:        mikel evins
;;;; Copyright:     2015 by mikel evins
;;;;
;;;; ***********************************************************************

(in-package :cl-user)

(defpackage :net.bardcode.folio2.boxes
  (:use :cl :net.bardcode.folio2.as :net.bardcode.folio2.make)
  (:export :box :box? :set-box! :unbox))
