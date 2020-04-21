(defpackage :fwoar.eval-args
  (:use :cl :clawk)
  (:export))
(in-package :fwoar.eval-args)

(defun ql (thing)
  (ql:quickload thing))

(defmacro squash (&body forms)
  `(let ((*standard-output* (make-broadcast-stream)))
     ,@forms))

(defmacro -> (&rest forms)
  `(uiop:nest ,@forms))

(defmacro s (&body forms)
  `(with-output-to-string (*standard-output*)
     ,@forms))

(defun o2s (it)
  (babel:octets-to-string it))

(defun translate-cons-call-to-funcall (form)
  (agnostic-lizard:walk-form form nil
                             :on-function-form-pre (lambda (f a)
                                                     (declare (ignore a))
                                                     (if (and (consp f)
                                                              (consp (car f)))
                                                         (list* 'funcall f)
                                                         f))))

(defmethod fwoar.utilitas:main progn ((arg0 (eql :eval-args)) args)
  (let* ((code (-> (substitute #\( #\[)
                 (substitute #\) #\])
                 (format nil "(~{~a~^ ~})" args)))
         (*random-state* (make-random-state t))
         (*package* (find-package :fwoar.eval-args))
         (values (multiple-value-list
                  (eval
                   (translate-cons-call-to-funcall
                    (read-from-string code))))))

    (fresh-line)
    (mapc (lambda (it)
            (princ it)
            (fresh-line))
          values))
  (fresh-line))
