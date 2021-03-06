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

(in-package #:cl-user)

(defpackage #:shake-ed.utils
  (:use #:cl+qt #:shake-utils)
  (:import-from #:shiva
                #:v #:vx #:vy #:vz)
  (:export #:vector->qcolor
           #:qcolor->vector))

(defpackage #:shake-ed.model
  (:use #:cl #:shake-utils)
  (:export #:mbrush
           #:copy-mbrush #:make-mbrush #:mbrush-p
           #:mbrush-brush
           #:mbrush-rotation
           #:sector
           #:sector-floor-height
           #:sector-ceiling-height
           #:texture
           #:texture-draw-mode
           #:texture-name
           #:texture-offset-x
           #:texture-offset-y))

(defpackage #:shake-ed.map-scene
  (:use #:cl+qt #:shake-utils #:shake-ed.model)
  (:import-from #:shiva
                #:deg->rad
                #:v #:vx #:vy #:v=
                #:v+ #:v- #:vscale)
  (:import-from #:alexandria
                #:clamp
                #:curry
                #:hash-table-values
                #:lastcar
                #:rcurry
                #:when-let)
  (:export #:+initial-grid-step+
           #:map-scene
           #:map-scene-edit-mode
           #:map-scene-selected-brushes
           #:scene->map-unit
           #:clear-map
           #:write-map
           #:read-map
           #:convert-brush
           #:remove-selected
           #:rotate-selected
           #:selected-items
           #:selected-sidedefs
           #:change-mode
           #:scale-grid-step
           #:toggle-view-normals))

(defpackage #:shake-ed.props-ed
  (:use #:cl+qt #:shake-utils #:shake-ed.utils #:shake-ed.model)
  (:import-from #:alexandria
                #:ends-with-subseq
                #:length=
                #:when-let)
  (:export #:properties-editor
           #:sector-editor
           #:sector-editor-brushes
           #:target))

(defpackage #:shake-ed
  (:use #:cl+qt #:shake-utils #:shake-ed.utils #:shake-ed.map-scene
        #:shake-ed.props-ed)
  (:export #:main)
  (:import-from #:alexandria
                #:clamp
                #:emptyp
                #:ends-with-subseq
                #:when-let*))
