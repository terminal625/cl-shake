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

(defpackage #:shake-bspc-test
  (:use #:cl
        #:prove
        #:shake-bspc)
  (:import-from #:shiva
                #:v=
                #:v))

(in-package #:shake-bspc-test)

(plan nil)

(defparameter *test-linedefs*
  (list (make-linedef :start (v 0 -2) :end (v 0 5))
        (make-linedef :start (v -2 1) :end (v 5 1))
        (make-linedef :start (v 3 2) :end (v 3 -2))))

(subtest "Testing split-lineseg"
  (let* ((line (car *test-linedefs*))
         (seg (linedef->lineseg line)))
    (is (sbsp::split-lineseg seg -1d0)
        nil)
    (is (sbsp::split-lineseg seg 0d0)
        nil)
    (is (sbsp::split-lineseg seg 1d0)
        nil)
    (let* ((t-split 0.8d0)
           (split-segs (sbsp::split-lineseg seg t-split)))
      (is split-segs
          (cons (make-lineseg :orig-line line
                              :t-end t-split)
                (make-lineseg :orig-line line
                              :t-start t-split))
          :test #'equalp)
      (is (sbsp::lineseg-start (car split-segs))
          (sbsp::linedef-start line) :test #'v=)
      (is (sbsp::lineseg-end (cdr split-segs))
          (sbsp::linedef-end line) :test #'v=)
      (is (sbsp::lineseg-start (cdr split-segs)) (v 0 3.6d0) :test #'v=)
      (is (sbsp::lineseg-start (cdr split-segs))
          (sbsp::lineseg-end (car split-segs)) :test #'v=))))

(subtest "Test serialization"
  (let* ((segs (mapcar #'linedef->lineseg *test-linedefs*))
         (bsp (build-bsp (car segs) (cdr segs))))
    (with-input-from-string (in (with-output-to-string (out)
                                  (sbsp::write-bsp bsp out)))
      (is (read-bsp in) bsp :test #'equalp))))

(defparameter *coincident-linedefs*
  (list (make-linedef :start (v -3.0d0 1.0d0) :end (v -2.0d0 1.0d0))
        (make-linedef :start (v -4.0d0 2.0d0) :end (v -4.0d0 0.0d0))
        (make-linedef :start (v -1.0d0 1.0d0) :end (v 0.0d0 1.0d0))))

(subtest "Test build-bsp produces correct back-to-front"
  (subtest "Coincident segments"
    (let* ((segs (mapcar #'linedef->lineseg *coincident-linedefs*))
           (bsp (build-bsp (car segs) (cdr segs))))
      (is (back-to-front (v -0.5d0 1.5d0) bsp)
          (list (make-lineseg :orig-line (second *coincident-linedefs*)
                              :t-start 0.5d0 :t-end 1d0)
                (third segs)
                (first segs)
                (make-lineseg :orig-line (second *coincident-linedefs*)
                              :t-start 0d0 :t-end 0.5d0)) :test #'equalp))))

(finalize)
