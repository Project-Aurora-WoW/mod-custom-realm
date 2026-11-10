-- LuaSrcDiet.lua: минификация Lua-кода для AIO (AIO вызывает LuaSrcDiet(code, 3))
-- Источник: референс m-orlovrus59/dwrath-eluna-3-3-5a (Dep_LuaSrcDiet)
-- Адаптация консольной утилиты (c) 2008 Kein-Hong Man под вызов из AIO.

--[[----------------------------------------------------------------------

  LuaSrcDiet
  Compresses Lua source code by removing unnecessary characters.
  For Lua 5.1.x source code.

  Copyright (c) 2008 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

  See the ChangeLog for more information.

----------------------------------------------------------------------]]

-- standard libraries, functions
local string = string
local math = math
local table = table
local require = require
local print = print
local sub = string.sub
local gmatch = string.gmatch

-- support modules
local llex = require "llex"
local lparser = require "lparser"
local optlex = require "optlex"
local optparser = require "optparser"
local plugin

--[[--------------------------------------------------------------------
-- messages and textual data
----------------------------------------------------------------------]]

local MSG_TITLE = [[
LuaSrcDiet: Puts your Lua 5.1 source code on a diet
Version 0.11.2 (20080608)  Copyright (c) 2005-2008 Kein-Hong Man
The COPYRIGHT file describes the conditions under which this
software may be distributed.
]]

------------------------------------------------------------------------
-- optimization options, for ease of switching on and off
-- * positive to enable optimization, negative (no) to disable
-- * these options should follow --opt-* and --noopt-* style for now
------------------------------------------------------------------------

local OPTION = [[
--opt-comments,'remove comments and block comments'
--opt-whitespace,'remove whitespace excluding EOLs'
--opt-emptylines,'remove empty lines'
--opt-eols,'all above, plus remove unnecessary EOLs'
--opt-strings,'optimize strings and long strings'
--opt-numbers,'optimize numbers'
--opt-locals,'optimize local variable names'
--opt-entropy,'tries to reduce symbol entropy of locals'
]]

-- preset configuration
local DEFAULT_CONFIG = [[
  --opt-comments --opt-whitespace --opt-emptylines
  --opt-numbers --opt-locals
]]
-- override configurations: MUST explicitly enable/disable everything
local BASIC_CONFIG = [[
  --opt-comments --opt-whitespace --opt-emptylines
  --noopt-eols --noopt-strings --noopt-numbers
  --noopt-locals
]]
local MAXIMUM_CONFIG = [[
  --opt-comments --opt-whitespace --opt-emptylines
  --opt-eols --opt-strings --opt-numbers
  --opt-locals --opt-entropy
]]
local NONE_CONFIG = [[
  --noopt-comments --noopt-whitespace --noopt-emptylines
  --noopt-eols --noopt-strings --noopt-numbers
  --noopt-locals
]]

------------------------------------------------------------------------
-- prepares text for list of optimizations, prepare lookup table
------------------------------------------------------------------------

