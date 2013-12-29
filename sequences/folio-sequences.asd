;;;; ***********************************************************************
;;;; FILE IDENTIFICATION
;;;;
;;;; Name:          folio-sequences.asd
;;;; Project:       folio - Bard features for Common Lisp
;;;; Purpose:       system definition for folio.sequences
;;;; Author:        mikel evins
;;;; Copyright:     2013 by mikel evins
;;;;
;;;; ***********************************************************************

(in-package :cl-user)

(require :asdf)

(asdf:defsystem :net.bardcode.folio.sequences
  :serial t
  :description "operations on sequences of values"
  :license "Lisp Lesser GNU Public License"
  :depends-on (:net.bardcode.folio.as
               :net.bardcode.folio.make
               :fset :series)
  :components ((:module "src"
                        :serial t
                        :components ((:file "package")
                                     (:file "functions-sequences")
                                     (:file "functions-series")))))

(asdf:defsystem :net.bardcode.folio.sequences.tests
  :serial t
  :description "sequence and series tests"
  :license "Lisp Lesser GNU Public License"
  :depends-on (:net.bardcode.folio.sequences :lift)
  :components ((:module "tests"
                        :serial t
                        :components ((:file "sequences")
                                     (:file "series")))))

(defun load-sequences ()
  (asdf:oos 'asdf:load-op :net.bardcode.folio.sequences))

(defun load-sequence-tests ()
  (asdf:oos 'asdf:load-op :net.bardcode.folio.sequences.tests))

;;; (load-sequences)
;;; (load-sequence-tests)