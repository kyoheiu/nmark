import strutils, json, re
# import nimprof

type
  BlockType = enum
    undefinedBlock,
    paragraph,
    header1,
    header2,
    header3,
    header4,
    header5,
    header6,
    themanticBreak,
    indentedCodeBlock,
    fencedCodeBlock,
    blockQuote,
    unOrderedList,
    orderedList

  InlineType = enum
    undefinedInline,
    hr,
    lineBreak,
    softBreak,
    link,
    em,
    strong,
    code,
    image,
    text

  ToggleContainer = ref object
    toggleBlockQuote: bool
    toggleIndentedCodeBlock: bool
    indentedCodeBlockDepth: int
    toggleFencedCodeBlock: bool
    toggleUnorderedListDashSpace: bool
    toggleUnorderedListPlusSpace: bool
    toggleUnorderedListAsteSpace: bool
    toggleUnorderedListDashPare: bool
    toggleUnorderedListPlusPare: bool
    toggleUnorderedListAstePare: bool
    toggleOrderedListSpace: bool
    toggleOrderedListPare: bool

proc newToggle(): ToggleContainer =
  ToggleContainer(
    toggleBlockQuote: false,
    toggleIndentedCodeBlock: false,
    indentedCodeBlockDepth: 0,
    toggleFencedCodeBlock: false,
    toggleUnorderedListDashSpace: false,
    toggleUnorderedListPlusSpace: false,
    toggleUnorderedListAsteSpace: false,
    toggleUnorderedListDashPare: false,
    toggleUnorderedListPlusPare: false,
    toggleUnorderedListAstePare: false,
    toggleOrderedListSpace: false,
    toggleOrderedListPare: false
  )

type
  BlockKind = enum
    containerBlock,
    leafBlock
  Block = ref BlockObj
  BlockObj = object
    case kind: BlockKind
    of containerBlock:
      containerType: BlockType
      children: Block
    of leafBlock:
      leafType: BlockType
      inline: Inline
  Inline = ref object
    kind: InlineType
    value: string

  Root = ref object
    kind: string
    children: seq[Block]

let
  reThematicBreak = re"^(| |  |   )(\*{3,}|-{3,}|_{3,})"
  reSetextHeader1 = re"^(| |  |   )(=+)"
  reSetextHeader2 = re"^(| |  |   )(--+)"
  reAtxHeader = re"^(| |  |   )(#|##|###|####|#####|######) "
  reBlockQuote = re"^(| |  |   )>( |)"
  reUnorderedListDashSpace = re"^(| |  |   )- "
  reUnorderedListPlusSpace = re"^(| |  |   )\+ "
  reUnorderedListAsteSpace = re"^(| |  |   )\* "
  reUnorderedListDashPare = re"^(| |  |   )-\)"
  reUnorderedListPlusPare = re"^(| |  |   )\+\)"
  reUnorderedListAstePare = re"^(| |  |   )\*\)"
  reOrderedListSpaceStart = re"^(| |  |   )1\. "
  reOrderedListPareStart = re"^(| |  |   )1\)"
  reOrderedListSpace = re"^(| |  |   )(2|3|4|5|6|7|8|9)\. "
  reOrderedListPare = re"^(| |  |   )(2|3|4|5|6|7|8|9)\)"
  reIndentedCodeBlock = re"^ {4,}\S"
  reBreakIndentedCode = re"^(| |  |   )\S"
  reFencedCodeBlock = re"^(| |  |   )(```|~~~)"
  reParagraph = re"^(| |  |   )[^\*-_=+#>123456789(```)(~~~)]"

proc isSetextHeader1(line: string): bool =
  match(line, reSetextHeader1)

proc isSetextHeader2(line: string): bool =
  match(line, reSetextHeader2)

proc isThemanticBreak(line: string): bool =
  match(line, reThematicBreak)

proc isAtxHeader(line: string): bool =
  match(line, reAtxHeader)

proc isBlockQuote(line: string): bool =
  match(line, reBlockQuote)

proc isIndentedCode(line: string): bool =
  match(line, reIndentedCodeBlock)

