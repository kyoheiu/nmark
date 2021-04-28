import sequtils, strutils, re

type
  BlockType* = enum
    paragraph,
    header,
    headerEmpty,
    header1,
    header2,
    header3,
    header4,
    header5,
    header6,
    setextHeader,
    themanticBreak,
    indentedCodeBlock,
    fencedCodeBlockBack,
    fencedCodeBlockTild,
    fencedCodeBlock,
    htmlBlock1,
    htmlBlock2,
    htmlBlock3,
    htmlBlock4,
    htmlBlock5,
    htmlBlock6,
    htmlBlock7,
    htmlBlock,
    linkReference,
    blockQuote,
    unOrderedList,
    unOrderedTightList,
    unOrderedLooseList,
    orderedList,
    orderedTightList,
    orderedLooseList,
    list,
    emptyLine,
    table,
    none

  ALignKind* = enum
    nothing,
    center,
    left,
    right

  BlockKind* = enum
    containerBlock,
    olist,
    leafBlock,
    fencedCode,
    linkRef,
    tableBlock

  Block* = ref BlockObj
  BlockObj = object
    case kind*: BlockKind

    of containerBlock:
      containerType*: BlockType
      children*: seq[Block]
    
    of olist:
      olType*: BlockType
      startNumber*: int
      olChildren*: seq[Block]

    of leafBlock:
      leafType*: BlockType
      raw*: string
    
    of fencedCode:
      codeType*: BlockType
      codeAttr*: string
      codeText*: string
    
    of linkRef:
      linkLabel*: string
      linkUrl*: string
      linkTitle*: string

    of tableBlock:
      align*: seq[ALignKind]
      thR*: seq[string]
      tdR*: seq[seq[string]]

  MarkerFlag* = ref MFObj
  MFObj = object
    numHeadSpace*: int
    numHeading*: int
    numBacktick*: int
    numTild*: int
    isAfterULMarker*: int
    isAfterNumber*: int
    isAfterOLMarker*: int
  
  AttrFlag* = ref AtFObj
  AtFObj = object
    numOpenfence*: int
    numEmptyLine*: int
    isAfterEmptyLine*: bool
    isLoose*: bool
    listSeq*: seq[Block]
    attr*: string
    kind*: BlockType
    width*: int
    startNum*: int
    markerType*: char
    was*: BlockType
    columnNum*: int
    align*: seq[ALignKind]
    th*: seq[string]
    td*: seq[seq[string]]
  
proc newMarkerFlag*(): MarkerFlag =
  MarkerFlag(
    numHeadSpace: 0,
    numHeading: 0,
    numBacktick: 0,
    numTild: 0,
    isAfterULMarker: 0,
    isAfterNumber: 0,
    isAfterOLMarker: 0
  )

proc newAttrFlag*(): AttrFlag =
  AttrFlag(
    numOpenfence: 0,
    numEmptyLine: 0,
    isAfterEmptyLine: false,
    isLoose: false,
    attr: "",
    kind: none,
    width: 0,
    startNum: 0,
    markerType: 'n',
    was: none,
    columnNum: 0,
    align: @[],
    th: @[],
    td: @[]
  )



