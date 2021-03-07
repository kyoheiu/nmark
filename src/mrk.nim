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
    unorderedlist,
    orderedlist,
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

  ToggleContainer = ref object
    toggleBlockquote: bool
    toggleCodeBlock: bool
    toggleBulletListDashSpace: bool
    toggleBulletListPlusSpace: bool
    toggleBulletListAsteSpace: bool
    toggleBulletListDashPare: bool
    toggleBulletListPlusPare: bool
    toggleBulletListAstePare: bool
    toggleOrderedListSpace: bool
    toggleOrderedListPare: bool

type 
  Block = ref object
    kind: Blocktype
    values: Inline
 
  Inline = ref object
    kind: Inlinetype
    value: seq[string]

  Root = ref object
    kind: string
    children: seq[Block]

let
  reHeader = re"^(#|##|###|####|#####|######) "
  reBlockquote = re"^> "
  reBulletListDashSpace = re"^- "
  reBulletListPlusSpace = re"^\+ "
  reBulletListAsteSpace = re"^\* "
  reBulletListDashPare = re"^-\)"
  reBulletListPlusPare = re"^\+\)"
  reBulletListAstePare = re"^\*\)"
  reOrderedListSpaceStart = re"1\. "
  reOrderedListPareStart = re"1\)"
  reOrderedListSpace = re"^(2|3|4|5|6|7|8|9)\. "
  reOrderedListPare = re"^(2|3|4|5|6|7|8|9)\)"
  reCodeBlock = re"^(```|~~~)"

proc isHeader(line: string): bool =
  match(line, reHeader)

proc isBlockquote(line: string): bool =
  match(line, reBlockquote)

proc isCodeFence(line: string): bool =
  match(line, reCodeBlock)

proc isBulletListDashSpace(line: string): bool =
  match(line, reBulletListDashSpace)
proc isBulletListPlusSpace(line: string): bool =
  match(line, reBulletListPlusSpace)
proc isBulletListAsteSpace(line: string): bool =
  match(line, reBulletListAsteSpace)
proc isBulletListDashPare(line: string): bool =
  match(line, reBulletListDashPare)
proc isBulletListPlusPare(line: string): bool =
  match(line, reBulletListDashPare)
proc isBulletListAstePare(line: string): bool =
  match(line, reBulletListDashPare)
proc isOrderdListSpaceStart(line: string): bool =
  match(line, reOrderedListSpaceStart)
proc isOrderdListPareStart(line: string): bool =
  match(line, reOrderedListPareStart)
proc isOrderdListSpace(line: string): bool =
  match(line, reOrderedListSpace)
proc isOrderdListPare(line: string): bool =
  match(line, reOrderedListPare)

proc newToggle(): ToggleContainer =
  ToggleContainer(
    toggleBlockquote: false,
    toggleCodeBlock: false,
    toggleBulletListDashSpace: false,
    toggleBulletListPlusSpace: false,
    toggleBulletListAsteSpace: false,
    toggleBulletListDashPare: false,
    toggleBulletListPlusPare: false,
    toggleBulletListAstePare: false,
    toggleOrderedListSpace: false,
    toggleOrderedListPare: false
  )

proc parseHeader(line: string): Block =
  case line.splitWhitespace[0]:
    of "#":
      let str = line.replace(reHeader)
      return Block(kind: header1, values: Inline(kind: text, value: @[str]))
    of "##":
      let str = line.replace(reHeader)
      return Block(kind: header2, values: Inline(kind: text, value: @[str]))
    of "###":
      let str = line.replace(reHeader)
      return Block(kind: header3, values: Inline(kind: text, value: @[str]))
    of "####":
      let str = line.replace(reHeader)
      return Block(kind: header4, values: Inline(kind: text, value: @[str]))
    of "#####":
      let str = line.replace(reHeader)
      return Block(kind: header5, values: Inline(kind: text, value: @[str]))
    of "######":
      let str = line.replace(reHeader)
      return Block(kind: header6, values: Inline(kind: text, value: @[str]))

proc parseBlockquote(line: string): Block =
  let str = line.replace(reBlockquote)
  return Block(kind: blockquote, values: Inline(kind: text, value: @[str]))

proc parseParagraph(line: string): Block =
  Block(kind: paragraph, values: Inline(kind: text, value: @[line]))

