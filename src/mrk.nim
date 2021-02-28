# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import strutils, json

type
  Blocktype = enum
    undefinedblock,
    paragraph,
    header1,
    header2,
    header3,
    header4,
    header5,
    header6,
    blockquote,
    list,
    codeblock,
    horizontalrule
  Inlinetype = enum
    undefinedinline,
    linebreak,
    softbreak,
    link,
    em,
    strong,
    code,
    image,
    text

type 
  Block = object
    kind: Blocktype
    values: Inline
 
  Inline = object
    kind: Inlinetype
    value: string

  Root = object
    kind: string
    children: seq[Block]
  
proc parseHeader(s: string, split: seq[string]): Block =
  var str = s
  case split[0]:
    of "#":
      str.delete(0,1)
      return Block(kind: header1, values: Inline(kind: text, value: str))
    of "##":
      str.delete(0,2)
      return Block(kind: header2, values: Inline(kind: text, value: str))
    of "###":
      str.delete(0,3)
      return Block(kind: header3, values: Inline(kind: text, value: str))
    of "####":
      str.delete(0,4)
      return Block(kind: header4, values: Inline(kind: text, value: str))
    of "#####":
      str.delete(0,5)
      return Block(kind: header5, values: Inline(kind: text, value: str))
    of "######":
      str.delete(0,6)
      return Block(kind: header6, values: Inline(kind: text, value: str))

proc parseBlockquote(s: string, split: seq[string]): Block =
  var str = s
  str.delete(0,1)
  return Block(kind: blockquote, values: Inline(kind: text, value: str))

proc parseParagraph(s: string): Block =
  Block(kind: paragraph, values: Inline(kind: text, value: s))

proc parseBlock(s:string): Block =
  var split = s.splitWhitespace
  case split[0]:
    of "#", "##", "###", "####", "#####", "######":
      parseHeader(s, split)
    of ">":
      parseBlockquote(s, split)
    else:
      parseParagraph(s)

when isMainModule:
  let path = readLine(stdin)
  var s = readFile(path).replace("  ","<br />")
  var root = Root(kind: "root", children: @[])
  var lineblock: string
  var mdast: seq[Block]
  for line in s.splitLines:
    if line.isEmptyOrWhitespace:
      mdast.add(Block(kind: undefinedblock, values:Inline(kind: undefinedinline, value: lineblock)))
      lineblock = ""
    else:
      lineblock.add(line)
  mdast.add(Block(kind: undefinedblock, values:Inline(kind: undefinedinline, value: lineblock)))
  root.children = mdast
  echo %root