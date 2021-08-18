;;; daylight-detector.el --- Decides on a theme based on whether the sun is up

;; Copyright (C) 2021 Dustin Ross

;; Author: Dustin Ross <dustinross@live.com>
;; Version: 1.0
;; Package-Requires: ((request "0.3.3") calendar json)
;; Keywords: convenience, faces
;; URL: https://github.com/mope-life

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides a single entry-point: M-x
;; daylight-detector-set-theme, which is autoloaded.  This command
;; loads the theme whose symbol is in either
;; daylight-detector-light-theme or daylight-detector-dark-theme,
;; depending on whether the sun is up at your location.

;;; Code:

(require 'solar)
(require 'request)
(require 'json)

(defgroup daylight-detector nil
  "Group for daylight-detector.el."
  :group 'convenience
  :prefix "daylight-detector-")

(defcustom daylight-detector-public-ip nil
  "Your public ip address.
If not set, and either calendar-latitude or calendar-longitude is
not set, daylight-detector will attempt to set it automatically
as reported by ipecho.net"
  :type 'string
  :group 'daylight-detector)

(defcustom daylight-detector-light-theme nil
  "The theme to turn on during daytime."
  :type 'symbol
  :group 'daylight-detector)

(defcustom daylight-detector-dark-theme nil
  "The theme to turn on during the nighttime."
  :type 'symbol
  :group 'daylight-detector)

;;; None of these macros  are intended to be used outside of this file
(eval-when-compile
  (defmacro daylight-detector--with-public-ip (&rest body)
    "Execute BODY after setting `daylight-detector-public-ip'.
If `daylight-detector-public-ip' is already set, just execute
body."
    `(if (null daylight-detector-public-ip)
	 (request
	   "https://ipecho.net/plain"
	   :parser 'buffer-string
	   :success
	   (cl-function
	    (lambda (&key data &allow-other-keys)
	      (setq daylight-detector-public-ip data)
	      ,@body)))
       ,@body))

  (defmacro daylight-detector--with-latitude/longitude (&rest body)
    "Execute BODY after setting `calendar-latitude' and `calendar-longitude'.
Also calls `daylight-detector--with-public-ip'.  If both
`calendar-latitude' and `calendar-longitude' are already set,
just execute body."
    `(if (or (null calendar-latitude) (null calendar-longitude))
	 (daylight-detector--with-public-ip
	  (request
	    (concat "http://ip-api.com/json/" daylight-detector-public-ip)
	    :parser 'json-read
	    :success
	    (cl-function
	     (lambda (&key data &allow-other-keys)
	       (setq calendar-latitude (alist-get 'lat data))
	       (setq calendar-longitude (alist-get 'lon data))
	       ,@body))))
       ,@body))

  (defmacro daylight-detector--with-sunrise-sunset
      (sunrise-var sunset-var &rest body)
    "Execute BODY with SUNRISE-VAR and SUNSET-VAR set appropriately.
Both values are floats as reported by `solar-sunrise-sunset'."
    (let ((ss (gensym)))
      `(daylight-detector--with-latitude/longitude
	(let* ((calendar-time-zone (car (calendar-current-time-zone)))
	       (,ss (solar-sunrise-sunset (calendar-current-date)))
	       (,sunrise-var (caar ,ss))
	       (,sunset-var (caadr ,ss)))
	  ,@body)))))

;;;###autoload
(defun daylight-detector-set-theme ()
  "Load a light or dark theme, depending on whether the sun is up.
The choices of themes are given by the symbols saved in
`daylight-detector-light-theme' or
`daylight-detector-dark-theme'.

If the (customizable) variables `calendar-latitude' and
`calendar-longitude' are not already set, this function will try
to automatically set your latitiude, longitude and
`daylight-detector-public-ip' using requests to the APIs at
ipecho.com and ip-api.com.  If this behavior is undesirable, or
something else is preventing the automatic discovery of your
location (for instance, you don't have an internet connection or
are behind a VPN), these variables can be customized."
  (interactive)
  (daylight-detector--with-sunrise-sunset
   sunrise sunset
   (let* ((hour (read (format-time-string "%H")))
	  (minute (read (format-time-string "%M")))
	  (float-time (+ hour (/ minute 60.0)))
	  ;; Just checks if the current time of day is before sunrise or
	  ;; after sunset. There are probably places on earth where this
	  ;; will not work all the time. *shrug*
	  (theme (if (or (< float-time sunrise) (> float-time sunset))
		     daylight-detector-dark-theme
		   daylight-detector-light-theme)))
     (load-theme theme)))
  ;; We can't return anything meaningful since the requests are async
  nil)

(provide 'daylight-detector)

;;; daylight-detector.el ends here
