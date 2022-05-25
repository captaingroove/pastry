# Pastry

## Introduction

Pastry is a simple neovim / vim plugin for sending text from a buffer to another window / buffer.
The main use case is sending selected text or the current line from a buffer to a terminal
window running a REPL where the text is "executed". This way you can keep focus in a buffer
where you edit code while testing code snippets in an interpreter running in a terminal window.
The text is unindented before sending it so that you can evaluate nested code blocks in
indentation sensitive languages like python.

The following commands and functions are provided to achieve this:
```vim
SetConsole
" command to set the current window / buffer as the target to send text to from any other buffer.

PastrySendCurrentLine()
" function to send the current line to the target window / buffer.

PastrySendSelection(mode)
" function to send a visual selection to the target window / buffer.
" Argument 'mode' is the visual mode:
"   'v'     - default visual mode
"   'V'     - line visual mode
"   \<c-v>  - block visual mode

PastrySendToConsole(string)
" function to send string to the target window / buffer.
```

Some examples for mapping the functions to keys are given in section "Configuration".

## Installation

Copy the plugin folder (or git-clone it directly) to an appropriate place in
your vim directory so that the built-in vim plugin manager can find it.
For example:

```bash
$ mkdir -p ~/.vim/pack/plugins/start
$ cd ~/.vim/pack/plugins/start
$ git clone https://github.com/captaingroove/pastry.git
```

## Configuration

You might want to add the following key mappings to your vimrc:

```
nnoremap <silent><F5> :call PastrySendCurrentLine()<CR>
xnoremap <silent><F5> :<C-U> call PastrySendSelection(visualmode())<CR>
nnoremap <silent><F6> :call PastrySendToConsole(&makeprg . "\n")<CR>
```

There's also one optional setting:

```vim
let g:pastry_send_to_buffer = 0
" send to the buffer and not to the window that was focused when SetConsole was run.
" Default is window.
```

## Compatibility

The plugin has been tested on Linux with the following vim versions:

- vim 8.2
- neovim v0.7.1-dev+33-g35075dcc2-dirty with nvim.patch from this repo

## Caveats

- Currently, bracketed paste mode is permanently switched on. Bracketed paste
  mode is needed for avoiding the staircase effect when sending multiline
  selections. However, the majority of interpreters can handle this.