proc parseLine(s: string): seq[Block] =
  var mdast: seq[Block]
  var lineBlock: string
  var unorderedListSeq: seq[string]
  var orderedListSeq: seq[string]
  var container = newToggle()

  for line in s.splitLines:

    block bulletListDashSpace:
      if container.toggleBulletListDashSpace:
        if line.isBulletListDashSpace:
          unorderedListSeq.add(line.replace(reBulletListDashSpace))
          continue
        else:
          mdast.add(Block(kind: unorderedlist, values: Inline(kind: text, value: unorderedListSeq)))
          unorderedListSeq = @[]
          container.toggleBulletListDashSpace = false
          break bulletListDashSpace

    block orderedListDashSpace:
      if container.toggleOrderedListSpace:
        if line.isOrderdListSpace:
          orderedListSeq.add(line.replace(reOrderedListSpace))
          continue
        else:
          mdast.add(Block(kind: orderedlist, values: Inline(kind: text, value: orderedListSeq)))
          orderedListSeq = @[]
          container.toggleOrderedListSpace = false
          break orderedListDashSpace

    if container.toggleCodeBlock:
      if not line.isCodeFence:
        lineBlock.add(line & "<br />")
      else:
        mdast.add(Block(kind: codeblock, values: Inline(kind: code, value: @[lineBlock])))
        lineblock = ""
        container.toggleCodeBlock = false

    elif line.isEmptyOrWhitespace:
      if not lineBlock.isEmptyOrWhitespace:
        mdast.add(parseParagraph(lineBlock))
        lineBlock = ""

    elif line.isCodeFence:
      if lineBlock != "":
        mdast.add(parseParagraph(lineBlock))
        lineBlock = ""
      container.toggleCodeBlock = true

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
    
    elif line.isBulletListDashSpace:
      if lineBlock != "":
        mdast.add(parseParagraph(lineBlock))
        lineBlock = ""
      unorderedListSeq.add(line.replace(reBulletListDashSpace))
      container.toggleBulletListDashSpace = true
    elif line.isBulletListPlusSpace:
      if lineBlock != "":
        mdast.add(parseParagraph(lineBlock))
        lineBlock = ""
      unorderedListSeq.add(line.replace(reBulletListPlusSpace))
      container.toggleBulletListPlusSpace = true
    elif line.isBulletListAsteSpace:
      if lineBlock != "":
        mdast.add(parseParagraph(lineBlock))
        lineBlock = ""
      unorderedListSeq.add(line.replace(reBulletListAsteSpace))
      container.toggleBulletListAsteSpace = true
    
    elif line.isBulletListDashPare:
      if lineBlock != "":
        mdast.add(parseParagraph(lineBlock))
        lineBlock = ""
      unorderedListSeq.add(line.replace(reBulletListDashPare))
      container.toggleBulletListDashPare = true
    elif line.isBulletListPlusPare:
      if lineBlock != "":
        mdast.add(parseParagraph(lineBlock))
        lineBlock = ""
      unorderedListSeq.add(line.replace(reBulletListPlusPare))
      container.toggleBulletListPlusPare = true
    elif line.isBulletListAstePare:
      if lineBlock != "":
        mdast.add(parseParagraph(lineBlock))
        lineBlock = ""
      unorderedListSeq.add(line.replace(reBulletListPlusPare))
      container.toggleBulletListAstePare = true
    
    elif line.isOrderdListSpaceStart:
      if lineBlock != "":
        mdast.add(parseParagraph(lineBlock))
        lineBlock = ""
      orderedListSeq.add(line.replace(reOrderedListSpaceStart))
      container.toggleOrderedListSpace = true

    elif line.isOrderdListPareStart:
      if lineBlock != "":
        mdast.add(parseParagraph(lineBlock))
        lineBlock = ""
      orderedListSeq.add(line.replace(reOrderedListPareStart))
      container.toggleOrderedListPare = true

    else:
      lineBlock.add(line)

  if lineBlock != "":
    mdast.add(parseParagraph(lineBlock))

  return mdast

when isMainModule:
  var s = readFile("testfiles/1.md").replace("  \n", "<br />")
  var root = Root(kind: "root", children: @[])
  root.children = parseLine(s)
  echo pretty(%root)