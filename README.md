# Pastry

## Introduction

Pastry is a neovim / vim plugin for pasting text from a buffer to a terminal window.

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
" Config option s:pastry_send_to_buffer sends to the buffer and not to the window
" that was focused when SetConsole was run. Default is sending to window.
```

## Compatibility

The plugin has been tested on Linux with the following vim versions:

- vim 8.2
- neovim v0.7.1-dev+33-g35075dcc2-dirty with nvim.patch from this repo

## Caveats

- Currently, bracketed paste mode is permanently switched on.
