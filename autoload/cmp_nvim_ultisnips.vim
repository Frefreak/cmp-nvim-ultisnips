" TODO: move python code into separate files

" Retrieves additional snippet information that is not directly accessible
" using the UltiSnips API functions. Returns a list of tables (one table
" per snippet) with the keys "trigger", "description", "options" and "value".
"
" If 'expandable_only' is "True", only expandable snippets are returned, otherwise all
" snippets for the current filetype are returned.
function! cmp_nvim_ultisnips#get_current_snippets(expandable_only)
let g:_cmpu_current_snippets = []
python3 << EOF
import vim
from UltiSnips import UltiSnips_Manager, vim_helper

if vim.eval("a:expandable_only") == "True":
    before = vim_helper.buf.line_till_cursor
    snippets = UltiSnips_Manager._snips(before, True)
else:
    snippets = UltiSnips_Manager._snips("", True)

for snippet in snippets:
    vim.command(
      "call add(g:_cmpu_current_snippets, {"
      "'trigger': py3eval('str(snippet._trigger)'),"
      "'description': py3eval('str(snippet._description)'),"
      "'options': py3eval('str(snippet._opts)'),"
      "'value': py3eval('str(snippet._value)'),"
      "'matched': py3eval('str(snippet._matched)'),"
      "})"
    )
EOF
return g:_cmpu_current_snippets
endfunction

function cmp_nvim_ultisnips#set_filetype(filetype)
python3 << EOF
import vim
from UltiSnips import vim_helper

filetype = vim.eval("a:filetype")
class CustomVimBuffer(vim_helper.VimBuffer):
  @property
  def filetypes(self):
    return [filetype]

vim_helper._orig_buf = vim_helper.buf
vim_helper.buf = CustomVimBuffer()  # TODO: avoid creating a new class instance every time
EOF
endfunction

function! cmp_nvim_ultisnips#reset_filetype()
python3 << EOF
from UltiSnips import vim_helper

# Restore to original VimBuffer instance
vim_helper.buf = vim_helper._orig_buf
EOF
endfunction

function! cmp_nvim_ultisnips#setup_treesitter_autocmds()
  augroup cmp_nvim_ultisnips
    autocmd!
    autocmd TextChangedI,TextChangedP * lua require("cmp_nvim_ultisnips.treesitter").set_filetype()
    autocmd InsertLeave * lua require("cmp_nvim_ultisnips.treesitter").reset_filetype()
  augroup end
endfunction

" Define silent mappings

" More info on why CursorMoved is called can be found here:
" https://github.com/SirVer/ultisnips/issues/1295#issuecomment-774056584
imap <silent> <Plug>(cmpu-expand)
\ <C-r>=[UltiSnips#CursorMoved(), UltiSnips#ExpandSnippet()][1]<cr>

smap <silent> <Plug>(cmpu-expand)
\ <Esc>:call UltiSnips#ExpandSnippetOrJump()<cr>

imap <silent> <Plug>(cmpu-jump-forwards)
\ <C-r>=UltiSnips#JumpForwards()<cr>

smap <silent> <Plug>(cmpu-jump-forwards)
\ <Esc>:call UltiSnips#JumpForwards()<cr>

imap <silent> <Plug>(cmpu-jump-backwards)
\ <C-r>=UltiSnips#JumpBackwards()<cr>

smap <silent> <Plug>(cmpu-jump-backwards)
\ <Esc>:call UltiSnips#JumpBackwards()<cr>
