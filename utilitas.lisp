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

(defun probe-system (selector)
  (handler-bind ((warning 'muffle-warning))
    (cond ((asdf:find-system selector nil)
           (asdf:load-system selector)
           :success)
          ((ql-dist:find-system selector)
           (ql:quickload selector)
           :success)
          (t nil))))

(defun handle-dump (args)
  (let ((new-name (elt args (1+ (position "--fwoar-dump" args :test #'equal)))))
    (setf sb-sys:*shared-objects* nil)
    (setf uiop:*image-entry-point* 'run-toplevel)
    (uiop:dump-image new-name
                     :executable t)))

(defun start-repl (warning selector)
  (#+sbcl warn #-sbcl error warning selector)
  #+sbcl
  (return-from start-repl
    (sb-impl::toplevel-init)))

(defun toplevel-designator (string)
  (intern (string-upcase string)
          :keyword))

(defun run-toplevel ()
  (asdf:initialize-source-registry)
  (setf *trace-output* (make-broadcast-stream))
  (mapcar 'asdf:load-asd
          (directory "*.asd"))
  (destructuring-bind (arg0 . args) sb-ext:*posix-argv*
    (let ((selector (toplevel-designator (trim-argv0 arg0))))
      (if (probe-system selector)
          (if (member "--fwoar-dump" args :test #'equal)
              (handle-dump args)
              (if (compute-applicable-methods (symbol-function 'main)
                                              (list selector nil))
                  (main selector args)
                  (start-repl "no applicable toplevel for ~s found, starting a repl"
                              selector)))
          (if (member "--fwoar-dump" args :test #'equal)
              (handle-dump args)
              (start-repl "no system for ~s found, starting a repl"
                          selector))))))

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
