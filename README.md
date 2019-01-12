# Vim Pivotal

Access Pivotal stories in Vim!


Prerequisites
-------------

This plugin requires [webapi-vim][a] and [fzf.vim][b], FZF is used for showing
current iteration stories in FZF window

Installation
------------

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'deepredsky/vim-pivotal'
```

This plugin requires pivotal project id and auth token to be configured.

```vim
  let g:project_id = 12345
  let g:pivotal_auth_token = 'xxooxxooxxooxx'
```

These values can also be set with environment variables via `PIVOTAL_PROJECT_ID` and  `PIVOTAL_AUTH_TOKEN`

Usage
-----

```vim

" Get a pivotal story by ID
:Pivotal 123456

" Fuzzy find pivotal stories in current iteration
:PivotalIteration

" Go to a story in Pivotal webpage ( in pivotal buffer )
:PivotalOpen

```


License
-------

MIT

[a]: https://github.com/mattn/webapi-vim
[b]: https://github.com/junegunn/fzf.vim
