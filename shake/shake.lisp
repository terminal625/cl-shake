(in-package #:shake)

(defun main ()
  (sdl2:with-init (:video)
    (set-gl-attrs)
    (sdl2:with-window (win :title "shake" :flags '(:shown :opengl))
      (sdl2:with-gl-context (context win)
        (print-gl-info)
        (let ((vertex-array (gl:gen-vertex-array))
              (shader-prog (load-shader #P"shaders/pass.vert"
                                        #P"shaders/color.frag")))
          (gl:use-program shader-prog)
          (sdl2:with-event-loop (:method :poll)
            (:quit () t)
            (:idle ()
                   (render win vertex-array))))))))

(defun set-gl-attrs ()
  "Set OpenGL context attributes. This needs to be called before window
  and context creation."
  (sdl2:gl-set-attr :context-major-version 3)
  (sdl2:gl-set-attr :context-minor-version 3)
  ;; set CONTEXT_FORWARD_COMPATIBLE
  (sdl2:gl-set-attr :context-flags #x2)
  ;; set CONTEXT_PROFILE_CORE
  (sdl2:gl-set-attr :context-profile-mask #x1))

(defun print-gl-info ()
  "Print basic OpenGL information."
  (let ((vendor (gl:get-string :vendor))
        (renderer (gl:get-string :renderer))
        (gl-version (gl:get-string :version))
        (glsl-version (gl:get-string :shading-language-version)))
    (format t "GL Vendor: ~S~%" vendor)
    (format t "GL Renderer: ~S~%" renderer)
    (format t "GL Version: ~S~%" gl-version)
    (format t "GLSL Version: ~S~%" glsl-version)
    (finish-output)))

(defun load-shader (vs-file fs-file)
  "Return shader program, created from given VS-FILE and FS-FILE paths to a
  vertex shader and fragment shader, respectively."
  (let* ((vs-src (read-file-into-string vs-file))
         (fs-src (read-file-into-string fs-file))
         (vs (compile-shader vs-src :vertex-shader))
         (fs (compile-shader fs-src :fragment-shader)))
    (link-program fs vs)))

(defun compile-shader (source type)
  "Create a shader of given TYPE, compiled with given SOURCE string."
  (let ((shader (gl:create-shader type)))
    (gl:shader-source shader source)
    (gl:compile-shader shader)
    (print (gl:get-shader-info-log shader))
    shader))

(defun link-program (shader &rest shaders)
  "Create a program, linked with given SHADER objects."
  (let ((program (gl:create-program)))
    (dolist (sh (cons shader shaders))
      (gl:attach-shader program sh))
    (gl:link-program program)
    (print (gl:get-program-info-log program))
    program))

(defun render (win vertex-array)
  (gl:bind-vertex-array vertex-array)
  (gl:vertex-attrib 0 0)
  (clear-buffer-fv :color 0 0 0 0)
  (gl:draw-arrays :points 0 1)
  (sdl2:gl-swap-window win)
  (gl:bind-vertex-array 0))

(defun clear-buffer-fv (buffer drawbuffer &rest values)
  (let ((len (list-length values)))
    (cffi:with-foreign-object (value-ptr :float len)
      (loop for i below len and val in values
         do (setf (cffi:mem-aref value-ptr :float i) (coerce val 'single-float)))
      (%gl:clear-buffer-fv buffer drawbuffer value-ptr))))
