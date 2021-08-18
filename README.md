# what am I looking at?
This is a package (really, just one function) for GNU Emacs.  Its sole
purpose is to load one of two themes based on whether the sun is
currently up in your location. Bring your own themes.

# how do I use it?
1. Download daylight-detector.el via curl or what have you (this
   package is not on melpa and probably never will be)
2. Run M-x package-install-file on the file you just downloaded
3. Setq or customize daylight-detector-light-theme and
   daylight-detector-dark-theme to the themes you would like to see at
   night and not-night, respectively.
4. After setting the themes, call daylight-detector-set-theme, which
   is autoloaded. This command figures out where you are and where the
   sun is, and sets the appropriate theme. Place it somewhere near the
   top of your init.el, or call it interactively.

See documentation on daylight-detector-set-theme.

Dustin Ross
August 17, 2021