local MSG_OPTIONS = ""
do
  local WIDTH = 24
  local o = {}
  for op, desc in gmatch(OPTION, "%s*([^,]+),'([^']+)'") do
    local msg = "  "..op
    msg = msg..string.rep(" ", WIDTH - #msg)..desc.."\n"
    MSG_OPTIONS = MSG_OPTIONS..msg
    o[op] = true
    o["--no"..sub(op, 3)] = true
  end
  OPTION = o  -- replace OPTION with lookup table
end

------------------------------------------------------------------------
-- global variable initialization, option set handling
------------------------------------------------------------------------

local suffix = "_"           -- default suffix for file renaming
local option = {}                       -- program options
local stat_c, stat_l                    -- statistics tables

-- function to set option lookup table based on a text list of options
-- note: additional forced settings for --opt-eols is done in optlex.lua
local function set_options(CONFIG)
  for op in gmatch(CONFIG, "(%-%-%S+)") do
    if sub(op, 3, 4) == "no" and        -- handle negative options
       OPTION["--"..sub(op, 5)] then
      option[sub(op, 5)] = false
    else
      option[sub(op, 3)] = true
    end
  end
end

--[[--------------------------------------------------------------------
-- support functions
----------------------------------------------------------------------]]

-- list of token types, parser-significant types are up to TTYPE_GRAMMAR
-- while the rest are not used by parsers; arranged for stats display
local TTYPES = {
  "TK_KEYWORD", "TK_NAME", "TK_NUMBER",         -- grammar
  "TK_STRING", "TK_LSTRING", "TK_OP",
  "TK_EOS",
  "TK_COMMENT", "TK_LCOMMENT",                  -- non-grammar
  "TK_EOL", "TK_SPACE",
}
local TTYPE_GRAMMAR = 7

local EOLTYPES = {                      -- EOL names for token dump
  ["\n"] = "LF", ["\r"] = "CR",
  ["\n\r"] = "LFCR", ["\r\n"] = "CRLF",
}

------------------------------------------------------------------------
-- functions to deal with statistics
------------------------------------------------------------------------

-- initialize statistics table
local function stat_init()
  stat_c, stat_l = {}, {}
  for i = 1, #TTYPES do
    local ttype = TTYPES[i]
    stat_c[ttype], stat_l[ttype] = 0, 0
  end
end

-- add a token to statistics table
local function stat_add(tok, seminfo)
  stat_c[tok] = stat_c[tok] + 1
  stat_l[tok] = stat_l[tok] + #seminfo
end

-- do totals for statistics table, return average table
local function stat_calc()
  local function avg(c, l)                      -- safe average function
    if c == 0 then return 0 end
    return l / c
  end
  local stat_a = {}
  local c, l = 0, 0
  for i = 1, TTYPE_GRAMMAR do                   -- total grammar tokens
    local ttype = TTYPES[i]
    c = c + stat_c[ttype]; l = l + stat_l[ttype]
  end
  stat_c.TOTAL_TOK, stat_l.TOTAL_TOK = c, l
  stat_a.TOTAL_TOK = avg(c, l)
  c, l = 0, 0
  for i = 1, #TTYPES do                         -- total all tokens
    local ttype = TTYPES[i]
    c = c + stat_c[ttype]; l = l + stat_l[ttype]
    stat_a[ttype] = avg(stat_c[ttype], stat_l[ttype])
  end
  stat_c.TOTAL_ALL, stat_l.TOTAL_ALL = c, l
  stat_a.TOTAL_ALL = avg(c, l)
  return stat_a
end

------------------------------------------------------------------------
-- process source code, write output and reports some statistics
------------------------------------------------------------------------

local function process_file(code)
  local function print(...)             -- handle quiet option
    if option.QUIET then return end
    _G.print(...)
  end
  print(MSG_TITLE)                      -- title message
  --------------------------------------------------------------------
  -- load file and process source input into tokens
  --------------------------------------------------------------------
  local z = code
  if plugin and plugin.post_load then   -- plugin post-load
    z = plugin.post_load(z) or z
    if option.EXIT then return end
  end
  llex.init(z)
  llex.llex()
  local toklist, seminfolist, toklnlist
    = llex.tok, llex.seminfo, llex.tokln
  if plugin and plugin.post_lex then    -- plugin post-lex
    plugin.post_lex(toklist, seminfolist, toklnlist)
    if option.EXIT then return end
  end
  --------------------------------------------------------------------
  -- collect 'before' statistics
  --------------------------------------------------------------------
  stat_init()
  for i = 1, #toklist do
    local tok, seminfo = toklist[i], seminfolist[i]
    stat_add(tok, seminfo)
  end--for
  local stat1_a = stat_calc()
  local stat1_c, stat1_l = stat_c, stat_l
  --------------------------------------------------------------------
  -- do parser optimization here
  --------------------------------------------------------------------
  if option["opt-locals"] then
    optparser.print = print  -- hack
    lparser.init(toklist, seminfolist, toklnlist)
    local globalinfo, localinfo = lparser.parser()
    if plugin and plugin.post_parse then        -- plugin post-parse
      plugin.post_parse(globalinfo, localinfo)
      if option.EXIT then return end
    end
    optparser.optimize(option, toklist, seminfolist, globalinfo, localinfo)
    if plugin and plugin.post_optparse then     -- plugin post-optparse
      plugin.post_optparse()
      if option.EXIT then return end
    end
  end
  --------------------------------------------------------------------
  -- do lexer optimization here, save output file
  --------------------------------------------------------------------
  optlex.print = print  -- hack
  toklist, seminfolist, toklnlist
    = optlex.optimize(option, toklist, seminfolist, toklnlist)
  if plugin and plugin.post_optlex then         -- plugin post-optlex
    plugin.post_optlex(toklist, seminfolist, toklnlist)
    if option.EXIT then return end
  end
  local dat = table.concat(seminfolist)
  -- depending on options selected, embedded EOLs in long strings and
  -- long comments may not have been translated to \n, tack a warning
  if string.find(dat, "\r\n", 1, 1) or
     string.find(dat, "\n\r", 1, 1) then
    optlex.warn.mixedeol = true
  end
  --------------------------------------------------------------------
  -- report warning flags from optimizing process
  --------------------------------------------------------------------
  if optlex.warn.lstring then
    print("* WARNING: "..optlex.warn.lstring)
  elseif optlex.warn.mixedeol then
    print("* WARNING: ".."output still contains some CRLF or LFCR line endings")
  end
  print()
  return dat
end

local function process_code(code, config)
    option.QUIET = true
    if config == 1 then
        set_options(DEFAULT_CONFIG)
    elseif config == 2 then
        set_options(BASIC_CONFIG)
    elseif config == 3 then
        set_options(MAXIMUM_CONFIG)
    else
        set_options(NONE_CONFIG)
    end

  local function print(...)             -- handle quiet option
    if option.QUIET then return end
    _G.print(...)
  end
  print(MSG_TITLE)                      -- title message
  --------------------------------------------------------------------
  -- load file and process source input into tokens
  --------------------------------------------------------------------
  local z = code
  if plugin and plugin.post_load then   -- plugin post-load
    z = plugin.post_load(z) or z
    if option.EXIT then return end
  end
  llex.init(z)
  llex.llex()
  local toklist, seminfolist, toklnlist
    = llex.tok, llex.seminfo, llex.tokln
  if plugin and plugin.post_lex then    -- plugin post-lex
    plugin.post_lex(toklist, seminfolist, toklnlist)
    if option.EXIT then return end
  end
  --------------------------------------------------------------------
  -- collect 'before' statistics
  --------------------------------------------------------------------
  stat_init()
  for i = 1, #toklist do
    local tok, seminfo = toklist[i], seminfolist[i]
    stat_add(tok, seminfo)
  end--for
  local stat1_a = stat_calc()
  local stat1_c, stat1_l = stat_c, stat_l
  --------------------------------------------------------------------
  -- do parser optimization here
  --------------------------------------------------------------------
  if option["opt-locals"] then
    optparser.print = print  -- hack
    lparser.init(toklist, seminfolist, toklnlist)
    local globalinfo, localinfo = lparser.parser()
    if plugin and plugin.post_parse then        -- plugin post-parse
      plugin.post_parse(globalinfo, localinfo)
      if option.EXIT then return end
    end
    optparser.optimize(option, toklist, seminfolist, globalinfo, localinfo)
    if plugin and plugin.post_optparse then     -- plugin post-optparse
      plugin.post_optparse()
      if option.EXIT then return end
    end
  end
  --------------------------------------------------------------------
  -- do lexer optimization here, save output file
  --------------------------------------------------------------------
  optlex.print = print  -- hack
  toklist, seminfolist, toklnlist
    = optlex.optimize(option, toklist, seminfolist, toklnlist)
  if plugin and plugin.post_optlex then         -- plugin post-optlex
    plugin.post_optlex(toklist, seminfolist, toklnlist)
    if option.EXIT then return end
  end
  local dat = table.concat(seminfolist)
  -- depending on options selected, embedded EOLs in long strings and
  -- long comments may not have been translated to \n, tack a warning
  if string.find(dat, "\r\n", 1, 1) or
     string.find(dat, "\n\r", 1, 1) then
    optlex.warn.mixedeol = true
  end
  --------------------------------------------------------------------
  -- report warning flags from optimizing process
  --------------------------------------------------------------------
  if optlex.warn.lstring then
    print("* WARNING: "..optlex.warn.lstring)
  elseif optlex.warn.mixedeol then
    print("* WARNING: ".."output still contains some CRLF or LFCR line endings")
  end
  print()
  return dat
end

--[[--------------------------------------------------------------------
-- main
----------------------------------------------------------------------]]

set_options(DEFAULT_CONFIG)     -- set to default options at beginning

return process_code
