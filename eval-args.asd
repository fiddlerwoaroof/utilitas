;;; -*- Mode:Lisp; Syntax:ANSI-Common-Lisp; Package: ASDF-USER -*-
(in-package :asdf-user)

(defsystem :eval-args
  :description ""
  :author "Ed L <edward@elangley.org>"
  :license "MIT"
  :depends-on (#:alexandria
               #:agnostic-lizard
               #:clawk
               #:drakma
               #:serapeum
               #:uiop)
  :serial t
  :components ((:file "eval-args")))
