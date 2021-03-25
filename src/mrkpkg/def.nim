import strutils, json
import re

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
    htmlBlock,
    linkReference,
    blockQuote,
    unOrderedTightList,
    unOrderedLooseList,
    orderedTightList,
    orderedLooseList,
    list,

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
    li,
    text

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
      inline*: string

  FlagContainer* = ref FlagObj
  FlagObj = object
    flagBlockQuote*: bool
    flagBlockQuoteMarker*: bool
    flagIndentedCodeBlock*: bool
    indentedCodeBlockDepth*: int
    flagFencedCodeBlockChar*: bool
    flagFencedCodeBlockTild*: bool
    openingFenceLength*: int
    fencedCodeBlocksdepth*: int
    flagHtmlBlock1*: bool
    flagHtmlBlock2*: bool
    flagHtmlBlock3*: bool
    flagHtmlBlock4*: bool
    flagHtmlBlock5*: bool
    flagHtmlBlock6*: bool
    flagHtmlBlock7*: bool
    flagLinkReference*: bool
    flagUnorderedList*: bool
    flagUnorderedListMarker*: bool
    uldepth*: int
    flagOrderedList*: bool
    flagOrderedListMarker*: bool
    oldepth*: int
    hasEmptyLine*: bool
    afterEmptyLine*: bool
    looseUnordered*: bool
    looseOrdered*: bool

proc newFlag*(): FlagContainer =
  FlagContainer(
    flagBlockQuote: false,
    flagBlockQuoteMarker: false,
    flagIndentedCodeBlock: false,
    indentedCodeBlockDepth: 0,
    flagFencedCodeBlockChar: false,
    flagFencedCodeBlockTild: false,
    flagHtmlBlock1: false,
    flagHtmlBlock2: false,
    flagHtmlBlock3: false,
    flagHtmlBlock4: false,
    flagHtmlBlock5: false,
    flagHtmlBlock6: false,
    flagHtmlBlock7: false,
    flagLinkReference: false,
    flagUnorderedList: false,
    flagUnorderedListMarker: false,
    uldepth: 0,
    flagOrderedList: false,
    flagOrderedListMarker: false,
    oldepth: 0,
    hasEmptyLine: false,
    afterEmptyLine: false,
    looseUnordered: false,
    looseOrdered: false
  )

let
  reThematicBreak* = re"^(| |  |   )(\*{3,}|-{3,}|_{3,})$"
  reSetextHeader1* = re"^(| |  |   )(=+)$"
  reBreakOrHeader* = re"^(| |  |   )(-{3,}) *$"
  reAtxHeader* = re"^(| |  |   )(#|##|###|####|#####|######) "
  reAnotherAtxHeader* = re"^(#|##|###|####|#####|######)$"
  reBlockQuote* = re"^(| |  |   )>( |)"
  reUnorderedList* = re"^(| |  |   )(-|\+|\*) +"
  reOrderedList* = re"^(| |  |   )[0-9]{1,9}(\.|\)) +"
  reIndentedCodeBlock* = re"^ {4,}\S"
  reBreakIndentedCode* = re"^(| |  |   )\S"
  reFencedCodeBlockChar* = re"^(| |  |   )(```*) *$"
  reFencedCodeBlockTild* = re"^(| |  |   )(~~~*) *$"

  reHtmlBlock1Begins* = re"(^(<script|<pre|<style)( |>|\n))"
  reHtmlBlock1Ends*   = re"(</script>|</pre>|</style>)"
  reHtmlBlock2Begins* = re"^<!--"
  reHtmlBlock2Ends*   = re"-->"
  reHtmlBlock3Begins* = re"^<\?"
  reHtmlBlock3Ends*   = re"\?>"
  reHtmlBlock4Begins* = re"^<![A-Z]"
  reHtmlBlock4Ends*   = re">"
  reHtmlBlock5Begins* = re"^<!\[CDATA\["
  reHtmlBlock5Ends*   = re"\]\]>"
  reHtmlBlock6Begins* = re"^(<|</)(address|article|aside|base|basefont|blockquote|body|caption|center|col|colgroup|dd|details|dialog|dir|div|dl|dt|fieldset|figcaption|figure|footer|form|frame|frameset|h1|h2|h3|h4|h5|h6|head|header|hr|html|iframe|legend|li|link|main|menu|menuitem|nav|noframes|ol|optgroup|option|p|param|section|source|summary|table|tbody|td|tfoot|th|thead|title|tr|track|ul)( |\n|>|/>)"
  reHtmlBlock7Begins* = re"^<.*>"
  reSoftBreak* = re" {2,}\n"

  reLinkLabel* = re"^\[\S+\]:"
  #reLinkReference = re(^\[\S+\]:( *\n? *)(\S+)( |\n)+(".*")|('.*')|()\s*$)

