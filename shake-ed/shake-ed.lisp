;;;; Copyright (C) 2016 Teon Banek
;;;;
;;;; This program is free software; you can redistribute it and/or modify
;;;; it under the terms of the GNU General Public License as published by
;;;; the Free Software Foundation; either version 2 of the License, or
;;;; (at your option) any later version.
;;;;
;;;; This program is distributed in the hope that it will be useful,
;;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;;; GNU General Public License for more details.
;;;;
;;;; You should have received a copy of the GNU General Public License along
;;;; with this program; if not, write to the Free Software Foundation, Inc.,
;;;; 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

(in-package #:shake-ed)
(in-readtable :qtools)

(defun qcolor->vector (qcolor)
  (v (q+:red-f qcolor) (q+:green-f qcolor) (q+:blue-f qcolor)))

(defun vector->qcolor (color)
  (let ((qcolor (q+:make-qcolor)))
    (setf (q+:rgb-f qcolor)
          (values (vx color) (vy color) (vz color)))
    qcolor))

(defun lineitem-normal (lineitem)
  ;; This needs to be the same as linedef-normal in shake-bspc.
  (let ((p1 (q+:p1 (q+:line lineitem)))
        (p2 (q+:p2 (q+:line lineitem))))
    (vnormalize (v (- (q+:y p2) (q+:y p1))
                   (- (q+:x p1) (q+:x p2))))))

(define-widget map-scene (QGraphicsScene)
  ((drawing-rect :initform nil)
   (line-color-map :initform (make-hash-table))
   (view-normals-p :initform t)))

(define-override (map-scene draw-background) (painter rect)
  (q+:fill-rect painter rect (q+:qt.black))
  (with-finalizing ((color (q+:make-qcolor 40 40 40)))
    (q+:set-pen painter color)
    (loop for x from (ceiling (q+:left rect)) upto (floor (q+:right rect)) do
         (with-finalizing ((p1 (q+:make-qpointf x (q+:top rect)))
                           (p2 (q+:make-qpointf x (q+:bottom rect))))
           (q+:draw-line painter p1 p2)))
    (loop for y from (ceiling (q+:top rect)) upto (floor (q+:bottom rect)) do
         (with-finalizing ((p1 (q+:make-qpointf (q+:left rect) y))
                           (p2 (q+:make-qpointf (q+:right rect) y)))
           (q+:draw-line painter p1 p2)))))

(defun make-linedef-loop (p1 p2 p3 &rest points)
  (let ((start-points (append (list p1 p2 p3) points))
        (end-points (append (list p2 p3) points (list p1))))
    (mapcar (lambda (start end) (sbsp:make-linedef :start start :end end))
            start-points end-points)))

(defun polygonitem->linedefs (item)
  (let ((polygon (q+:polygon item)))
    (format t "Polygon ~S~%" polygon)))
    ;; (make-linedef-loop (v right bot) (v left bot) (v left top) (v right top))))

(defun draw-polygonitem-normals (item painter &key (scale 0.25d0))
  (dolist (line (polygonitem->linedefs item))
    (let* ((center (v+ (sbsp:linedef-start line)
                      (vscale 0.5d0 (sbsp:linedef-vec line))))
           (dest (v+ center (vscale scale (sbsp:linedef-normal line)))))
      (with-finalizing* ((p1 (q+:make-qpointf (vx center) (vy center)))
                         (p2 (q+:make-qpointf (vx dest) (vy dest))))
        (q+:draw-line painter p1 p2)))))

(defun draw-lineitem-normal (item painter &key (scale 0.25d0))
  (let ((item-center (q+:center (q+:bounding-rect item)))
        (normal (vscale scale (lineitem-normal item))))
    (with-finalizing ((endpoint (q+:make-qpointf (+ (q+:x item-center)
                                                    (vx normal))
                                                 (+ (q+:y item-center)
                                                    (vy normal)))))
      (q+:draw-line painter item-center endpoint))))

