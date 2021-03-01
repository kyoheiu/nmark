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
  
proc isCodeFence(line: string): bool =
  if line.len() < 3:
    false
  else:
    let firstThree = line[0..2]
    firstThree == "```" or firstThree == "~~~"

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

proc parseLinequote(s: string, split: seq[string]): Block =
  var str = s
  str.delete(0,1)
  return Block(kind: blockquote, values: Inline(kind: text, value: str))

proc parseParagraph(s: string): Block =
  Block(kind: paragraph, values: Inline(kind: text, value: s))

proc parseLine(s: string): seq[Block] =
  var mdast: seq[Block]
  var lineBlock: string
  var isCodeBlock = false
  for line in s.splitLines:
    if isCodeBlock:
      if not line.isCodeFence:
        lineBlock.add(line & "\n")
      else:
        mdast.add(Block(kind: codeblock, values: Inline(kind: code, value: lineBlock)))
        lineblock = ""
        isCodeBlock = false
    elif line.isEmptyOrWhitespace:
      if not lineBlock.isEmptyOrWhitespace:
        mdast.add(Block(kind: paragraph, values: Inline(kind: undefinedinline, value: lineBlock)))
        lineBlock = ""
    elif line[0] == '`' or line[0] == '~':
      if line.len() >= 3 and line.isCodeFence:
        if lineBlock != "":
          mdast.add(Block(kind: paragraph, values:Inline(kind: undefinedinline, value: lineBlock)))
          lineBlock = ""
        isCodeBlock = true

    else:
      var split = line.splitWhitespace
      case split[0]:
        of "#", "##", "###", "####", "#####", "######":
          if lineBlock != "":
            mdast.add(Block(kind: paragraph, values: Inline(kind: undefinedinline, value: lineBlock)))
          mdast.add(parseHeader(line, split))
          lineBlock = ""
        of ">":
          if lineBlock != "":
            mdast.add(Block(kind: paragraph, values: Inline(kind: undefinedinline, value: lineBlock)))
          mdast.add(parseLinequote(line, split))
          lineBlock = ""
        else:
          lineBlock.add(line)

  mdast.add(Block(kind: paragraph, values:Inline(kind: undefinedinline, value: lineBlock)))
  return mdast

when isMainModule:
  var s = readFile("testfiles/1.md").replace("  \n", "<br />")
  var root = Root(kind: "root", children: @[])
  root.children = parseLine(s)
  echo %root