proc isBreakIndentedCode(line: string): bool =
  match(line, reBreakIndentedCode)

proc isCodeFence(line: string): bool =
  match(line, reFencedCodeBlock)

proc isParagraph(line: string): bool =
  match(line, reParagraph)

proc isUnorderedListDashSpace(line: string): bool =
  match(line, reUnorderedListDashSpace)
proc isUnorderedListPlusSpace(line: string): bool =
  match(line, reUnorderedListPlusSpace)
proc isUnorderedListAsteSpace(line: string): bool =
  match(line, reUnorderedListAsteSpace)
proc isUnorderedListDashPare(line: string): bool =
  match(line, reUnorderedListDashPare)
proc isUnorderedListPlusPare(line: string): bool =
  match(line, reUnorderedListDashPare)
proc isUnorderedListAstePare(line: string): bool =
  match(line, reUnorderedListDashPare)
proc isOrderedListSpaceStart(line: string): bool =
  match(line, reOrderedListSpaceStart)
proc isOrderedListPareStart(line: string): bool =
  match(line, reOrderedListPareStart)
proc isOrderedListSpace(line: string): bool =
  match(line, reOrderedListSpace)
proc isOrderedListPare(line: string): bool =
  match(line, reOrderedListPare)

proc countWhitespace(line: string): int =
  var i = 0
  for c in line:
    if c == ' ': i.inc
    else: return i

proc openAtxHeader(line: string): Block =
  case line.splitWhitespace[0]:
    of "#":
      let str = line.replace(reAtxHeader)
      return Block(kind: leafBlock, leafType: header1, inline: Inline(kind: text, value: str))
    of "##":
      let str = line.replace(reAtxHeader)
      return Block(kind: leafBlock, leafType: header2, inline: Inline(kind: text, value: str))
    of "###":
      let str = line.replace(reAtxHeader)
      return Block(kind: leafBlock, leafType: header3, inline: Inline(kind: text, value: str))
    of "####":
      let str = line.replace(reAtxHeader)
      return Block(kind: leafBlock, leafType: header4, inline: Inline(kind: text, value: str))
    of "#####":
      let str = line.replace(reAtxHeader)
      return Block(kind: leafBlock, leafType: header5, inline: Inline(kind: text, value: str))
    of "######":
      let str = line.replace(reAtxHeader)
      return Block(kind: leafBlock, leafType: header6, inline: Inline(kind: text, value: str))

proc openContainerBlock(blockType: BlockType, containerBLockSeq: seq[string]): Block =
  return Block(kind: containerBlock, containerType: blockType, children: nil)  

proc openCodeBlock(blockType: BlockType, codeLines: string): Block =
  return Block(kind: leafBlock, leafType: blockType, inline: Inline(kind: text, value: codeLines))  

proc openSetextHeader(blockType: BlockType, lineBlock: string): Block =
  return Block(kind: leafBlock, leafType: blockType, inline: Inline(kind: text, value: lineBlock))

proc openThemanticBreak(): Block =
  return Block(kind: leafBlock, leafType: themanticBreak, inline: nil) 

proc openParagraph(line: string): Block =
  Block(kind: leafBlock, leafType: paragraph, inline: Inline(kind: text, value: line))

var mdast: seq[Block]
var lineBlock: string
var blockQuoteSeq: seq[string]
var unorderedListSeq: seq[string]
var orderedListSeq: seq[string]
var container = newToggle()

