import strutils, json, re
# import nimprof

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
    lineong,
    code,
    image,
    text

type 
  Block = ref object
    kind: Blocktype
    values: Inline
 
  Inline = ref object
    kind: Inlinetype
    value: string

  Root = ref object
    kind: string
    children: seq[Block]

let
  reHeader = re"^(#|##|###|####|#####|######) "
  reBlockquote = re"^> "
  reBulletList = re"^(-|\+|\*) "
  reOrderedList = re"^(1|2|3|4|5|6|7|8|9) "
  reCodeBlock = re"^(```|~~~)"

proc isHeader(line: string): bool =
  match(line, reHeader)

proc isBlockquote(line: string): bool =
  match(line, reBlockquote)

proc isCodeFence(line: string): bool =
  match(line, reCodeBlock)

proc parseHeader(line: string): Block =
  case line.splitWhitespace[0]:
    of "#":
      let str = line.replace(reHeader)
      return Block(kind: header1, values: Inline(kind: text, value: str))
    of "##":
      let str = line.replace(reHeader)
      return Block(kind: header2, values: Inline(kind: text, value: str))
    of "###":
      let str = line.replace(reHeader)
      return Block(kind: header3, values: Inline(kind: text, value: str))
    of "####":
      let str = line.replace(reHeader)
      return Block(kind: header4, values: Inline(kind: text, value: str))
    of "#####":
      let str = line.replace(reHeader)
      return Block(kind: header5, values: Inline(kind: text, value: str))
    of "######":
      let str = line.replace(reHeader)
      return Block(kind: header6, values: Inline(kind: text, value: str))

proc parseBlockquote(line: string): Block =
  let str = line.replace(reBlockquote)
  return Block(kind: blockquote, values: Inline(kind: text, value: str))

proc parseParagraph(line: string): Block =
  Block(kind: paragraph, values: Inline(kind: text, value: line))

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
        mdast.add(parseParagraph(lineBlock))
        lineBlock = ""

    elif line.isCodeFence:
      if lineBlock != "":
        mdast.add(parseParagraph(lineBlock))
        lineBlock = ""
      isCodeBlock = true

    elif line.isHeader:
      if lineBlock != "":
        mdast.add(parseParagraph(lineBlock))
      mdast.add(parseHeader(line))
      lineBlock = ""
    
    elif line.isBlockquote:
      if lineBlock != "":
        mdast.add(parseParagraph(lineBlock))
      mdast.add(parseBlockquote(line))
      lineBlock = ""
    
    else:
      lineBlock.add(line)

  if lineBlock != "":
    mdast.add(parseParagraph(lineBlock))

  return mdast

when isMainModule:
  var s = readFile("testfiles/1.md").replace("  \n", "<br />")
  var root = Root(kind: "root", children: @[])
  root.children = parseLine(s)
  echo %root