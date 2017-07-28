if exists('g:loaded_rsense')
    finish
endif
let g:loaded_rsense = 1

if !exists('g:rsenseHome')
    let g:rsenseHome = expand("/usr/local")
endif

if !exists('g:rsenseUseOmniFunc')
    let g:rsenseUseOmniFunc = 0
endif

" Check vimproc.
let s:is_vimproc = exists('*vimproc#system')

function! s:system(str, ...)"{{{
  return s:is_vimproc ? (a:0 == 0 ? vimproc#system(a:str) : vimproc#system(a:str, join(a:000)))
        \: (a:0 == 0 ? system(a:str) : system(a:str, join(a:000)))
endfunction"}}}

let s:rsenseCompletionKindDictionary = {'CLASS': 'C', 'MODULE': 'M', 'CONSTANT': 'c', 'METHOD': 'm'}

function! s:rsenseProgram()
    return g:rsenseHome . '/bin/rsense'
endfunction

function! s:rsenseCommand(args)
    for i in range(0, len(a:args) - 1)
        let a:args[i] = shellescape(a:args[i])
    endfor
    return s:system(printf('ruby %s %s %s',
                           \ shellescape(s:rsenseProgram()),
                           \ join(a:args, ' '),
                           \ shellescape('--detect-project=' . bufname('%'))))
endfunction

function! s:rsenseClientCommand(args)
    for i in range(0, len(a:args) - 1)
        let a:args[i] = shellescape(a:args[i])
    endfor
    return s:system(printf('_rsense_commandline.rb %s',
                           \ join(a:args, ' ')))
endfunction

function! s:rsenseCurrentBufferFile()
    let buf = getline(1, '$')
    let file = tempname()
    call writefile(buf, file)
    return file
endfunction

function! s:rsenseCurrentBufferFileOption()
    return '--file=' . s:rsenseCurrentBufferFile()
endfunction

function! s:rsenseCurrentLocationOption()
    return printf('--location=%s:%s', line('.'), col('.') - (mode() == 'n' ? 0 : 1))
endfunction

function! RSenseCompleteFunction(findstart, base)
    if a:findstart
        let cur_text = strpart(getline('.'), 0, col('.') - 1)
        return match(cur_text, '[^\.:]*$')
    else
        let result = split(s:rsenseClientCommand(['code_completion',
                                            \ s:rsenseCurrentBufferFileOption(),
                                            \ s:rsenseCurrentLocationOption(),
                                            \ '--prefix=' . a:base]),
                           \ "\n")
        let completions = []
        for item in result
		let ary = split(item, ' ')
		let dict = { 'word': ary[1] }
		if len(ary) > 4
		    let dict['menu'] = ary[3]
		    let dict['kind'] = s:rsenseCompletionKindDictionary[ary[4]]
		endif
		call add(completions, dict)
        endfor
        return completions
    endif
endfunction

function! RSenseVersion()
    return s:rsenseCommand(['version'])
endfunction

function! RSenseStart()
    return s:rsenseCommand(['start'])
endfunction

function! RSenseStop()
    return s:rsenseCommand(['stop'])
endfunction

function! RSenseStatus()
    return s:rsenseCommand(['status'])
endfunction

command! -narg=0 RSenseVersion          echo RSenseVersion()
command! -narg=0 RSenseStart     echo RSenseStart()
command! -narg=0 RSenseStop      echo RSenseStop()
command! -narg=0 RSenseStatus    echo RSenseStatus()

function! SetupRSense()
    if g:rsenseUseOmniFunc
        setlocal omnifunc=RSenseCompleteFunction
    else
        setlocal completefunc=RSenseCompleteFunction
    endif
endfunction

autocmd FileType ruby call SetupRSense()