let
  reThematicBreak* = re" {0,3}(\*{3,}|-{3,}|_{3,})$"
  reSetextHeader* = re"^ {0,3}(=+|-+)\s*$"
  reAnotherAtxHeader* = re"^#{1,6}$"
  reFencedCodeBlockBack* = re"^ {0,3}`{3,}[^`]*$"
  reFencedCodeBlockTild* = re"^ {0,3}~{3,}[^~]*~*$"

  reEmptyUL* = re"^ {0,3}(-|\+|\*) *$"
  reEmptyOL* = re"^ {0,3}[0-9]{1,9}(\.|\)) *$"

  reHtmlBlock1Begins* = re" {0,3}<(script|pre|style|textarea)( |>|$)"
  reHtmlBlock1Ends*   = re"</script>|</pre>|</style>|</textarea>"
  reHtmlBlock2Begins* = re" {0,3}<!--"
  reHtmlBlock2Ends*   = re"-->"
  reHtmlBlock3Begins* = re" {0,3}<\?"
  reHtmlBlock3Ends*   = re"\?>"
  reHtmlBlock4Begins* = re" {0,3}<![A-Z]"
  reHtmlBlock4Ends*   = re">"
  reHtmlBlock5Begins* = re" {0,3}<!\[CDATA\["
  reHtmlBlock5Ends*   = re"\]\]>"
  reHtmlBlock6Begins* = re(" {0,3}(<|</)(address|article|aside|base|basefont|blockquote|body|caption|center|col|colgroup|dd|details|dialog|dir|div|dl|dt|fieldset|figcaption|figure|footer|form|frame|frameset|h1|h2|h3|h4|h5|h6|head|header|hr|html|iframe|legend|li|link|main|menu|menuitem|nav|noframes|ol|optgroup|option|p|param|section|source|summary|table|tbody|td|tfoot|th|thead|title|tr|track|ul)( |\n|>|/>)", {reIgnoreCase})
  reHtmlBlock7Begins* = re(" {0,3}(<|</)[a-zA-Z][a-zA-Z0-9-]*( [a-zA-Z_:][a-zA-Z0-9|_|.|:|-]*)*( {0,1}= {0,1}(|'|\")[a-zA-Z]+(|'|\"))* */*(>|/>) *$")

  reLinkRef = re" {0,3}\[\s*.*\s*]:(\s*\n?\s*)"
  reEntity* = re"&[a-zA-Z0-9#]+;"

const olNum* = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
const puncChar* = ['!', '"', '#', '$', '%', '&', '\'', '(', ')', '+', ',', '-', '.', '/', ':', ';', '<', '=', '>', '?', '@', '[', '\\', ']', '^', '`', '{', '|', '}', '~']

proc delWhitespace*(line: string): string =
  for c in line:
    if c != ' ': result.add(c)
  return result

proc countWhitespace*(line: string): int =
  var i = 0
  for c in line:
    if c == ' ': i.inc
    else: return i
  return i

proc isTable*(line: string): bool =
  for c in line:
    case c
    of ' ', '-', '|', ':': continue
    else: return false
  return true

proc parseTableDelim*(line: string): seq[ALignKind] =
  let s = line.split('|')
         .filter(proc(x: string): bool = not x.isEmptyOrWhitespace)
  for delim in s:
    let e = delim.strip
    if e[0] == ':' and e[^1] == ':':
      result.add(center)
    elif e[0] == ':':
      result.add(left)
    elif e[^1] == ':':
      result.add(right)
    else:
      result.add(nothing)
  
proc parseTableElement*(line: string): seq[string] =
  var str: string
  var flag = false
  for c in line:
    case c
    of '|':
      if not flag:
        if not str.isEmptyOrWhitespace:
          result.add(str.strip)
          str = ""
        else: continue
      else: 
        flag = false
        str.add(c)
    of '\\':
      flag = true
    else:
      if flag: flag = false
      str.add(c)
  if not str.isEmptyOrWhitespace: result.add(str.strip)

proc addTableElement*(td: var seq[seq[string]], row: var seq[string], columnNum: int) =
  let length = row.len()
  if length == columnNum:
    td.add(row)
  elif length < columnNum:
    while true:
      row.add("")
      if row.len() == columnNum: break
    td.add(row)
  else:
    td.add(row[0..columnNum-1])

proc openTable*(alignSeq: seq[ALignKind], th: seq[string], td: seq[seq[string]]): Block =
  return Block(kind: tableBlock, align: alignSeq, thR: th, tdR: td)
  
proc delULMarker*(line: var string): (int, string, char) =
  var n: int
  var s: string
  var marker: char
  var flag: bool
  var mPos: int
  var ws: int
  for i, c in line:
    if c == '-' or c == '+' or c == '*':
      if flag:
        n = mPos + ws + 1
        s = line[n..^1]
        return (n, s, marker)
      else:
        marker = c
        flag = true
        mPos = i
    elif c == ' ':
      if flag:
        ws.inc
        if ws == 5:
          n = mPos + 2
          s = line[n..^1]
          return (n, s, marker)
      else: continue
    else:
      if flag:
        n = mPos + ws + 1
        s = line[n..^1]
        return (n, s, marker)
      else: continue
  return (mPos+2, "", marker)

