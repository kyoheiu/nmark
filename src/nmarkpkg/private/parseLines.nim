import strutils, sequtils, re
import defBlock

type
  MarkerFlag* = ref MFObj
  MFObj = object
    numHeadSpace: int
    numHeading: int
    kind: BlockType
    width: int
  
proc newMarkerFlag(): MarkerFlag =
  MarkerFlag(
    numHeadSpace: 0,
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

    #check for marker begins
    for i, c in line:



      block ICBblock:

        if m.kind == indentedCodeBlock:
          if (not line.isEmptyOrWhitespace) and
            line.countWhitespace < 4:
            lineBlock.removeSuffix("\n")
            mdast.add(openCodeBlock(indentedCodeBlock, lineBlock))
            lineBlock = ""
            m.kind = none
            break ICBblock
          elif line.isEmptyOrWhiteSpace:
            lineBlock.add("\n")
            continue
          else:
            line.delete(0, 3)
            lineBlock.add("\n" & line)
            continue



      if line.isEmptyOrWhitespace:
        m.kind = emptyLine
        break

      elif lineBlock != "" and line.match(reSetextHeader):
        m.kind = setextHeader
        break
      
      elif line.delWhitespace.startsWith(reThematicBreak):
        m.kind = themanticBreak
        break
      
      elif line.match(reAnotherAtxHeader):
        m.kind = headerEmpty
        break



      if i == 0:
        case c

        of '#':
          m.numHeading = 1
          continue
        
        of ' ':
          m.numHeadSpace = 1
          continue

        else: continue
    
      
      case c

      of '#':
        m.numHeading.inc
      
      of ' ':
        if (1..6).contains(m.numHeading):
          m = newMarkerFlag()
          m.kind = header
          break
        else:
          m.numHeadSpace.inc
          if m.numHeadSpace  == 4 and m.kind != paragraph:
            m = newMarkerFlag()
            m.kind = indentedCodeBlock
            break

      else:
        m = newMarkerFlag()
        m.kind = paragraph
        break
    #check for marker ends



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
        m.kind = none
      
    elif m.kind == indentedCodeBlock:
      if lineBlock == "":
        line.delete(0, 3)
        lineBlock.add(line)
      else:
        lineBlock.add("\n" & line.strip(trailing = false))
    
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