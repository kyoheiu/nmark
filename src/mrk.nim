import strutils, sequtils, json, re
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
    flagBlockQuoteMarker: bool
    flagIndentedCodeBlock: bool
    indentedCodeBlockDepth: int
    flagFencedCodeBlock: bool
    flagUnorderedListDash: bool
    flagUnorderedListPlus: bool
    flagUnorderedListAste: bool
    flagOrderedListSpace: bool
    flagOrderedListPare: bool

proc newFlag(): FlagContainer =
  FlagContainer(
    flagBlockQuote: false,
    flagBlockQuoteMarker: false,
    flagIndentedCodeBlock: false,
    indentedCodeBlockDepth: 0,
    flagFencedCodeBlock: false,
    flagUnorderedListDash: false,
    flagUnorderedListPlus: false,
    flagUnorderedListAste: false,
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
      children: seq[Block]
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
  reBreakBlockQuote = re""
  reUnorderedListDash = re"^(| |  |   )- "
  reUnorderedListPlus = re"^(| |  |   )\+ "
  reUnorderedListAste = re"^(| |  |   )\* "
  reOrderedListSpaceStart = re"^(| |  |   )1\. "
  reOrderedListPareStart = re"^(| |  |   )1\)"
  reOrderedListSpace = re"^(| |  |   )(2|3|4|5|6|7|8|9)\. "
  reOrderedListPare = re"^(| |  |   )(2|3|4|5|6|7|8|9)\)"
  reIndentedCodeBlock = re"^ {4,}\S"
  reBreakIndentedCode = re"^(| |  |   )\S"
  reFencedCodeBlock = re"^(| |  |   )(```|~~~)"
  #reParagraph = re"^(| |  |   )[^(\* )(\*\))(\+ )(\+\))(- )(-\))_=+(# )(## )(### )(#### )(##### )(###### )>((1|2|3|4|5|6|7|8|9|)\.)((1|2|3|4|5|6|7|8|9|)\))(```)(~~~)]"

proc hasMarker(line: string, regex: Regex): bool =
  match(line, regex)

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
  return Block(kind: containerBlock, containerType: blockType, children: @[])

proc openQuoteBlock(mdast: seq[Block]): Block =
  return Block(kind: containerBlock, containerType: blockQuote, children: mdast)

proc openCodeBlock(blockType: BlockType, codeLines: string): Block =
  return Block(kind: leafBlock, leafType: blockType, inline: Inline(kind: text, value: codeLines))  

proc openSetextHeader(blockType: BlockType, lineBlock: string): Block =
  return Block(kind: leafBlock, leafType: blockType, inline: Inline(kind: text, value: lineBlock))

proc openThemanticBreak(): Block =
  return Block(kind: leafBlock, leafType: themanticBreak, inline: nil) 

proc openParagraph(line: string): Block =
  Block(kind: leafBlock, leafType: paragraph, inline: Inline(kind: text, value: line))

var blockChildren: seq[Block]
var mdast: seq[Block]
var lineBlock: string
var blockQuoteSeq: seq[string]
var unorderedListSeq: seq[string]
var orderedListSeq: seq[string]
var flag = newFlag()

proc parseLine(mdast: var seq[Block], line: var string) =

  flag.flagBlockQuoteMarker = false

  block unorderedListDashBlock:
    if flag.flagUnorderedListDash:
      if line.hasMarker(reUnorderedListDash):
        unorderedListSeq.add(line.replace(reUnorderedListDash))
      else:
        mdast.add(openContainerBlock(unOrderedList, unorderedListSeq))
        unorderedListSeq = @[]
        flag.flagUnorderedListDash = false
        break unorderedListDashBlock

  block orderedListDashSpaceBlock:
    if flag.flagOrderedListSpace:
      if line.hasMarker(reOrderedListSpaceStart):
        orderedListSeq.add(line.replace(reOrderedListSpace))
      else:
        mdast.add(openContainerBlock(orderedList, orderedListSeq))
        orderedListSeq = @[]
        flag.flagOrderedListSpace = false
        break orderedListDashSpaceBlock

  block indentedCodeBlocks:
    if flag.flagIndentedCodeBlock:
      if line.hasMarker(reBreakIndentedCode):
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

  block blockQuoteBlock:
    if flag.flagBlockQuote:
      if line.hasMarker(reBlockQuote):
        line = line.replace(reBlockQuote)
        flag.flagBlockQuoteMarker = true
      break blockQuoteBlock
    if line.hasMarker(reBlockQuote):
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      blockChildren = concat(blockChildren, mdast)
      mdast = @[]
      line = line.replace(reBlockQuote)
      flag.flagBlockQuote = true
      flag.flagBlockQuoteMarker = true
      break blockQuoteBlock
        
  if flag.flagFencedCodeBlock:
    if not line.hasMarker(reFencedCodeBlock):
      lineBlock.add(line & "\n")
    else:
      lineBlock.removeSuffix("\n")
      mdast.add(openCodeBlock(fencedCodeBlock, lineBlock))
      lineblock = ""
      flag.flagFencedCodeBlock = false

  elif line.hasMarker(reUnorderedListDash):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
      lineBlock = ""
    unorderedListSeq.add(line.replace(reUnorderedListDash))
    flag.flagUnorderedListDash = true

  #elif line.isUnorderedListPlus:
    #if lineBlock != "":
      #mdast.add(openParagraph(lineBlock))
      #lineBlock = ""
    #unorderedListSeq.add(line.replace(reUnorderedListPlus))
    #flag.flagUnorderedListPlus = true

  #elif line.isUnorderedListAste:
    #if lineBlock != "":
      #mdast.add(openParagraph(lineBlock))
      #lineBlock = ""
    #unorderedListSeq.add(line.replace(reUnorderedListAste))
    #flag.flagUnorderedListAste = true
  
  elif line.hasMarker(reOrderedListSpaceStart):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
      lineBlock = ""
    orderedListSeq.add(line.replace(reOrderedListSpaceStart))
    flag.flagOrderedListSpace = true

  elif line.hasMarker(reOrderedListPareStart):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
      lineBlock = ""
    orderedListSeq.add(line.replace(reOrderedListPareStart))
    flag.flagOrderedListPare = true

  elif line.hasMarker(reIndentedCodeBlock):
    if lineBlock == "":
      flag.indentedCodeBlockDepth = line.countWhitespace - 1
      flag.flagIndentedCodeBlock = true
      var mutLine = line
      mutLine.delete(0,flag.indentedCodeBlockDepth)
      lineBlock.add(mutLine)

  elif line.hasMarker(reFencedCodeBlock):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
      lineBlock = ""
    flag.flagFencedCodeBlock = true
  
  elif line.hasMarker(reAtxHeader):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
    mdast.add(openAtxHeader(line))
    lineBlock = ""
  
  elif line.hasMarker(reSetextHeader1):
    if lineBlock == "":
      lineBlock.add(line)
    else:
      mdast.add(openSetextHeader(header1, lineBlock))
      lineBlock = ""
  
  elif line.hasMarker(reSetextHeader2):
    if lineBlock != "":
      mdast.add(openSetextHeader(header2, lineBlock))
      lineBlock = ""
    else:
      mdast.add(openThemanticBreak())
  
  elif line.hasMarker(reThematicBreak):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
      lineBlock = ""
    mdast.add(openThemanticBreak())

  elif line.isEmptyOrWhitespace:
    if flag.flagBlockQuote:
      if flag.flagBlockQuoteMarker:
        return
      else:
        if lineBlock != "":
          mdast.add(openParagraph(lineBlock))
        blockChildren.add(openQuoteBlock(mdast))
        lineBlock = ""
        mdast = @[]
        flag.flagBlockQuote = false
    if not lineBlock.isEmptyOrWhitespace:
      mdast.add(openParagraph(lineBlock))
      lineBlock = ""

  else:
    if lineBlock != "":
      line = "\n" & line
    lineBlock.add(line)

when isMainModule:
  var s = readFile("testfiles/1.md")
  var root = Root(kind: "root", children: @[])
  for line in s.splitLines:
    var str = line
    parseLine(mdast, str)
  if lineBlock != "":
    mdast.add(openParagraph(lineBlock))
    blockChildren = concat(blockChildren, mdast)
  root.children = blockChildren
  echo pretty(%root)