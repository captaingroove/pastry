" File              : pastry.vim
" Author            : Jörg Bakker <jorg@hakker.de>
" Date              : 2020-01-02
" Last Modified Date: 2021-09-14
" Last Modified By  : Jörg Bakker <jorg@hakker.de>


" Config option s:pastry_send_to_buffer sends to the buffer and not to the window
" when SetConsole was run. Default is sending to window.
let s:pastry_send_to_buffer = 0
let s:pastry_console_window = 0
let s:pastry_console_buffer = 0


function! SetConsoleFunc()
    let s:pastry_console_window = win_getid()
    let s:pastry_console_buffer = bufnr()
endfunction
command! SetConsole call SetConsoleFunc()


function! PastryConsoleNotSet()
    return s:pastry_console_buffer == 0 || s:pastry_console_window == 0
endfunction


function! PastryWarnConsoleNotSet()
    echohl ErrorMsg
    echomsg "First run 'SetConsole' command once in console window ..."
    echohl None
endfunction


function PastryFocusConsole()
    if PastryConsoleNotSet()
        call PastryWarnConsoleNotSet()
        return
    endif
    execute bufwinnr(s:pastry_console_buffer) . 'wincmd w'
endfunction


function! PastrySendToConsole(string)
    if PastryConsoleNotSet()
        call PastryWarnConsoleNotSet()
        return
    endif
    if s:pastry_send_to_buffer
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
    call PastryFocusConsole()
endfunction


function! PastrySendCurrentLine()
    call PastrySendToConsole(trim(getline('.')) . "\n")
endfunction


function! PastryUnindent(lines)
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
    call PastrySendToConsole(join(PastryUnindent(lines), "\n") . "\n")
endfunction