(defpackage ningle-admin/controllers
  (:use :cl
        :ningle-admin/conditions
        :ningle-admin/resource)
  (:shadowing-import-from :ningle-admin/resource #:list #:get #:delete)
  (:export #:*app*
           #:*auth-check*
           #:*mount-path*
           #:*render-fn*
           #:def-controller
           #:attach-resource-routes
           #:render-list
           #:render-add
           #:render-view
           #:execute-save
           #:execute-delete))

(in-package :ningle-admin/controllers)

(defvar *app* (make-instance 'ningle:<app>))
(defvar *mount-path* "/admin")
(defvar *auth-check* (lambda () t))
(defvar *render-fn* #'djula:render-template*)

(defmacro def-controller (name args &body body)
  (multiple-value-bind (remaining-forms declarations doc-string)
      (alexandria:parse-body body :documentation t)
    `(defun ,name ,args
       ,@(when doc-string (cl:list doc-string))
       ,@declarations
       (when *auth-check*
         (funcall *auth-check*))
       ,@remaining-forms)))

;;; ---------------------------------------------------------------------------
;;; Generic Controller Actions
;;; ---------------------------------------------------------------------------

(defun render-list (resource-name params &key (render-fn *render-fn*))
  (let* ((resource (find-resource resource-name))
         (page     (or (parse-integer (or (ingle:get-param "page" params) "1") :junk-allowed t) 1))
         (limit    (or (parse-integer (or (ingle:get-param "limit" params) "15") :junk-allowed t) 15)))
    (flet ((fetch (limit offset)
             (declare (ignore offset))
             (list resource :page page :limit limit :params params)))
      (mito-pager:with-pager ((items pager #'fetch :page page :limit limit))
        (let* ((data (if (resource-serializer resource)
                         (mapcar (resource-serializer resource) items)
                         items))
               (template (resource-template-list resource))
               (var-name (intern (format nil "~A" (resource-name resource)) :keyword)))
          (funcall render-fn template var-name data :pager pager :resource resource))))))

(defun render-add (resource-name params &key (render-fn *render-fn*))
  (declare (ignore params))
  (let ((resource (find-resource resource-name)))
    (if (resource-form resource)
        (let ((form (cl-forms:find-form (resource-form resource))))
          (setf (slot-value form 'cl-forms::action) (format nil "~A~A/new" *mount-path* (resource-url-prefix resource)))
          (funcall render-fn (resource-template-add resource) :form form :resource resource))
        (funcall render-fn (resource-template-add resource) :resource resource))))

(defun render-view (resource-name params &key (render-fn *render-fn*))
  (let* ((resource (find-resource resource-name))
         (id       (ingle:get-param :id params))
         (item     (get resource id))
         (form     (when (resource-form resource)
                     (cl-forms:find-form (resource-form resource))))
         (var-name (resource-template-var resource)))
    (when form
      (setf (slot-value form 'cl-forms::action) (format nil "~A~A/~A" *mount-path* (resource-url-prefix resource) id))
      (populate-form resource form item))
    (funcall render-fn (resource-template-view resource) var-name item :form form :resource resource)))

(defun execute-save (resource-name params)
  (let* ((resource (find-resource resource-name))
         (id       (ingle:get-param :id params)))
    (save resource params id)
    (ingle:redirect (format nil "~A~A" *mount-path* (resource-url-prefix resource)))))

(defun execute-delete (resource-name params)
  (let ((resource (find-resource resource-name))
        (id       (ingle:get-param :id params)))
    (delete resource id)
    (setf (lack.response:response-status ningle:*response*) 204)
    ""))

(defun attach-resource-routes (app resource)
  (let ((prefix (resource-url-prefix resource))
        (name   (resource-name resource)))

    ;; 1. List
    (setf (ningle:route app prefix :method :GET)
          (lambda (params)
            (when *auth-check* (funcall *auth-check*))
            (render-list name params :render-fn *render-fn*)))

    ;; 2. Add form
    (setf (ningle:route app (format nil "~A/new" prefix) :method :GET)
          (lambda (params)
            (when *auth-check* (funcall *auth-check*))
            (render-add name params :render-fn *render-fn*)))

    ;; 3. Create
    (setf (ningle:route app (format nil "~A/new" prefix) :method :POST)
          (lambda (params)
            (when *auth-check* (funcall *auth-check*))
            (execute-save name params)))

    ;; 4. View / Edit form
    (setf (ningle:route app (format nil "~A/:id" prefix) :method :GET)
          (lambda (params)
            (when *auth-check* (funcall *auth-check*))
            (render-view name params :render-fn *render-fn*)))

    ;; 5. Update
    (setf (ningle:route app (format nil "~A/:id" prefix) :method :POST)
          (lambda (params)
            (when *auth-check* (funcall *auth-check*))
            (execute-save name params)))

    ;; 6. Delete
    (setf (ningle:route app (format nil "~A/:id" prefix) :method :DELETE)
          (lambda (params)
            (when *auth-check* (funcall *auth-check*))
            (execute-delete name params)))))

;; Wire up auto-attaching of routes on registration
(setf ningle-admin/resource:*register-hook*
      (lambda (res)
        (attach-resource-routes *app* res)))

;; Attach routes for any pre-registered resources
(dolist (res (list-resources))
  (attach-resource-routes *app* res))
