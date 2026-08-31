# ningle-admin

A declarative CRUD admin interface generator for Common Lisp applications built with [Ningle](https://github.com/fukamachi/ningle), [Mito](https://github.com/fukamachi/mito), [Djula](https://github.com/mmontone/djula), and [cl-forms](https://github.com/mmontone/cl-forms).

## Features

- **Declarative Resource Registration**: Register Mito models with one clean call: `(ningle-admin:register :resource-name ...)`.
- **Pluggable Authentication**: Completely auth-agnostic via `*auth-check*` hook.
- **Extensible CLOS Protocol**: Override `ningle-admin:list`, `ningle-admin:get`, `ningle-admin:save`, `ningle-admin:delete`, or `ningle-admin:populate-form` only when custom behavior is needed.
- **Dynamic Route Mounting**: `(ningle-admin:mount *app*)` automatically attaches full RESTful CRUD routes to your Ningle application.
- **Built-in Pagination**: Integrates seamlessly with `mito-pager`.

## Installation

Add to your `qlfile`:

```
github nmunro/ningle-admin :branch main
```

Or clone into your Quicklisp `local-projects/` directory.

## Quick Start

```lisp
;; 1. Register a resource
(ningle-admin:register :products
  :model 'my-app/models:product
  :form 'my-app/forms:product-form
  :url-prefix "/admin/products"
  :template-list "admin/products.html"
  :template-view "admin/product.html"
  :template-add "admin/product-add.html")

;; 2. Mount onto your Ningle app
(ningle-admin:mount *app*
  :auth-check (lambda ()
                (unless (is-admin-p)
                  (error "Unauthorized"))))
```

## Generic Protocol Extension Points

```lisp
;; Custom form binding
(defmethod ningle-admin:populate-form ((res (eql (ningle-admin:find-resource :products))) form product)
  (cl-forms:set-field-value form 'my-forms:name (my-models:name product)))

;; Custom save logic
(defmethod ningle-admin:save ((res (eql (ningle-admin:find-resource :products))) params &optional id)
  ...)

;; Custom delete logic
(defmethod ningle-admin:delete ((res (eql (ningle-admin:find-resource :users))) id)
  ...)
```

## License

BSD 3-Clause.
