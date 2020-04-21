(defpackage :fwoar.utilitas
  (:use :cl )
  (:export main))
(in-package :fwoar.utilitas)

(defgeneric main (arg0 args)
  (:method-combination progn)
  (:documentation "To define your application's entrypoint, Specialize
  this method with an eql selector for ARG0.

ARG0: a keyword that indicates your application name"))

(defun trim-argv0 (argv0)
  (pathname-name argv0))

(defun run-toplevel ()
  (asdf:initialize-source-registry)
  (setf *trace-output* (make-broadcast-stream))
  (destructuring-bind (arg0 . args) sb-ext:*posix-argv*
    (let ((selector (intern (string-upcase (trim-argv0 arg0))
                            :keyword)))
      (if (cond ((asdf:find-system selector nil)
                 (asdf:load-system selector)
                 :success)
                ((ql-dist:find-system selector)
                 (ql:quickload selector)
                 :success)
                (t nil))
          (if (member "--fwoar-dump" args :test #'equal)
              (let ((new-name (elt args (1+ (position "--fwoar-dump" args :test #'equal)))))
                (setf sb-sys:*shared-objects* nil)
                (setf uiop:*image-entry-point* 'run-toplevel)
                (uiop:dump-image new-name
                                 :executable t))
              (if (compute-applicable-methods (symbol-function 'main)
                                              (list selector nil))
                  (main selector args)
                  (progn (warn "no applicable toplevel for ~s found, starting a repl"
                               selector)
                         (sb-impl::toplevel-init))))
          (if (member "--fwoar-dump" args :test #'equal)
              (let ((new-name (elt args (1+ (position "--fwoar-dump" args :test #'equal)))))
                (setf sb-sys:*shared-objects* nil)
                (setf uiop:*image-entry-point* 'run-toplevel)
                (uiop:dump-image new-name
                                 :executable t))
              (progn (warn "no system for ~s found, starting a repl"
                           selector)
                     (sb-impl::toplevel-init)))))))

#+(:and sbcl fw.dev)
(defun save-core (core-fn)
  (progn
    #+sbcl
    (let ((fork-result (sb-posix:fork)))
      (case fork-result
        (-1 (error "fork failed"))
        (0 (sb-ext:save-lisp-and-die core-fn :toplevel #'fwoar.utilitas::run-toplevel :executable t))
        (otherwise (sb-posix:wait)))
      (format t "stand-alone core ~a saved" core-fn))
    #-sbcl
    (error "not available on this lisp")
    (values)))