proc delOLMarker*(line: var string): (int, int, string, char) =
  var n: int
  var s: string
  var marker: char
  var flag: bool
  var mPos: int
  var ws: int
  var startNum: string
  for i, c in line:
    if c == '.' or c == ')':
      flag = true
      mPos = i
      marker = c
    elif c == ' ':
      if flag:
        ws.inc
        if ws == 5:
          n = mPos + 2
          s = line[n..^1]
          return (n, startNum.parseInt, s, marker)
      else: continue
    elif olNum.contains(c):
      if flag: 
        n = mPos + ws + 1
        s = line[n..^1]
        return (n, startNum.parseInt, s, marker)
      else:
        startNum.add(c)
    else:
      if flag:
        n = mPos + ws + 1
        s = line[n..^1]
        return (n, startNum.parseInt, s, marker)
      else: continue
  return (mPos+2, startNum.parseInt, "", marker)



proc isUL*(line: string): bool =
  var m = newMarkerFlag()

  if line.startsWith(reHtmlBlock1Begins) or
    line.startsWith(reHtmlBlock2Begins) or
    line.startsWith(reHtmlBlock3Begins) or
    line.startsWith(reHtmlBlock4Begins) or
    line.startsWith(reHtmlBlock5Begins) or
    line.startsWith(reHtmlBlock6Begins) or
    line.startsWith(reHtmlBlock7Begins) or
    line.match(reAnotherAtxHeader) or
    line.match(reSetextHeader) or
    line.countWhitespace < 4 and line.delWhitespace.startsWith(reThematicBreak):
    return false
  
  for i, c in line:

    if m.isAfterULMarker > 0:
      m.isAfterULMarker.dec
    if m.isAfterNumber > 0:
      m.isAfterNumber.dec
    if m.isAfterOLMarker > 0:
      m.isAfterOLMarker.dec

    if i == 0:
      case c

      of ' ':
        m.numHeadSpace = 1
        continue

      of '-', '+', '*':
        m.isAfterULMarker = 2
        continue

      else: return false
  
    
    case c

    of ' ':
      if m.isAfterULMarker == 1:
        return true
      else:
        m.numHeadSpace.inc
        if m.numHeadSpace == 4:
          return false

    of '-', '+', '*':
      if m.isAfterULMarker > 0:
        return false
      else:
        m.isAfterULMarker = 2
    
    else: 
      return false

  return false



proc isOL*(line: string): bool =
  var m = newMarkerFlag()

  if line.startsWith(reHtmlBlock1Begins) or
    line.startsWith(reHtmlBlock2Begins) or
    line.startsWith(reHtmlBlock3Begins) or
    line.startsWith(reHtmlBlock4Begins) or
    line.startsWith(reHtmlBlock5Begins) or
    line.startsWith(reHtmlBlock6Begins) or
    line.startsWith(reHtmlBlock7Begins) or
    line.match(reAnotherAtxHeader) or
    line.match(reSetextHeader) or
    line.countWhitespace < 4 and line.delWhitespace.startsWith(reThematicBreak):
    return false
  
  for i, c in line:

    if m.isAfterULMarker > 0:
      m.isAfterULMarker.dec
    if m.isAfterNumber > 0:
      m.isAfterNumber.dec
    if m.isAfterOLMarker > 0:
      m.isAfterOLMarker.dec

    if i == 0:
      case c

      of ' ':
        m.numHeadSpace = 1
        continue

      of olNum:
        m.isAfterNumber = 2

      else: return false
  
    
    case c

    of ' ':
      if m.isAfterOLMarker == 1:
        return true
      else:
        m.numHeadSpace.inc
        if m.numHeadSpace == 4:
          return false

    of olNum:
      m.isAfterNumber = 2

    of '.', ')':
      if m.isAfterNumber == 1:
        m.isAfterOLMarker = 2
      else: return false
    
    else: 
      return false

  return false



proc countBacktick*(line: string): int =
  var i: int
  for c in line:
    if c == ' ': continue
    elif c == '`': i.inc
    else: return i
  return i

proc countTild*(line: string): int =
  var i: int
  for c in line:
    if c == ' ': continue
    elif c == '~': i.inc
    else: return i
  return i

proc delSpaceAndFence*(line: string): string =
  var flag = false
  for c in line:
    if flag:
      result.add(c)
    elif c == ' ' or c == '`' or c == '~': continue
    else:
      flag = true
      result.add(c)

proc takeAttr*(line: string): string =
  let s = line.splitWhitespace
  return s[0]

