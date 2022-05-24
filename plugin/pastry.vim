" Copyright (c) 2022 Jörg Bakker
"
" Permission is hereby granted, free of charge, to any person obtaining a copy of
" this software and associated documentation files (the 'Software'), to deal in
" the Software without restriction, including without limitation the rights to
" use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
" of the Software, and to permit persons to whom the Software is furnished to do
" so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in all
" copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
" SOFTWARE.

let g:pastry_send_to_buffer = 0

let s:pastry_console_window = 0
let s:pastry_console_buffer = 0


function! s:SetConsoleFunc()
    let s:pastry_console_window = win_getid()
    let s:pastry_console_buffer = bufnr()
endfunction
command! SetConsole call s:SetConsoleFunc()


function! s:PastryConsoleNotSet()
    return s:pastry_console_buffer == 0 || s:pastry_console_window == 0
endfunction


function! s:PastryWarnConsoleNotSet()
    echohl ErrorMsg
    echomsg "First run 'SetConsole' command once in console window ..."
    echohl None
endfunction


function s:PastryFocusConsole()
    if s:PastryConsoleNotSet()
        call s:PastryWarnConsoleNotSet()
        return
    endif
    execute bufwinnr(s:pastry_console_buffer) . 'wincmd w'
endfunction


function! PastrySendToConsole(string)
    if s:PastryConsoleNotSet()
        call s:PastryWarnConsoleNotSet()
        return
    endif
    if g:pastry_send_to_buffer
        let current_window_buffer = s:pastry_console_buffer
    else
        let current_window_buffer = winbufnr(s:pastry_console_window)
    endif
    " Honor bracketed paste mode
    let send_string = "\x1b[200~" . a:string . "\x1b[201~\n"
    if has('nvim')
        let current_buffer_jobid = getbufvar(current_window_buffer, "terminal_job_id")
        " FIXME: neovim doesn't honor bracketed paste mode ...?!
        " https://jdhao.github.io/2021/02/01/bracketed_paste_mode/
        " It seems like bracketed_paste_mode is only used when pasting to
        " current cursor position. So the following line makes a staircase ...
        " call chansend(current_buffer_jobid, a:string)
        call chansend(current_buffer_jobid, send_string)
    else
        call term_sendkeys(current_window_buffer, send_string)
    endif
endfunction
command! -nargs=1 SendConsole call PastrySendToConsole(<f-args>)


function! PastryCdAndFocus(directory)
    call PastrySendToConsole("cd " . a:directory)
    call s:PastryFocusConsole()
endfunction


function! PastrySendCurrentLine()
    call PastrySendToConsole(trim(getline('.')) . "\n")
endfunction


function! s:PastryUnindent(lines)
    let line_starts = []
    for l in a:lines
        let line_start = match(l, '\S')
        let line_starts = add(line_starts, line_start)
    endfor
    let i = 0
    let new_lines = a:lines
    let line_starts_min = min(line_starts)
    for l in a:lines
        let new_lines[i] = l[line_starts_min:]
        let i = i + 1
    endfor
    return new_lines
endfunction


function! PastrySendSelection(mode)
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end]     = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if a:mode ==# 'v'
        " Must trim the end before the start, the beginning will shift left
        let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
        let lines[0] = lines[0][column_start - 1:]
    elseif  a:mode ==# 'V'
        " Line mode no need to trim start or end
    elseif  a:mode == "\<c-v>"
        " Block mode, trim every line
        let new_lines = []
        let i = 0
        for line in lines
            let lines[i] = line[column_start - 1: column_end - (&selection == 'inclusive' ? 1 : 2)]
            let i = i + 1
        endfor
    else
        return ''
    endif
    call PastrySendToConsole(join(s:PastryUnindent(lines), "\n") . "\n")
endfunction
