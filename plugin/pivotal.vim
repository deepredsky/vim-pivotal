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

function! s:ApiUrl(path)
  let url = 'https://www.pivotaltracker.com/services/v5/projects/' . $PIVOTAL_PROJECT_ID . a:path
  return url
endfunction

function! s:strip(str)
  return substitute(a:str, '^\s*\|\s*$', '', 'g')
endfunction

function! s:FZFOpenPivotalStory(line)
  let pivotalid = split(a:line, "\t")[0]
  call PivotalGet(s:strip(pivotalid))
endfunction

function! s:align_lists(lists)
  let maxes = {}
  for list in a:lists
    let i = 0
    while i < len(list)
      let maxes[i] = max([get(maxes, i, 0), len(list[i])])
      let i += 1
    endwhile
  endfor
  for list in a:lists
    call map(list, "printf('%-'.maxes[v:key].'s', v:val)")
  endfor
  return a:lists
endfunction

function! PivotalGetCurrentIteration()
  let res = webapi#http#get(s:ApiUrl('/iterations'), {'scope': 'current'}, { "X-TrackerToken": g:pivotal_auth_token })
  if res.status =~# '^2'
    try
      let iterations = webapi#json#decode(res.content)
    catch
      redraw
      echohl ErrorMsg | echomsg 'Pivotal api seems to be broken' | echohl None
      return
    endtry

    let stories = iterations[0]['stories']

    let story_titles = map(stories, {idx, story -> [story['id'], story['name']]})

    echo story_titles

    let aligned = sort(s:align_lists(story_titles))
    let items = map(aligned, 'v:val[0]."\t".v:val[1]')

    call fzf#run({'source': items, 'sink': function('s:FZFOpenPivotalStory'), 'down': '30%'})
  else
    redraw
    echohl ErrorMsg | echomsg 'VIM-PIVOTAL: Pivotal story not found' | echohl None
    return
  endif
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
  let res = webapi#http#get(s:ApiUrl('/stories/' . a:pivotalid), '', { "X-TrackerToken": g:pivotal_auth_token })
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