proc hasMarker*(line: string, regex: Regex): bool =
  match(line, regex)

proc delWhitespace*(line: string): string =
  var str: string
  for c in line:
    if c != ' ': str.add(c)
  return str

proc countWhitespace*(line: string): int =
  var i = 0
  for c in line:
    if c == ' ': i.inc
    else: return i

proc countBacktick*(line: string): int =
  line.strip.len

proc openAtxHeader*(line: string): Block =
  case line.splitWhitespace[0]:
    of "#":
      let str = line.strip(chars = {' ', '#'})
      return Block(kind: leafBlock, leafType: header1, inline: str)
    of "##":
      let str = line.strip(chars = {' ', '#'})
      return Block(kind: leafBlock, leafType: header2, inline: str)
    of "###":
      let str = line.strip(chars = {' ', '#'})
      return Block(kind: leafBlock, leafType: header3, inline: str)
    of "####":
      let str = line.strip(chars = {' ', '#'})
      return Block(kind: leafBlock, leafType: header4, inline: str)
    of "#####":
      let str = line.strip(chars = {' ', '#'})
      return Block(kind: leafBlock, leafType: header5, inline: str)
    of "######":
      let str = line.strip(chars = {' ', '#'})
      return Block(kind: leafBlock, leafType: header6, inline: str)

proc openAnotherAtxHeader*(line: string): Block =
  case line
    of "#":
      return Block(kind: leafBlock, leafType: header1, inline: "")
    of "##":
      return Block(kind: leafBlock, leafType: header2, inline: "")
    of "###":
      return Block(kind: leafBlock, leafType: header3, inline: "")
    of "####":
      return Block(kind: leafBlock, leafType: header4, inline: "")
    of "#####":
      return Block(kind: leafBlock, leafType: header5, inline: "")
    of "######":
      return Block(kind: leafBlock, leafType: header6, inline: "")

proc openContainerBlock*(blockType: BlockType, mdast: seq[Block]): Block =
  return Block(kind: containerBlock, containerType: blockType, children: mdast)

proc openCodeBlock*(blockType: BlockType, codeLines: string): Block =
  return Block(kind: leafBlock, leafType: blockType, inline: codeLines)

proc openSetextHeader*(blockType: BlockType, lineBlock: string): Block =
  return Block(kind: leafBlock, leafType: blockType, inline: lineBlock)

proc openThemanticBreak*(): Block =
  return Block(kind: leafBlock, leafType: themanticBreak, inline: "")

proc openHtmlBlock*(lineBlock: string): Block =
  return Block(kind: leafBlock, leaftype: htmlblock, inline: lineBlock) 

proc openLinkReference*(lineBlock: string): Block =
  return Block(kind: leafBlock, leaftype: linkReference, inline: lineBlock)

proc openBlockQuote*(mdast: seq[Block]): Block =
  Block(kind: containerBlock, containerType: blockQuote, children: mdast)

proc openList*(mdast: seq[Block]): Block =
  Block(kind: containerBlock, containerType: list, children: mdast)

proc openLooseUL*(mdast: seq[Block]): Block =
  Block(kind: containerBlock, containerType: unOrderedLooseList, children: mdast)

proc openTightUL*(mdast: seq[Block]): Block =
  Block(kind: containerBlock, containerType: unOrderedTightList, children: mdast)

proc openLooseOL*(mdast: seq[Block]): Block =
  Block(kind: containerBlock, containerType: orderedLooseList, children: mdast)

proc openTightOL*(mdast: seq[Block]): Block =
  Block(kind: containerBlock, containerType: orderedTightList, children: mdast)

proc openParagraph*(lineBlock: string): Block =
  Block(kind: leafBlock, leafType: paragraph, inline: lineBlock)

proc echoSeqBlock*(mdast: seq[Block]) =
  var s: seq[JsonNode]
  for b in mdast:
    s.add(%b)
  echo s