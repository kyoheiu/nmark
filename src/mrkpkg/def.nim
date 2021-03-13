import re, strutils

type
  BlockType* = enum
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

  InlineType* = enum
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

  FlagContainer* = ref object
    flagBlockQuote*: bool
    flagBlockQuoteMarker*: bool
    flagIndentedCodeBlock*: bool
    indentedCodeBlockDepth*: int
    flagFencedCodeBlock*: bool
    flagUnorderedListDash*: bool
    flagUnorderedListPlus*: bool
    flagUnorderedListAste*: bool
    flagOrderedListSpace*: bool
    flagOrderedListPare*: bool

proc newFlag*(): FlagContainer =
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
  BlockKind* = enum
    containerBlock,
    leafBlock
  Block* = ref BlockObj
  BlockObj = object
    case kind*: BlockKind
    of containerBlock:
      containerType*: BlockType
      children*: seq[Block]
    of leafBlock:
      leafType*: BlockType
      inline*: Inline
  Inline* = ref object
    kind*: InlineType
    value*: string

let
  reThematicBreak* = re"^(| |  |   )(\*{3,}|-{3,}|_{3,})"
  reSetextHeader1* = re"^(| |  |   )(=+)"
  reSetextHeader2* = re"^(| |  |   )(--+)"
  reAtxHeader* = re"^(| |  |   )(#|##|###|####|#####|######) "
  reBlockQuote* = re"^(| |  |   )>( |)"
  reBreakBlockQuote* = re""
  reUnorderedListDash* = re"^(| |  |   )- "
  reUnorderedListPlus* = re"^(| |  |   )\+ "
  reUnorderedListAste* = re"^(| |  |   )\* "
  reOrderedListSpaceStart* = re"^(| |  |   )1\. "
  reOrderedListPareStart* = re"^(| |  |   )1\)"
  reOrderedListSpace* = re"^(| |  |   )(2|3|4|5|6|7|8|9)\. "
  reOrderedListPare* = re"^(| |  |   )(2|3|4|5|6|7|8|9)\)"
  reIndentedCodeBlock* = re"^ {4,}\S"
  reBreakIndentedCode* = re"^(| |  |   )\S"
  reFencedCodeBlock* = re"^(| |  |   )(```|~~~)"
  #reParagraph = re"^(| |  |   )[^(\* )(\*\))(\+ )(\+\))(- )(-\))_=+(# )(## )(### )(#### )(##### )(###### )>((1|2|3|4|5|6|7|8|9|)\.)((1|2|3|4|5|6|7|8|9|)\))(```)(~~~)]"

proc hasMarker*(line: string, regex: Regex): bool =
  match(line, regex)

proc countWhitespace*(line: string): int =
  var i = 0
  for c in line:
    if c == ' ': i.inc
    else: return i

proc openAtxHeader*(line: string): Block =
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

proc openContainerBlock*(blockType: BlockType, containerBLockSeq: seq[string]): Block =
  return Block(kind: containerBlock, containerType: blockType, children: @[])

proc openQuoteBlock*(mdast: seq[Block]): Block =
  return Block(kind: containerBlock, containerType: blockQuote, children: mdast)

proc openCodeBlock*(blockType: BlockType, codeLines: string): Block =
  return Block(kind: leafBlock, leafType: blockType, inline: Inline(kind: text, value: codeLines))  

proc openSetextHeader*(blockType: BlockType, lineBlock: string): Block =
  return Block(kind: leafBlock, leafType: blockType, inline: Inline(kind: text, value: lineBlock))

proc openThemanticBreak*(): Block =
  return Block(kind: leafBlock, leafType: themanticBreak, inline: nil) 

proc openParagraph*(line: string): Block =
  Block(kind: leafBlock, leafType: paragraph, inline: Inline(kind: text, value: line))
