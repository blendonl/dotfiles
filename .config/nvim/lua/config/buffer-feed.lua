-- Buffer feed: every listed buffer's contents stitched end to end into one
-- scratch buffer, so a single vertical scroll carries you across files.
--
-- A Neovim window renders exactly one buffer, so the feed is a rendered copy of
-- the others rather than the others themselves. That makes it read-only: <CR>
-- jumps to the real buffer at the line (and column) under the cursor.
--
-- Sections track the buffer list as it changes. `dd` closes the buffer under
-- the cursor outright; `x` only drops it from the feed and leaves it open.

local M = {}

local ns = vim.api.nvim_create_namespace("buffer_feed")

-- Treesitter over a huge section costs more than the colour is worth.
local MAX_HIGHLIGHT_LINES = 5000

-- Captures that steer spelling or concealing rather than naming a colour.
local NOT_A_COLOUR = { conceal = true, spell = true, nospell = true, none = true }

local state = {
  buf = nil,      -- the feed scratch buffer, reused across opens
  tab = nil,      -- tabpage the feed was opened in, so `q` only closes our own
  map = {},       -- feed lnum -> { buf = <source bufnr>, line = <source lnum> }
  owner = {},     -- feed lnum -> source bufnr, headers and spacers included
  first = {},     -- source bufnr -> its first content lnum in the feed
  header = {},    -- feed lnum -> true
  headers = {},   -- sorted list of header lnums, for [[ and ]]
  hidden = {},    -- source bufnr -> true, dropped from the feed but still open
  building = false,
}

-- The feed usually sits in its own tabpage, and bufwinid() only ever looks at
-- the current one -- win_findbuf searches every tabpage, which is what lets an
-- edit made elsewhere refresh the feed.
local function feed_win()
  if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
    return -1
  end
  return vim.fn.win_findbuf(state.buf)[1] or -1
end