proc openAtxHeader*(line: string): Block =
  var s = line.splitWhitespace
  let l = s.len()
  let marker = s[0]
  if s[l-1].all(proc(c: char): bool = c == '#'):
    s.delete(l-1, l-1)
  s.delete(0,0)
  let str = s.join(" ")

  case marker:
    of "#":
      return Block(kind: leafBlock, leafType: header1, raw: str)
    of "##":
      return Block(kind: leafBlock, leafType: header2, raw: str)
    of "###":
      return Block(kind: leafBlock, leafType: header3, raw: str)
    of "####":
      return Block(kind: leafBlock, leafType: header4, raw: str)
    of "#####":
      return Block(kind: leafBlock, leafType: header5, raw: str)
    of "######":
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

proc openCodeBlock*(blockType: BlockType, atr: string, lines: string): Block =
  return Block(kind: fencedCode, codeType: blockType, codeAttr: atr, codeText: lines)

proc openSetextHeader*(n: int, lineBlock: string): Block =
  if n == 1:
    return Block(kind: leafBlock, leafType: header1, raw: lineBlock)
  else:
    return Block(kind: leafBlock, leafType: header2, raw: lineBlock)

proc openThemanticBreak*(): Block =
  return Block(kind: leafBlock, leafType: themanticBreak, raw: "")

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

proc openLooseOL*(mdast: seq[Block], startNum: int): Block =
  Block(kind: olist, olType: orderedLooseList, startNumber: startNum, olChildren: mdast)

proc openTightOL*(mdast: seq[Block], startNum: int): Block =
  Block(kind: olist, olType: orderedTightList, startNumber: startNum, olChildren: mdast)



proc openHTML*(lineBlock: string): Block =
  Block(kind: leafBlock, leafType: htmlBlock, raw: lineBlock)



type linkRefKind = enum
  toLabel
  skipToUrl
  toUrl
  toUrlLT
  skipToTitle
  toTitleDouble
  toTitleSingle
  toTitlePare
  afterTitle

