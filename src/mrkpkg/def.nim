import strutils
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
  reThematicBreak* = re"^(| |  |   )(\*{3,}|-{3,}|_{3,})$"
  reSetextHeader1* = re"^(| |  |   )(=+)$"
  reBreakOrHeader* = re"^(| |  |   )(-{3,}) *$"
  reAtxHeader* = re"^(| |  |   )(#|##|###|####|#####|######) "
  reAnotherAtxHeader* = re"^(#|##|###|####|#####|######)$"
  reBlockQuote* = re"^(| |  |   )>( |)"
  reUnorderedListDash* = re"^(| |  |   )- "
  reUnorderedListPlus* = re"^(| |  |   )\+ "
  reUnorderedListAste* = re"^(| |  |   )\* "
  reOrderedListSpaceStart* = re"^(| |  |   )1\. "
  reOrderedListPareStart* = re"^(| |  |   )1\)"
  reOrderedListSpace* = re"^(| |  |   )(2|3|4|5|6|7|8|9)\. "
  reOrderedListPare* = re"^(| |  |   )(2|3|4|5|6|7|8|9)\)"
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
      return Block(kind: leafBlock, leafType: header1, inline: Inline(kind: text, value: str))
    of "##":
      let str = line.strip(chars = {' ', '#'})
      return Block(kind: leafBlock, leafType: header2, inline: Inline(kind: text, value: str))
    of "###":
      let str = line.strip(chars = {' ', '#'})
      return Block(kind: leafBlock, leafType: header3, inline: Inline(kind: text, value: str))
    of "####":
      let str = line.strip(chars = {' ', '#'})
      return Block(kind: leafBlock, leafType: header4, inline: Inline(kind: text, value: str))
    of "#####":
      let str = line.strip(chars = {' ', '#'})
      return Block(kind: leafBlock, leafType: header5, inline: Inline(kind: text, value: str))
    of "######":
      let str = line.strip(chars = {' ', '#'})
      return Block(kind: leafBlock, leafType: header6, inline: Inline(kind: text, value: str))

proc openAnotherAtxHeader*(line: string): Block =
  case line
    of "#":
      return Block(kind: leafBlock, leafType: header1, inline: Inline(kind: text, value: ""))
    of "##":
      return Block(kind: leafBlock, leafType: header2, inline: Inline(kind: text, value: ""))
    of "###":
      return Block(kind: leafBlock, leafType: header3, inline: Inline(kind: text, value: ""))
    of "####":
      return Block(kind: leafBlock, leafType: header4, inline: Inline(kind: text, value: ""))
    of "#####":
      return Block(kind: leafBlock, leafType: header5, inline: Inline(kind: text, value: ""))
    of "######":
      return Block(kind: leafBlock, leafType: header6, inline: Inline(kind: text, value: ""))

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

proc openHtmlBlock*(lineBlock: string): Block =
  return Block(kind: leafBlock, leaftype: htmlblock, inline: Inline(kind: text, value: lineBlock))

proc openLinkReference*(lineBlock: string): Block =
  return Block(kind: leafBlock, leaftype: linkReference, inline: Inline(kind: text, value: lineBlock))

proc openParagraph*(lineBlock: string): Block =
  Block(kind: leafBlock, leafType: paragraph, inline: Inline(kind: text, value: lineBlock))
