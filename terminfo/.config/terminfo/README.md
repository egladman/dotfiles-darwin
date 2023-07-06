# Enable truecolor support

>Colors and faces are supported in non-windowed mode, i.e., on Unix and GNU/Linux text-only terminals and consoles, and when invoked as ‘emacs -nw’ on X, MS-DOS and MS-Windows. Emacs automatically detects color support at startup and uses it if available. If you think that your terminal supports colors, but Emacs won’t use them, check the termcap entry for your display type for color-related capabilities.
>
>The command M-x list-colors-display pops up a window which exhibits all the colors Emacs knows about on the current display.
>
>Syntax highlighting is also on by default on text-only terminals.
.
>Emacs 26.1 and later support direct color mode in terminals. If Emacs finds Terminfo capabilities ‘setb24’ and ‘setf24’, 24-bit direct color mode is used. The capability strings are expected to take one 24-bit pixel value as argument and transform the pixel to a string that can be used to send 24-bit colors to the terminal.
>
>Standard terminal definitions don’t support these capabilities and therefore custom definition is needed.

Source: https://www.gnu.org/software/emacs/manual/html_mono/efaq.html#Colors-on-a-TTY

```
tic -x -o ~/.terminfo ~/.config/terminfo/xterm-emacs.src
```

You can now set `TERM` to `xterm-emacs`
```
export TERM=xterm-emacs
```

Additional Reading:
- https://github.com/syl20bnr/spacemacs/wiki/Terminal

