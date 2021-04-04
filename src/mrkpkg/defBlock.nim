import strutils, re

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
      raw*: string
  
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
  reThematicBreak* = re"^ {0,3}(\*{3,}|-{3,}|_{3,})$"
  reSetextHeader1* = re"^ {0,3}(=+)$"
  reBreakOrHeader* = re"^ {0,3}(-{3,}) *$"
  reAtxHeader* = re"^ {0,3}(#|##|###|####|#####|######) "
  reAnotherAtxHeader* = re"^(#|##|###|####|#####|######)$"
  reBlockQuote* = re"^ {0,3}> {0,1}"
  reUnorderedList* = re"^( {0,3}(-|\+|\*) +)"
  reOrderedList* = re"^( {0,3}[0-9]{1,9}(\.|\)) +)"
  reIndentedCodeBlock* = re"^ {4,}\S"
  reBreakIndentedCode* = re"^ {0,3}\S"
  reFencedCodeBlockChar* = re"^ {0,3}(```*) *$"
  reFencedCodeBlockTild* = re"^ {0,3}(~~~*) *$"

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
  reHtmlBlock7Begins* = re"^<.*> *$"

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
      return Block(kind: leafBlock, leafType: header1, raw: str)
    of "##":
      let str = line.strip(chars = {' ', '#'})
      return Block(kind: leafBlock, leafType: header2, raw: str)
    of "###":
      let str = line.strip(chars = {' ', '#'})
      return Block(kind: leafBlock, leafType: header3, raw: str)
    of "####":
      let str = line.strip(chars = {' ', '#'})
      return Block(kind: leafBlock, leafType: header4, raw: str)
    of "#####":
      let str = line.strip(chars = {' ', '#'})
      return Block(kind: leafBlock, leafType: header5, raw: str)
    of "######":
      let str = line.strip(chars = {' ', '#'})
      return Block(kind: leafBlock, leafType: header6, raw: str)

proc openAnotherAtxHeader*(line: string): Block =
  case line
    of "#":
      return Block(kind: leafBlock, leafType: header1, raw: "")
    of "##":
      return Block(kind: leafBlock, leafType: header2, raw: "")
    of "###":
      return Block(kind: leafBlock, leafType: header3, raw: "")
    of "####":
      return Block(kind: leafBlock, leafType: header4, raw: "")
    of "#####":
      return Block(kind: leafBlock, leafType: header5, raw: "")
    of "######":
      return Block(kind: leafBlock, leafType: header6, raw: "")

proc openContainerBlock*(blockType: BlockType, mdast: seq[Block]): Block =
  return Block(kind: containerBlock, containerType: blockType, children: mdast)

proc openCodeBlock*(blockType: BlockType, codeLines: string): Block =
  return Block(kind: leafBlock, leafType: blockType, raw: codeLines)

proc openSetextHeader*(blockType: BlockType, lineBlock: string): Block =
  return Block(kind: leafBlock, leafType: blockType, raw: lineBlock)

proc openThemanticBreak*(): Block =
  return Block(kind: leafBlock, leafType: themanticBreak, raw: "")

proc openHtmlBlock*(lineBlock: string): Block =
  return Block(kind: leafBlock, leaftype: htmlblock, raw: lineBlock) 

proc openLinkReference*(lineBlock: string): Block =
  return Block(kind: leafBlock, leaftype: linkReference, raw: lineBlock)

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
  Block(kind: leafBlock, leafType: paragraph, raw: lineBlock)