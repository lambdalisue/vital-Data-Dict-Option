function! s:_vital_loaded(V) abort
  let s:List = a:V.import('Data.List')
  let s:String = a:V.import('Data.String')
  let s:Formatter = a:V.import('Data.String.Formatter')
endfunction

function! s:_vital_depends() abort
  return ['Data.List', 'Data.String', 'Data.String.Formatter']
endfunction


function! s:translate(options, schemes) abort
  let args = []
  for key in sort(keys(a:schemes))
    if !has_key(a:options, key)
      continue
    endif
    let scheme = type(a:schemes[key]) == type('')
          \ ? a:schemes[key]
          \ : len(key) == 1 ? '-%k%v' : '--%k%{=}v'
    call extend(args, s:_translate(key, a:options, scheme))
  endfor
  return args
endfunction

function! s:strip_quotes(value) abort
  let value = a:value =~# '^\%(".*"\|''.*''\)$' ? a:value[1:-2] : a:value
  if value =~# '^--\?\w\+=["''].*["'']$'
    let value = substitute(value, '^\(--\?\w\+=\)["'']\(.*\)["'']$', '\1\2', '')
  endif
  return value
endfunction

function! s:split_args(args) abort
  let single_quote = '''\zs[^'']\+\ze'''
  let double_quote = '"\zs[^"]\+\ze"'
  let bare_strings = '\%(\\\s\|[^ \t''"]\)\+'
  let atoms = [single_quote, double_quote, bare_strings]
  let pattern = '\%(' . join(atoms, '\|') . '\)'
  let args = split(a:args, pattern . '*\zs\%(\s\+\|$\)\ze')
  let args = map(args, 's:strip_quotes(v:val)')
  let args = map(args, 's:String.unescape(v:val, '' '')')
  return args
endfunction

function! s:_translate(key, options, scheme) abort
  let value = a:options[a:key]
  if type(value) == type([])
    return s:List.flatten(map(
          \ copy(value),
          \ 's:_translate(a:key, { a:key : v:val }, a:scheme)'
          \))
  elseif type(value) == type(0)
    return value ? [(len(a:key) == 1 ? '-' : '--') . a:key] : []
  else
    let value = value =~# '\s' ? printf("'%s'", value) : value
    return s:split_args(s:Formatter.format(
          \ a:scheme,
          \ { 'k': 'key', 'v': 'val' },
          \ { 'key': a:key, 'val': value },
          \))
  endif
endfunction