local function collect()
  local bufs = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if b ~= state.buf
        and not state.hidden[b]
        and vim.bo[b].buflisted
        and vim.bo[b].buftype == ""
        and vim.api.nvim_buf_get_name(b) ~= ""
    then
      bufs[#bufs + 1] = b
    end
  end
  return bufs
end

local function hidden_count()
  local n = 0
  for b in pairs(state.hidden) do
    -- Drop entries whose buffer has since been wiped; bufnrs get reused.
    if vim.api.nvim_buf_is_valid(b) and vim.bo[b].buflisted then
      n = n + 1
    else
      state.hidden[b] = nil
    end
  end
  return n
end

local function header_text(name, count)
  local label = ("── %s  %d lines "):format(name, count)
  local pad = math.max(vim.o.columns - vim.fn.strdisplaywidth(label) - 8, 3)
  return label .. string.rep("─", pad)
end

-- Walk a parser and every injected child parser under it.
local function each_tree(ltree, fn)
  for _, tree in pairs(ltree:trees()) do
    fn(tree, ltree:lang())
  end
  for _, child in pairs(ltree:children()) do
    each_tree(child, fn)
  end
end

-- Re-run the source buffer's own highlight query and replay the captures into
-- the feed at a line offset, so each section keeps its real filetype colours.
local function highlight_section(feed, src, offset, count)
  if count > MAX_HIGHLIGHT_LINES then
    return
  end
  local ok, parser = pcall(vim.treesitter.get_parser, src)
  if not ok or not parser then
    return
  end
  if not pcall(parser.parse, parser, true) then
    return
  end

  local last_len = #(vim.api.nvim_buf_get_lines(src, count - 1, count, false)[1] or "")

  each_tree(parser, function(tree, lang)
    -- A parser that has drifted from its queries raises here rather than
    -- returning nil; one bad language must not sink the whole feed.
    local ok_query, query = pcall(vim.treesitter.query.get, lang, "highlights")
    if not ok_query or not query then
      return
    end
    pcall(function()
      for id, node in query:iter_captures(tree:root(), src) do
        local sr, sc, er, ec = node:range()
        local capture = query.captures[id]
        local base = capture:match("^([^.]+)")
        if sr < count and not NOT_A_COLOUR[base] then
          -- A node may end one past the final line; pull it back in range.
          if er >= count then
            er, ec = count - 1, last_len
          end
          -- Lay the generic group down first so a colourscheme that never
          -- defines the dotted variant still paints something.
          if base ~= capture then
            pcall(vim.api.nvim_buf_set_extmark, feed, ns, offset + sr, sc, {
              end_row = offset + er,
              end_col = ec,
              hl_group = "@" .. base,
              priority = 100,
            })
          end
          pcall(vim.api.nvim_buf_set_extmark, feed, ns, offset + sr, sc, {
            end_row = offset + er,
            end_col = ec,
            hl_group = "@" .. capture,
            priority = 101,
          })
        end
      end
    end)
  end)
end

local function build()
  local feed = state.buf
  local lines, map, owner, first, header, headers, sections = {}, {}, {}, {}, {}, {}, {}

  for _, b in ipairs(collect()) do
    vim.fn.bufload(b)
    local src = vim.api.nvim_buf_get_lines(b, 0, -1, false)
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ":~:.")

    -- The blank line before a header belongs to the section it introduces, so
    -- `dd` works anywhere in a section including its top edge.
    if #lines > 0 then
      lines[#lines + 1] = ""
      owner[#lines] = b
    end
    lines[#lines + 1] = header_text(name, #src)
    owner[#lines] = b
    header[#lines] = true
    headers[#headers + 1] = #lines

    local offset = #lines -- 0-indexed row the first content line lands on
    first[b] = #lines + 1
    for i, line in ipairs(src) do
      lines[#lines + 1] = line
      map[#lines] = { buf = b, line = i }
      owner[#lines] = b
    end
    sections[#sections + 1] = { buf = b, offset = offset, count = #src }
  end

  local hidden = hidden_count()
  if #lines == 0 then
    lines = { hidden > 0 and "All buffers hidden." or "No listed buffers." }
  end
  if hidden > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("── %d buffer(s) hidden -- press X to bring them back "):format(hidden)
  end

  vim.bo[feed].modifiable = true
  vim.api.nvim_buf_set_lines(feed, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(feed, ns, 0, -1)

  for _, lnum in ipairs(headers) do
    vim.api.nvim_buf_set_extmark(feed, ns, lnum - 1, 0, {
      end_row = lnum - 1,
      end_col = #lines[lnum],
      hl_group = "Title",
      priority = 200,
    })
  end
  for _, section in ipairs(sections) do
    pcall(highlight_section, feed, section.buf, section.offset, section.count)
  end

  vim.bo[feed].modifiable = false
  vim.bo[feed].modified = false
  state.map, state.owner, state.first = map, owner, first
  state.header, state.headers = header, headers
end

-- Fold each file into one section.
function M.foldexpr()
  return state.header[vim.v.lnum] and ">1" or "1"
end

-- Show the line number the line has in its *source* file, not in the feed.
function M.statuscolumn()
  local entry = state.map[vim.v.lnum]
  if not entry then
    return "     "
  end
  return ("%4d "):format(entry.line)
end

-- The source buffer the cursor is sitting in, header and spacer lines included.
local function buf_at_cursor()
  return state.owner[vim.fn.line(".")]
end

function M.jump()
  local lnum = vim.fn.line(".")
  local entry = state.map[lnum]
  if not entry then
    -- On a header or spacer: take the first content line of that section.
    local owner = state.owner[lnum]
    entry = owner and state.first[owner] and state.map[state.first[owner]]
  end
  if not entry then
    vim.notify("buffer-feed: nothing to jump to here", vim.log.levels.WARN)
    return
  end
  if not vim.api.nvim_buf_is_valid(entry.buf) then
    vim.notify("buffer-feed: source buffer is gone, press R to refresh", vim.log.levels.WARN)
    return
  end

  local col = math.max(vim.fn.col(".") - 1, 0)
  M.close()
  vim.api.nvim_set_current_buf(entry.buf)
  local last = vim.api.nvim_buf_line_count(entry.buf)
  local line = math.min(entry.line, last)
  pcall(vim.api.nvim_win_set_cursor, 0, { line, col })
  vim.cmd("normal! zz")
end

function M.close()
  if state.tab and vim.api.nvim_tabpage_is_valid(state.tab) and #vim.api.nvim_list_tabpages() > 1 then
    vim.api.nvim_set_current_tabpage(state.tab)
    vim.cmd("tabclose")
  end
  state.tab = nil
end

function M.refresh()
  local win = feed_win()
  -- A refresh can be triggered from a window in another tabpage, so save and
  -- restore the view inside the feed's own window rather than the current one.
  if win == -1 or state.building then
    return
  end
  state.building = true
  pcall(vim.api.nvim_win_call, win, function()
    local view = vim.fn.winsaveview()
    build()
    view.lnum = math.min(view.lnum, vim.api.nvim_buf_line_count(state.buf))
    view.topline = math.min(view.topline, vim.api.nvim_buf_line_count(state.buf))
    vim.fn.winrestview(view)
  end)
  state.building = false
end

-- Delete the buffer the cursor is in, the way <leader>bd already does it.
function M.remove(force)
  local buf = buf_at_cursor()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    vim.notify("buffer-feed: no buffer under the cursor", vim.log.levels.WARN)
    return
  end

  local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":~:.")
  if vim.bo[buf].modified and not force then
    local choice = vim.fn.confirm(("Save changes to %q?"):format(name), "&Yes\n&No\n&Cancel")
    if choice == 1 then
      vim.api.nvim_buf_call(buf, function() vim.cmd("write") end)
    elseif choice == 2 then
      force = true
    else
      return
    end
  end

  -- mini.bufremove keeps the window layout intact; fall back if it is absent.
  local ok, bufremove = pcall(require, "mini.bufremove")
  if ok then
    bufremove.delete(buf, force)
  else
    pcall(vim.api.nvim_buf_delete, buf, { force = force })
  end
  state.hidden[buf] = nil
  M.refresh()
end

-- Drop a buffer from the feed without closing it.
function M.hide()
  local buf = buf_at_cursor()
  if not buf then
    vim.notify("buffer-feed: no buffer under the cursor", vim.log.levels.WARN)
    return
  end
  state.hidden[buf] = true
  M.refresh()
end

function M.unhide_all()
  state.hidden = {}
  M.refresh()
end

local function goto_header(dir)
  local cur = vim.fn.line(".")
  local target
  if dir > 0 then
    for _, lnum in ipairs(state.headers) do
      if lnum > cur then
        target = lnum
        break
      end
    end
  else
    for _, lnum in ipairs(state.headers) do
      if lnum < cur then
        target = lnum
      end
    end
  end
  if target then
    vim.api.nvim_win_set_cursor(0, { target, 0 })
    vim.cmd("normal! zt")
  end
end

local function keymaps(buf)
  local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = buf, nowait = true, desc = desc })
  end
  map("<CR>", M.jump, "Jump to source line")
  map("q", M.close, "Close feed")
  map("R", M.refresh, "Rebuild feed")
  map("]]", function() goto_header(1) end, "Next file")
  map("[[", function() goto_header(-1) end, "Previous file")
  map("dd", function() M.remove(false) end, "Delete this buffer")
  map("D", function() M.remove(true) end, "Delete this buffer (force)")
  map("x", M.hide, "Hide this buffer from the feed")
  map("X", M.unhide_all, "Show hidden buffers again")
end

local function window_options(win)
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true
  vim.wo[win].foldmethod = "expr"
  vim.wo[win].foldexpr = "v:lua.require'config.buffer-feed'.foldexpr()"
  vim.wo[win].foldlevel = 99
  vim.wo[win].statuscolumn = "%!v:lua.require'config.buffer-feed'.statuscolumn()"
end

function M.open()
  local win = feed_win()
  if win ~= -1 then
    vim.api.nvim_set_current_win(win)
    M.refresh()
    return
  end

  if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.buf].buftype = "nofile"
    vim.bo[state.buf].bufhidden = "hide"
    vim.bo[state.buf].swapfile = false
    vim.bo[state.buf].filetype = "bufferfeed"
    pcall(vim.api.nvim_buf_set_name, state.buf, "buffer-feed://all")
    keymaps(state.buf)
  end

  vim.cmd("tabnew")
  local throwaway = vim.api.nvim_get_current_buf()
  win = vim.api.nvim_get_current_win()
  state.tab = vim.api.nvim_get_current_tabpage()
  vim.api.nvim_win_set_buf(win, state.buf)
  if throwaway ~= state.buf and vim.api.nvim_buf_is_valid(throwaway) then
    pcall(vim.api.nvim_buf_delete, throwaway, { force = true })
  end

  build()
  window_options(win)
end

function M.toggle()
  if feed_win() ~= -1 then
    M.close()
  else
    M.open()
  end
end

vim.api.nvim_create_user_command("BufferFeed", M.toggle, { desc = "Toggle the buffer feed" })

-- BufAdd fires before the file has been read, so rebuilds are scheduled rather
-- than run inline; by the time one lands the new buffer has its contents. The
-- pending flag collapses a burst -- `:args *.lua` -- into a single rebuild.
local function schedule_refresh()
  if state.pending or state.building or feed_win() == -1 then
    return
  end
  state.pending = true
  vim.schedule(function()
    state.pending = false
    M.refresh()
  end)
end

local group = vim.api.nvim_create_augroup("BufferFeed", { clear = true })
vim.api.nvim_create_autocmd(
  { "BufAdd", "BufNew", "BufReadPost", "BufWritePost", "BufDelete", "BufFilePost" },
  { group = group, callback = schedule_refresh }
)

-- Catch anything the events above miss: whenever you land back on the feed, it
-- is current.
vim.api.nvim_create_autocmd({ "TabEnter", "WinEnter" }, {
  group = group,
  callback = function()
    if state.buf and vim.api.nvim_get_current_buf() == state.buf then
      schedule_refresh()
    end
  end,
})

return M