proc openParagraph*(lineBlock: var string): seq[Block] =
  
  if lineBlock.startsWith(reLinkRef):

    block linkDetecting:

      while true:

        var
          label: string
          url: string
          title: string
          urlEndPos: int
          titleEndPos: int
          numOpenP: int
          numCloseP: int
          isAfterBreak = false
          isAfterBS = false
          isAfterWS = false
          isUrlLT = false
          nextLoop = false
          flag = toLabel

        for i, c in lineBlock:
          if i == 0: continue

          case flag
          of toLabel:
            if c == '[' and lineBlock[i-1] != '\\': break linkDetecting
            elif c == ']' and lineBlock[i-1] != '\\':
              flag = skipToUrl
              continue
            elif c == '\\':
              continue
            else:
              label.add(c)
              continue
          
          of skipToUrl:
            if c == ':' or c == ' ' or c == '\n': continue
            elif c == '<':
              flag = toUrlLT
              isUrlLT = true
              continue
            else:
              url.add(c)
              flag = toUrl
              continue
          
          of toUrlLT:
            if c == '\n': break linkDetecting
            elif c == '<' and lineBlock[i-1] != '\\': break linkDetecting
            elif c == '>' and lineBlock[i-1] != '\\':
              urlEndPos = i
              flag = skipToTitle
              continue
            elif c == ' ':
              url.add("%20")
              continue
            else:
              url.add(c)
              continue
          
          of toUrl:
            if c == '(' and lineBlock[i-1] != '\\':
              numOpenP.inc
              url.add(c)
            elif c == ')' and lineBlock[i-1] != '\\':
              numCloseP.inc
              url.add(c)
            elif c == '\\':
              isAfterBS = true
              continue
            elif c == ' ':
              if numOpenP == numCloseP:
                urlEndPos = i
                flag = skipToTitle
                isAfterWS = true
                continue
              else:
                break linkDetecting
            elif c == '\n':
              if numOpenP == numCloseP:
                urlEndPos = i
                flag = skipToTitle
                isAfterBreak = true
                continue
              else:
                break linkDetecting
            elif c == '*':
              isAfterBS = false
              url.add(c)
            else:
              if isAfterBS:
                isAfterBS = false
                url.add("%5C" & c)
              else:
                url.add(c)
                continue
          
          of skipToTitle:
            if c == ' ':
              isAfterWS = true
              continue 
            elif c == '\n':
              if isAfterBreak:
                result.add(Block(kind: linkRef, linkLabel: label, linkUrl: url, linkTitle: ""))
                lineBlock.delete(0, urlEndPos)
                break linkDetecting
              else:
                isAfterBreak = true
                continue
            elif c == '"':
              if isAfterWS or isAfterBreak:
                title.add(c)
                flag = toTitleDouble
                isAfterWS = false
                continue
              else:
                break linkDetecting
            elif c == '\'':
              if isAfterWS or isAfterBreak:
                title.add(c)
                flag = toTitleSingle
                isAfterWS = false
                continue
              else: break linkDetecting
            elif c == '(':
              if isAfterWS or isAfterBreak:
                title.add(c)
                flag = toTitleDouble
                isAfterWS = false
                continue
              else: break linkDetecting
            else:
              if isAfterBreak:
                result.add(Block(kind: linkRef, linkLabel: label, linkUrl: url, linkTitle: ""))
                lineBlock.delete(0, urlEndPos)
                nextLoop = true
                break 
              else:
                break linkDetecting
          
          of toTitleDouble:
            if c == '"' and not(isAfterBS):
              title.add(c)
              titleEndPos = i
              flag = afterTitle
              continue
            elif c == '"' and isAfterBS:
              title.add("&quot;")
              isAfterBS = false
              continue
            elif c == '\\':
              isAfterBS = true
              continue
            else:
              if isAfterBS:
                isAfterBS = false
                title.add("\\" & c)
                continue
              else:
                title.add(c)
                continue

          of toTitleSingle:
            if c == '\'' and not(isAfterBS):
              title.add(c)
              titleEndPos = i
              flag = afterTitle
              continue
            elif c == '\'' and isAfterBS:
              title.add(c)
              isAfterBS = false
              continue
            elif c == '\\':
              isAfterBS = true
              continue
            else:
              if isAfterBS:
                isAfterBS = false
                title.add("\\" & c)
                continue
              else:
                title.add(c)
                continue

          of toTitlePare:
            if c == '(' and not(isAfterBS): break linkDetecting
            if c == ')' and not(isAfterBS):
              title.add(c)
              titleEndPos = i
              flag = afterTitle
              continue
            elif c == ')' and isAfterBS:
              title.add(c)
              isAfterBS = false
              continue
            elif c == '\\':
              isAfterBS = true
              continue
            else:
              if isAfterBS:
                isAfterBS = false
                title.add("\\" & c)
                continue
              else:
                title.add(c)
                continue
            if c == '(' and lineBlock[i-1] != '\\': break linkDetecting
            elif c == ')' and lineBlock[i-1] != '\\':
              title.add(c)
              titleEndPos = i
              flag = afterTitle
              continue
            else:
              title.add(c)
              continue
          
          of afterTitle:
            if c == ' ': continue
            elif c == '\n':
              result.add(Block(kind: linkRef, linkLabel: label, linkUrl: url, linkTitle: title[1..^2]))
              lineBlock.delete(0, i)
              nextLoop = true
              break
            else:
              if isAfterBreak:
                result.add(Block(kind: linkRef, linkLabel: label, linkUrl: url, linkTitle: ""))
                lineBlock.delete(0, urlEndPos)
                break linkDetecting
              else:
                break linkDetecting
              
        
        if nextLoop:
          continue

        elif url == "":
          if isUrlLT:
            result.add(Block(kind: linkRef, linkLabel: label, linkUrl: "", linkTitle: ""))
            return result
          else:
            break linkDetecting

        elif url != "" and title == "":
          result.add(Block(kind: linkRef, linkLabel: label, linkUrl: url, linkTitle: ""))
          return result
      
        elif url != "" and title != "":
          if (title[0] == '"' and title[^1] == '"') or
             (title[0] == '\'' and title[^1] == '\'') or
             (title[0] == '(' and title[^1] == ')'):
            result.add(Block(kind: linkRef, linkLabel: label, linkUrl: url, linkTitle: title[1..^2]))
            return result
          else:
            break linkDetecting

        else:
          if lineBlock.startsWith(reLinkRef):
            continue
          else: break


  if lineBlock == "":
    return result
  else:
    result.add(Block(kind: leafBlock, leafType: paragraph, raw: lineBlock))
    return result
