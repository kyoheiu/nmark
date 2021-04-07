import strutils, sequtils, re
import defBlock

type
  MarkerFlag* = ref MFObj
  MFObj = object
    numWSpace: int
    maybeBQ: bool
    maybeULdash: bool
    maybeULaste: bool
    maybeULplus: bool
    maybeOLdot: bool
    maybeOLbra: bool
    numHeading: int
    kind: BlockType
    width: int
  
proc newMarkerFlag(): MarkerFlag =
  MarkerFlag(
    numWSpace: 0,
    maybeBQ: false,
    maybeULdash: false,
    maybeULaste: false,
    maybeULplus: false,
    maybeOLdot: false,
    maybeOLbra: false,
    numHeading: 0,
    kind: none,
    width: 0
  )



proc parseLines*(s: string): seq[Block] =
  
  var m = newMarkerFlag()
  var flag = newFlag()
  var lineBlock: string
  var mdast: seq[Block]

  for str in s.splitLines:
    var line = str

    if line.isEmptyOrWhitespace:
      m.kind = emptyLine

    elif m.kind == paragraph and line.match(reSetextHeader):
      m.kind = setextHeader
    
    elif line.delWhitespace.startsWith(reThematicBreak):
      m.kind = themanticBreak
    
    elif line.match(reAnotherAtxHeader):
      m.kind = headerEmpty



    #check for marker begins
    for i, c in line:

      if m.kind != none:
        break




      if i == 0:
        case c

        of '#':
          m.numHeading = 1
        
        of ' ':
          m.numWSpace = 1

        else: continue
    
      
      case c

      of '#':
        if m.numHeading != 0:
          m.numHeading.inc
        else: continue
      
      of ' ':
        if (1..6).contains(m.numHeading):
          m.kind = header
          m.width = m.numWSpace + m.numHeading
        else:
          m.numWSpace.inc

      else:
        m.kind = paragraph
        break
    #check for marker ends

    echo m.kind
    #line-adding begins
    if m.kind == themanticBreak:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      mdast.add(openThemanticBreak())
      m.kind = none

    if m.kind == header:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      mdast.add(openAtxHeader(line))
      m.kind = none
    
    elif m.kind == headerEmpty:
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      mdast.add(openAnotherAtxHeader(line))
      m.kind = none
    
    elif m.kind == setextHeader:
      if lineBlock == "":
        lineBlock.add(line)
      else:
        var n: int
        if line.contains('='): n = 1
        else: n = 2
        mdast.add(openSetextHeader(n, lineBlock))
        lineBlock = ""

    elif m.kind == emptyLine:
      if flag.flagUnorderedList:
        continue
      elif flag.flagOrderedList:
        continue
      elif flag.flagHtmlBlock6:
          mdast.add(openHtmlBlock(lineBlock))
          lineBlock = ""
          flag.flagHtmlBlock6 = false
          m.kind = none
      elif flag.flagHtmlBlock7:
          mdast.add(openHtmlBlock(lineBlock))
          lineBlock = ""
          flag.flagHtmlBlock7 = false
          m.kind = none
      elif lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
        m.kind = none
        continue
      else:
        m.kind = none
        continue

    elif m.kind == paragraph:
      if lineBlock != "":
        lineBlock.add("\n" & line.strip(trailing = false))
      else:
        lineBlock.add(line.strip(trailing = false))
    #line-adding ends


  #after EOF
  if lineBlock != "":
    mdast.add(openParagraph(lineBlock))
  
  result = concat(result, mdast)
  
  return result