proc parseLine(line: string) =

    block unorderedListDashSpaceBlock:
      if container.toggleUnorderedListDashSpace:
        if line.isUnorderedListDashSpace:
          unorderedListSeq.add(line.replace(reUnorderedListDashSpace))
        else:
          mdast.add(openContainerBlock(unOrderedList, unorderedListSeq))
          unorderedListSeq = @[]
          container.toggleUnorderedListDashSpace = false
          break unorderedListDashSpaceBlock

    block orderedListDashSpaceBlock:
      if container.toggleOrderedListSpace:
        if line.isOrderedListSpace:
          orderedListSeq.add(line.replace(reOrderedListSpace))
        else:
          mdast.add(openContainerBlock(orderedList, orderedListSeq))
          orderedListSeq = @[]
          container.toggleOrderedListSpace = false
          break orderedListDashSpaceBlock

    block indentedCodeBlocks:
      if container.toggleIndentedCodeBlock:
        if line.isBreakIndentedCode:
          lineBlock.removeSuffix("\n")
          mdast.add(openCodeBlock(indentedCodeBlock, lineBlock))
          lineBlock = ""
          container.toggleIndentedCodeBlock = false
          break indentedCodeBlocks
        else:
          var mutLine = line
          mutLine.delete(0,container.indentedCodeBlockDepth)
          lineBlock.add("\n" & mutLine)
          return

    if container.toggleFencedCodeBlock:
      if not line.isCodeFence:
        lineBlock.add(line & "\n")
      else:
        lineBlock.removeSuffix("\n")
        mdast.add(openCodeBlock(fencedCodeBlock, lineBlock))
        lineblock = ""
        container.toggleFencedCodeBlock = false

    elif line.isBlockQuote:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      blockQuoteSeq.add(line.replace(reBlockQuote))
      container.toggleBlockQuote = true
    
    elif line.isUnorderedListDashSpace:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      unorderedListSeq.add(line.replace(reUnorderedListDashSpace))
      container.toggleUnorderedListDashSpace = true

    elif line.isUnorderedListPlusSpace:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      unorderedListSeq.add(line.replace(reUnorderedListPlusSpace))
      container.toggleUnorderedListPlusSpace = true

    elif line.isUnorderedListAsteSpace:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      unorderedListSeq.add(line.replace(reUnorderedListAsteSpace))
      container.toggleUnorderedListAsteSpace = true
    
    elif line.isUnorderedListDashPare:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      unorderedListSeq.add(line.replace(reUnorderedListDashPare))
      container.toggleUnorderedListDashPare = true

    elif line.isUnorderedListPlusPare:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      unorderedListSeq.add(line.replace(reUnorderedListPlusPare))
      container.toggleUnorderedListPlusPare = true

    elif line.isUnorderedListAstePare:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      unorderedListSeq.add(line.replace(reUnorderedListAstePare))
      container.toggleUnorderedListAstePare = true
    
    elif line.isOrderedListSpaceStart:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      orderedListSeq.add(line.replace(reOrderedListSpaceStart))
      container.toggleOrderedListSpace = true

    elif line.isOrderedListPareStart:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      orderedListSeq.add(line.replace(reOrderedListPareStart))
      container.toggleOrderedListPare = true

    elif line.isIndentedCode:
      if lineBlock == "":
        container.indentedCodeBlockDepth = line.countWhitespace - 1
        container.toggleIndentedCodeBlock = true
        var mutLine = line
        mutLine.delete(0,container.indentedCodeBlockDepth)
        lineBlock.add(mutLine)

    elif line.isCodeFence:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      container.toggleFencedCodeBlock = true
    
    elif line.isAtxHeader:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
      mdast.add(openAtxHeader(line))
      lineBlock = ""
    
    elif line.isSetextHeader1:
      if lineBlock != "":
        mdast.add(openSetextHeader(header1, lineBlock))
        lineBlock = ""
      else:
        lineBlock.add(line)
    
    elif line.isSetextHeader2:
      if lineBlock != "":
        mdast.add(openSetextHeader(header2, lineBlock))
        lineBlock = ""
      else:
        mdast.add(openThemanticBreak())
    
    elif line.isThemanticBreak:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      mdast.add(openThemanticBreak())

    elif line.isEmptyOrWhitespace:
      if not lineBlock.isEmptyOrWhitespace:
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""

    else:
      lineBlock.add(line)

when isMainModule:
  var s = readFile("testfiles/1.md")
  var root = Root(kind: "root", children: @[])
  for line in s.splitLines:
    line.parseLine
  if lineBlock != "":
    mdast.add(openParagraph(lineBlock))
  root.children = mdast
  echo pretty(%root)