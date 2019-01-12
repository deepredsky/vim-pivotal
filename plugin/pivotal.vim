let g:pivotal_base_directory = expand('~/.pivotal')

if !exists("g:project_id")
  let g:project_id = $PIVOTAL_PROJECT_ID
endif

if !exists("g:pivotal_auth_token")
  let g:pivotal_auth_token = $PIVOTAL_AUTH_TOKEN
endif


if !exists('g:project_id')
  echohl ErrorMsg | echomsg 'VIM-PIVOTAL: project id has not been set!' | echohl None
  finish
endif

if !exists('g:pivotal_auth_token')
  echohl ErrorMsg | echomsg 'VIM-PIVOTAL: pivotal auth token has not been set!' | echohl None
  finish
endif

function! s:ApiUrl(pivotalid)
  let url = 'https://www.pivotaltracker.com/services/v5/projects/' . $PIVOTAL_PROJECT_ID . '/stories/' . a:pivotalid
  return url
endfunction

function! s:SetupBuffer(buffer_name)
  let winnr = bufwinnr('^' . a:buffer_name . '$')

  if winnr < 0
    silent! execute 'vertical botright new ' . a:buffer_name
  else
    silent! execute winnr . 'wincmd w'
  endif
endfunction

function! PivotalGet(pivotalid) abort
  redraw | echon 'Getting pivotal... '
  echom s:ApiUrl(a:pivotalid)
  let res = webapi#http#get(s:ApiUrl(a:pivotalid), '', { "X-TrackerToken": g:pivotal_auth_token })
  if res.status =~# '^2'
    try
      let pivotal = webapi#json#decode(res.content)
    catch
      redraw
      echohl ErrorMsg | echomsg 'Pivotal api seems to be broken' | echohl None
      return
    endtry
    redraw
    let buffer_name = g:pivotal_base_directory . '/' . g:project_id  . '/' . a:pivotalid
    let pivotal_directory = fnamemodify(buffer_name, ':h')

    if !isdirectory(pivotal_directory)
      call mkdir(pivotal_directory, 'p')
    endif

    call s:SetupBuffer(buffer_name)

    silent %d _

    call setline(1, split(pivotal.description, "\n"))

    let b:pivotal = {
          \ "id": pivotal.id,
          \ "name": pivotal.name,
          \ "url": pivotal.url,
          \}
    setlocal bufhidden=hide filetype=markdown noswapfile noswapfile
    setlocal nomodified
  else
    redraw
    echohl ErrorMsg | echomsg 'VIM-PIVOTAL: Pivotal story not found' | echohl None
    return
  endif
endfunction

function! PivotalOpen()
  if exists("b:pivotal['url']")
    call netrw#BrowseX(b:pivotal['url'], 0)
    return
  else
    echohl ErrorMsg | echomsg 'VIM-PIVOTAL: Could not find pivotal story in buffer' | echohl None
  endif
endfunction
