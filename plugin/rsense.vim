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

let s:rsenseCompletionKindDictionary = {'CLASS': 'C', 'MODULE': 'M', 'CONSTANT': 'c', 'METHOD': 'm'}

function! s:RsenseProgram()
    return g:rsenseHome . '/bin/rsense'
endfunction

function! s:RsenseCommand(args)
    for i in range(0, len(a:args) - 1)
        let a:args[i] = shellescape(a:args[i])
    endfor
    return system(printf('%s %s',
                           \ shellescape(s:RsenseProgram()),
                           \ join(a:args, ' ')))
endfunction

function! s:RsenseClientCommand(args)
    for i in range(0, len(a:args) - 1)
        let a:args[i] = shellescape(a:args[i])
    endfor
    return system(printf('_rsense_commandline.rb %s',
                           \ join(a:args, ' ')))
endfunction

function! s:RsenseCurrentProjectOption()
    return '--project=' . './someproject'
endfunction

function! s:RsenseCurrentBufferFileOption()
    return '--file=' . expand("%:p")
endfunction

function! s:RsenseCurrentBufferTextOption()
    let buf = getline(1, '$')
    return '--text=' . buf
endfunction

function! s:RsenseCurrentLocationOption()
    return printf('--location=%s:%s', line('.'), col('.') - (mode() == 'n' ? 0 : 1))
endfunction

function! RSenseCompleteFunction(findstart, base)
    if a:findstart
        let cur_text = strpart(getline('.'), 0, col('.') - 1)
        return match(cur_text, '[^\.:]*$')
    else
        let result = split(s:RsenseClientCommand([s:RsenseCurrentProjectOption(),s:RsenseCurrentBufferFileOption(),
					    \ s:RsenseCurrentBufferTextOption(),
                                            \ s:RsenseCurrentLocationOption()]),
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
    return s:RsenseCommand(['version'])
endfunction

function! RSenseStart()
    return s:RsenseCommand(['start'])
endfunction

function! RSenseStop()
    return s:RsenseCommand(['stop'])
endfunction

function! RSenseStatus()
    return s:RsenseCommand(['status'])
endfunction

command! -narg=0 RSenseVersion   echo RSenseVersion()
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
