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

  FlagContainer = ref object
    flagBlockQuote: bool
    flagIndentedCodeBlock: bool
    indentedCodeBlockDepth: int
    flagFencedCodeBlock: bool
    flagUnorderedListDashSpace: bool
    flagUnorderedListPlusSpace: bool
    flagUnorderedListAsteSpace: bool
    flagUnorderedListDashPare: bool
    flagUnorderedListPlusPare: bool
    flagUnorderedListAstePare: bool
    flagOrderedListSpace: bool
    flagOrderedListPare: bool

proc newFlag(): FlagContainer =
  FlagContainer(
    flagBlockQuote: false,
    flagIndentedCodeBlock: false,
    indentedCodeBlockDepth: 0,
    flagFencedCodeBlock: false,
    flagUnorderedListDashSpace: false,
    flagUnorderedListPlusSpace: false,
    flagUnorderedListAsteSpace: false,
    flagUnorderedListDashPare: false,
    flagUnorderedListPlusPare: false,
    flagUnorderedListAstePare: false,
    flagOrderedListSpace: false,
    flagOrderedListPare: false
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
var flag = newFlag()

proc parseLine(line: string) =

    block unorderedListDashSpaceBlock:
      if flag.flagUnorderedListDashSpace:
        if line.isUnorderedListDashSpace:
          unorderedListSeq.add(line.replace(reUnorderedListDashSpace))
        else:
          mdast.add(openContainerBlock(unOrderedList, unorderedListSeq))
          unorderedListSeq = @[]
          flag.flagUnorderedListDashSpace = false
          break unorderedListDashSpaceBlock

    block orderedListDashSpaceBlock:
      if flag.flagOrderedListSpace:
        if line.isOrderedListSpace:
          orderedListSeq.add(line.replace(reOrderedListSpace))
        else:
          mdast.add(openContainerBlock(orderedList, orderedListSeq))
          orderedListSeq = @[]
          flag.flagOrderedListSpace = false
          break orderedListDashSpaceBlock

    block indentedCodeBlocks:
      if flag.flagIndentedCodeBlock:
        if line.isBreakIndentedCode:
          lineBlock.removeSuffix("\n")
          mdast.add(openCodeBlock(indentedCodeBlock, lineBlock))
          lineBlock = ""
          flag.flagIndentedCodeBlock = false
          break indentedCodeBlocks
        else:
          var mutLine = line
          mutLine.delete(0,flag.indentedCodeBlockDepth)
          lineBlock.add("\n" & mutLine)
          return

    if flag.flagFencedCodeBlock:
      if not line.isCodeFence:
        lineBlock.add(line & "\n")
      else:
        lineBlock.removeSuffix("\n")
        mdast.add(openCodeBlock(fencedCodeBlock, lineBlock))
        lineblock = ""
        flag.flagFencedCodeBlock = false

    elif line.isBlockQuote:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      blockQuoteSeq.add(line.replace(reBlockQuote))
      flag.flagBlockQuote = true
    
    elif line.isUnorderedListDashSpace:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      unorderedListSeq.add(line.replace(reUnorderedListDashSpace))
      flag.flagUnorderedListDashSpace = true

    elif line.isUnorderedListPlusSpace:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      unorderedListSeq.add(line.replace(reUnorderedListPlusSpace))
      flag.flagUnorderedListPlusSpace = true

    elif line.isUnorderedListAsteSpace:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      unorderedListSeq.add(line.replace(reUnorderedListAsteSpace))
      flag.flagUnorderedListAsteSpace = true
    
    elif line.isUnorderedListDashPare:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      unorderedListSeq.add(line.replace(reUnorderedListDashPare))
      flag.flagUnorderedListDashPare = true

    elif line.isUnorderedListPlusPare:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      unorderedListSeq.add(line.replace(reUnorderedListPlusPare))
      flag.flagUnorderedListPlusPare = true

    elif line.isUnorderedListAstePare:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      unorderedListSeq.add(line.replace(reUnorderedListAstePare))
      flag.flagUnorderedListAstePare = true
    
    elif line.isOrderedListSpaceStart:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      orderedListSeq.add(line.replace(reOrderedListSpaceStart))
      flag.flagOrderedListSpace = true

    elif line.isOrderedListPareStart:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      orderedListSeq.add(line.replace(reOrderedListPareStart))
      flag.flagOrderedListPare = true

    elif line.isIndentedCode:
      if lineBlock == "":
        flag.indentedCodeBlockDepth = line.countWhitespace - 1
        flag.flagIndentedCodeBlock = true
        var mutLine = line
        mutLine.delete(0,flag.indentedCodeBlockDepth)
        lineBlock.add(mutLine)

    elif line.isCodeFence:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      flag.flagFencedCodeBlock = true
    
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