(define-override (map-scene draw-foreground) (painter rect)
  (when view-normals-p
    (with-finalizing ((color (q+:make-qcolor 0 255 255)))
      (q+:set-pen painter color)
      (let ((items (q+:items map-scene)))
        (dolist (item items)
          (unless (eq (car drawing-rect) item)
            (cond
              ((qinstancep item 'qgraphics-line-item)
               (draw-lineitem-normal item painter))
              ((qinstancep item 'qgraphics-polygon-item)
               (draw-polygonitem-normals item painter))))))))
  (stop-overriding))

(defun update-rectitem (rectitem-and-start-pos bot-right)
  (destructuring-bind (rectitem . (x . y)) rectitem-and-start-pos
    (with-finalizing* ((top-left (q+:make-qpointf x y))
                       (new-rect (q+:make-qrectf top-left bot-right))
                       (new-poly (q+:make-qpolygonf (q+:normalized new-rect))))
      (setf (q+:polygon rectitem) new-poly))))

(defun new-rectitem (top-left bot-right)
  (with-finalizing* ((rect (q+:make-qrectf top-left bot-right))
                     (polygon (q+:make-qpolygonf rect)))
    (let ((polygon-item (q+:make-qgraphicspolygonitem polygon)))
      (q+:set-flag polygon-item (q+:qgraphicsitem.item-is-selectable) t)
      polygon-item)))

(defun new-lineitem (p1 p2)
  (with-finalizing ((new-line (q+:make-qlinef p1 p2)))
    (let ((lineitem (q+:make-qgraphicslineitem new-line)))
      (setf (q+:flag lineitem) (values (q+:qgraphicsitem.item-is-selectable) t))
      lineitem)))

(defun within-scene-p (scene point)
  (q+:contains (q+:scene-rect scene) point))

(define-signal (map-scene mouse-scene-pos) (double double))

(defun add-rect-to-scene (scene rect)
  (with-finalizing* ((color (q+:make-qcolor (q+:qt.dark-green)))
                     (pen (q+:make-qpen color)))
    (setf (q+:width-f pen) 0.05
          (q+:pen rect) pen))
  (q+:add-item scene rect))

(defun add-line-to-scene (scene line)
  (with-finalizing* ((color (q+:make-qcolor (q+:qt.dark-green)))
                     (pen (q+:make-qpen color)))
    (setf (q+:width-f pen) 0.05
          (q+:pen line) pen))
  (q+:add-item scene line))

(defun scene-pos-from-mouse (mouse-event)
  (let* ((scene-pos (q+:scene-pos mouse-event))
         (x (q+:x scene-pos))
         (y (q+:y scene-pos))
         (snap-to-grid-p (enum-equal (q+:modifiers mouse-event)
                                     (q+:qt.control-modifier))))
    (if snap-to-grid-p
        (cons (round x) (round y))
        (cons x y))))

(defun add-or-update-rect (map-scene scene-pos)
  (with-slots (drawing-rect) map-scene
    (with-finalizing ((scene-point (q+:make-qpointf (car scene-pos)
                                                    (cdr scene-pos))))
      (if drawing-rect
          (progn
            (update-rectitem drawing-rect scene-point)
            (setf drawing-rect nil))
          (progn
            (setf drawing-rect
                  (cons (new-rectitem scene-point scene-point) scene-pos))
            (add-rect-to-scene map-scene (car drawing-rect)))))))

(define-override (map-scene mouse-press-event) (mouse-event)
  (when (within-scene-p map-scene (q+:scene-pos mouse-event))
    (cond
      ((enum-equal (q+:button mouse-event) (q+:qt.right-button))
       (add-or-update-rect map-scene (scene-pos-from-mouse mouse-event)))
      ((enum-equal (q+:button mouse-event) (q+:qt.left-button))
       (let* ((view (car (q+:views map-scene)))
              (item (q+:item-at map-scene (q+:scene-pos mouse-event)
                                (q+:transform view))))
         (if (null-qobject-p item)
             (q+:clear-selection map-scene)
             (setf (q+:selected item) t))))
      (t (stop-overriding)))))

(define-override (map-scene mouse-move-event) (mouse-event)
  (when (and drawing-rect (within-scene-p map-scene (q+:scene-pos mouse-event)))
    (let ((scene-pos (scene-pos-from-mouse mouse-event)))
      (with-finalizing ((scene-point (q+:make-qpointf (car scene-pos)
                                                      (cdr scene-pos))))
        (update-rectitem drawing-rect scene-point))))
  (signal! map-scene (mouse-scene-pos double double)
           (q+:x (q+:scene-pos mouse-event))
           (q+:y (q+:scene-pos mouse-event))))

(defun remove-selected (scene)
  (let ((items (q+:selected-items scene)))
    (dolist (item items)
      (q+:remove-item scene item)
      (with-slots (drawing-rect line-color-map) scene
        (setf drawing-rect nil)
        (remhash item line-color-map)))))

(define-override (map-scene key-press-event) (key-event)
  (cond
    ((q+:matches key-event (q+:qkeysequence.delete))
     (remove-selected map-scene))
    (t (stop-overriding))))

(defun flip-normal-on-selected (scene)
  (let ((items (q+:selected-items scene)))
    (dolist (item items)
      (let ((line (q+:line item)))
        (with-finalizing ((flipped-line (q+:make-qlinef (q+:p2 line)
                                                        (q+:p1 line))))
          (q+:set-line item flipped-line))))
    (when items
      (q+:update scene (q+:scene-rect scene)))))

(defun toggle-view-normals (scene)
  (with-slots (view-normals-p) scene
    (setf view-normals-p (not view-normals-p))
    (q+:update scene (q+:scene-rect scene))))

(define-widget main (QMainWindow)
  ((map-file :initform nil)))

(define-subwidget (main scene) (make-instance 'map-scene))

(define-slot (main mouse-scene-pos) ((x double) (y double))
  (declare (connected scene (mouse-scene-pos double double)))
  (q+:show-message (q+:status-bar main) (format nil "Pos ~,2F, ~,2F" x y)))

(define-subwidget (main map-view) (q+:make-qgraphicsview)
  (with-finalizing ((cursor (q+:make-qcursor (q+:qt.cross-cursor))))
    (setf (q+:minimum-size map-view) (values 200 200)
          (q+:mouse-tracking map-view) t
          (q+:cursor map-view) cursor))
  (q+:scale map-view 25 25)
  (with-finalizing ((rect (q+:make-qrectf -200 -200 400 400))
                    (brush (q+:make-qbrush (q+:qt.black) (q+:qt.solid-pattern))))
    (setf (q+:scene-rect scene) rect
          (q+:background-brush scene) brush))
  (setf (q+:scene map-view) scene))

(define-subwidget (main layout) (q+:make-qvboxlayout)
  (let ((widget (q+:make-qwidget)))
    (q+:add-widget layout map-view)
    (setf (q+:layout widget) layout)
    (setf (q+:central-widget main) widget)))

(defun new-map (w)
  (with-slots (scene map-file) w
    (q+:clear scene)
    (setf map-file nil)))

(defun write-map (stream scene)
  (with-slots (line-color-map) scene
    (let* ((items (q+:items scene))
           (items-count (length items)))
      (format stream "~S~%" items-count)
      (loop for i from 0 and lineitem in items do
           (let ((p1 (q+:p1 (q+:line lineitem)))
                 (p2 (q+:p2 (q+:line lineitem)))
                 (color (gethash lineitem line-color-map (v 1 0 1))))
             (format stream "~S~%~S ~S ~S~%"
                     (list (q+:x p1) (q+:y p1) (q+:x p2) (q+:y p2))
                     (vx color) (vy color) (vz color)))))))

(defun read-map (stream scene)
  (with-slots (line-color-map) scene
    (let ((n (read stream)))
      (loop repeat n doing
           (let ((points (read stream))
                 (color (v (read stream) (read stream) (read stream))))
             (with-finalizing ((p1 (q+:make-qpointf (first points)
                                                    (second points)))
                               (p2 (q+:make-qpointf (third points)
                                                    (fourth points))))
               (let ((lineitem (new-lineitem p1 p2)))
                 (add-line-to-scene scene lineitem)
                 (setf (gethash lineitem line-color-map) color))))))))

(defun save-map (w &optional filename)
  (let ((filepath filename))
    (unless filepath
      (setf filepath
            (q+:qfiledialog-get-save-file-name w "Save Map" "" "Maps (*.map)")))
    (unless (emptyp filepath)
      (unless (ends-with-subseq ".map" filepath)
        (setf filepath (concatenate 'string filepath ".map")))
      (with-slots (scene map-file) w
        (with-open-file (file filepath :direction :output
                              :if-exists :supersede :if-does-not-exist :create)
          (write-map file scene)
          (q+:show-message (q+:status-bar w)
                           (format nil "Saved '~S'" filepath))
          (setf map-file filepath))))))

(defun open-map (w)
  (let ((filepath (q+:qfiledialog-get-open-file-name
                   w "Open Map" "" "Maps (*.map)")))
    (when (and filepath (ends-with-subseq ".map" filepath))
      (with-slots (scene map-file) w
        (with-open-file (file filepath)
          (q+:clear scene)
          (read-map file scene)
          (q+:show-message (q+:status-bar w)
                           (format nil "Loaded '~S'" filepath))
          (setf map-file filepath))))))

(defun compile-map (w)
  (with-slots (map-file) w
    (unless (emptyp map-file)
      (let ((bsp-file (concatenate 'string
                                   (subseq map-file 0 (- (length map-file) 4))
                                   ".bsp")))
        (sbsp:compile-map-file map-file bsp-file)
        (q+:show-message (q+:status-bar w)
                         (format nil "Compiled to '~S'" bsp-file))))))

(define-menu (main File)
  (:item ("New" (ctrl n)) (new-map main))
  (:item ("Open..." (ctrl o)) (open-map main))
  (:separator)
  (:item ("Save" (ctrl s)) (save-map main map-file))
  (:item ("Save As..." (shift ctrl s)) (save-map main))
  (:item ("Compile" (f5)) (compile-map main))
  (:separator)
  (:item ("Quit" (ctrl q))
         (q+:close main)))

(defun edit-color (w)
  (with-slots-bound (w main)
    (when-let ((items (q+:selected-items scene)))
      (with-slots (line-color-map) scene
        (let ((old-color (gethash (car items) line-color-map (v 1 0 1))))
          (with-finalizing* ((qcolor (vector->qcolor old-color))
                             (new-qcolor (q+:qcolordialog-get-color qcolor w)))
            (when (q+:is-valid new-qcolor)
              (dolist (item items)
                (setf (gethash item line-color-map)
                      (qcolor->vector new-qcolor))))))))))

(define-menu (main Edit)
  (:item ("Color" (c)) (edit-color main))
  (:item ("Delete" (backspace)) (remove-selected scene)))

(define-menu (main View)
  (:item "Normals" (toggle-view-normals scene)))

(define-initializer (main setup)
  (setf (q+:window-title main) "ShakeEd")
  (q+:resize main 800 600)
  (q+:show-message (q+:status-bar main) "Status"))

(defun main ()
  (let ((gl-format (q+:make-qglformat)))
    (q+:set-version gl-format 3 3)
    ;; Core Profile.
    (q+:set-profile gl-format 1)
    (q+:qglformat-set-default-format gl-format)
    (with-main-window (window (make-instance 'main)))))
