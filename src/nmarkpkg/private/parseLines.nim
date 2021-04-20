import strutils, sequtils, re
import defBlock

type
  MarkerFlag* = ref MFObj
  MFObj = object
    numHeadSpace: int
    numHeading: int
    numBacktick: int
    numTild: int
    isAfterULMarker: int
  
  AttrFlag* = ref AtFObj
  AtFObj = object
    numOpenfence: int
    numEmptyLine: int
    isAfterEmptyLine: bool
    isLoose: bool
    listSeq: seq[Block]
    attr: string
    kind: BlockType
    width: int
  
proc newMarkerFlag(): MarkerFlag =
  MarkerFlag(
    numHeadSpace: 0,
    numHeading: 0,
    numBacktick: 0,
    numTild: 0,
    isAfterULMarker: 0
  )

proc newAttrFlag(): AttrFlag =
  AttrFlag(
    numOpenfence: 0,
    numEmptyLine: 0,
    isAfterEmptyLine: false,
    isLoose: false,
    attr: "",
    kind: none,
    width: 0
  )



proc parseLines*(s: string): seq[Block] =

  var lineBlock: string
  var a = newAttrFlag()

  for str in s.splitLines:
    var line = str
    var m = newMarkerFlag()



    block bqblock:
      if a.kind == blockQuote:

        if line.isEmptyOrWhitespace:
          result.add(openBlockQuote(lineBlock.parseLines))
          lineBlock = ""
          a = newAttrFlag()
          break bqblock

        # check if (lazy) continuation lines
        for i, c in line:

          if line.startsWith(reHtmlBlock1Begins) or
             line.startsWith(reHtmlBlock2Begins) or
             line.startsWith(reHtmlBlock3Begins) or
             line.startsWith(reHtmlBlock4Begins) or
             line.startsWith(reHtmlBlock5Begins) or
             line.startsWith(reHtmlBlock6Begins) or
             line.startsWith(reHtmlBlock7Begins) or
             line.countWhitespace < 4 and line.delWhitespace.startsWith(reThematicBreak):
            a.kind = none
            break

          if i == 0 :
            case c

            of '#':
              m.numHeading = 1
              continue
            
            of ' ':
              m.numHeadSpace = 1
              continue

            of '`':
              m.numBacktick = 1

            of '~':
              m.numTild = 1
            
            of '\\':
              a.kind = paragraph
              break

            of '>':
              line.delete(0, 0)
              if (not line.isEmptyOrWhitespace) and
                line[0] == ' ':
                line.delete(0, 0)
              if line.isEmptyOrWhitespace:
                a.isAfterEmptyLine = true
                break
              else:
                a.isAfterEmptyLine = false
                break

            else: continue
    
      
          case c

          of '#':
            m.numHeading.inc
          
          of ' ':
            if m.numBacktick > 0: m.numBacktick = -128
            if (1..6).contains(m.numHeading):
              a.kind = header
              break
            else:
              m.numHeadSpace.inc
              if m.numHeadSpace == 4:
                a.kind = indentedCodeBlock
                break

          of '`':
            m.numBacktick.inc
            if m.numBacktick == 3 and line.match(reFencedCodeBlockBack):
              a.kind = fencedCodeBlockBack
              break
          
          of '~':
            m.numTild.inc
            if m.numTild >= 3 and line.match(reFencedCodeBlockTild):
              a.kind = fencedCodeBlockTild
              break

          of '>':
            line.delete(0, i)
            if (not line.isEmptyOrWhitespace) and
              line[0] == ' ':
              line.delete(0, 0)
            if line.isEmptyOrWhitespace:
              a.isAfterEmptyLine = true
              break
            else:
              a.isAfterEmptyLine = false
              break

          else:
            if a.isAfterEmptyLine: a.kind = paragraph
            break

        if a.kind == blockQuote:
          lineBlock.add("\n" & line)
          continue
        else:
          result.add(openBlockQuote(lineBlock.parseLines))
          lineBlock = ""
          a = newAttrFlag()
          m = newMarkerFlag()
          break bqblock



    block ulblock:
      if a.kind == unOrderedList:
        if line.isEmptyOrWhitespace:
          lineBlock.add("\n")
          a.isAfterEmptyLine = true
          continue
        elif line.countWhitespace >= a.width:
          if a.isAfterEmptyLine:
            a.isLoose = true
          a.isAfterEmptyLine = false
          lineBlock.add("\n" & line[a.width..^1])
          continue
        else:
          if a.isAfterEmptyLine:
            if a.isLoose:
              a.listSeq.add(lineBlock.parseLines.openList)
              result.add(a.listSeq.openLooseUL)
              lineBlock = ""
              a = newAttrFlag()
              break ulblock
            else:
              a.listSeq.add(lineBlock.parseLines.openList)
              result.add(a.listSeq.openTightUL)
              lineBlock = ""
              a = newAttrFlag()
              break ulblock
          else:

            for i, c in line:

              if line.startsWith(reHtmlBlock1Begins) or
                line.startsWith(reHtmlBlock2Begins) or
                line.startsWith(reHtmlBlock3Begins) or
                line.startsWith(reHtmlBlock4Begins) or
                line.startsWith(reHtmlBlock5Begins) or
                line.startsWith(reHtmlBlock6Begins) or
                line.startsWith(reHtmlBlock7Begins) or
                line.countWhitespace < 4 and line.delWhitespace.startsWith(reThematicBreak):
                a.kind = none
                break

              if i == 0 :
                case c

                of '#':
                  m.numHeading = 1
                  continue
                
                of ' ':
                  m.numHeadSpace = 1
                  continue

                of '`':
                  m.numBacktick = 1

                of '~':
                  m.numTild = 1
                
                of '\\':
                  a.kind = paragraph
                  break

                of '>':
                  a.kind = blockQuote
                  break

                else: continue
        
          
              case c

              of '#':
                m.numHeading.inc
              
              of ' ':
                if m.numBacktick > 0: m.numBacktick = -128
                if (1..6).contains(m.numHeading):
                  a.kind = header
                  break
                else:
                  m.numHeadSpace.inc
                  continue

              of '`':
                m.numBacktick.inc
                if m.numBacktick == 3 and line.match(reFencedCodeBlockBack):
                  a.kind = fencedCodeBlockBack
                  break
              
              of '~':
                m.numTild.inc
                if m.numTild >= 3 and line.match(reFencedCodeBlockTild):
                  a.kind = fencedCodeBlockTild
                  break

              of '>':
                a.kind = blockQuote
                break

              else:
                break

            if a.kind == unOrderedList:
              lineBlock.add("\n" & line)
              continue
            else:
              if a.isLoose:
                a.listSeq.add(lineBlock.parseLines.openList)
                result.add(a.listSeq.openLooseUL)
                lineBlock = ""
                a = newAttrFlag()
                m = newMarkerFlag()
                break ulblock
              else:
                a.listSeq.add(lineBlock.parseLines.openList)
                result.add(a.listSeq.openLooseUL)
                lineBlock = ""
                a = newAttrFlag()
                m = newMarkerFlag()
                break ulblock



    block iCBblock:
      if a.kind == indentedCodeBlock:
        if (not line.isEmptyOrWhitespace) and
          line.countWhitespace < 4:
          if a.numEmptyLine != 0:
            var s = lineBlock.splitLines
            let l = s.len() - 1
            s.delete(l - a.numEmptyLine + 1, l)
            lineBlock = s.join("\n")
          result.add(openCodeBlock(indentedCodeBlock, "", lineBlock))
          lineBlock = ""
          a = newAttrFlag()
          break iCBblock
        elif line.isEmptyOrWhiteSpace:
          a.numEmptyLine.inc
          let w = line.countWhitespace
          if w >= 4:
            line.delete(0, 3)
            lineBlock.add("\n" & line)
            continue
          else:
            lineBlock.add("\n")
            continue
        else:
          line.delete(0, 3)
          lineBlock.add("\n" & line)
          a.numEmptyLine = 0
          continue



    block fencedCodeBackblock:
      if a.kind == fencedCodeBlockBack:
        let rem = line.delSpaceAndFence

        if rem != "":
          let numWS = line.countWhitespace
          if numWS >= a.width:
            line.delete(0, a.width - 1)
          if numWS > 0 and
               numWS < a.width:
            line.removePrefix(' ')
          lineBlock.add(line & "\n")
          continue

        elif line.match(reFencedCodeBlockBack) and
            line.countBacktick >= a.numOpenfence:
          lineBlock.removeSuffix("\n")
          result.add(openCodeBlock(fencedCodeBlock, a.attr, lineBlock))
          lineBlock = ""
          a = newAttrFlag()
          m = newMarkerFlag()
          continue

        else:
          let numWS = line.countWhitespace
          if numWS >= a.width:
            line.delete(0, a.width - 1)
          if numWS > 0 and
               numWS < a.width:
            line.removePrefix(' ')
          lineBlock.add(line & "\n")
          continue



    block fencedCodeTildblock:
      if a.kind == fencedCodeBlockTild:
        if line.match(reFencedCodeBlockTild) and
            line.countTild >= a.numOpenfence:
          lineBlock.removeSuffix("\n")
          result.add(openCodeBlock(fencedCodeBlock, a.attr, lineBlock))
          lineBlock = ""
          a = newAttrFlag()
          m = newMarkerFlag()
          continue
        else:
          let numWS = line.countWhitespace
          if numWS >= a.width:
            line.delete(0, a.width - 1)
          if numWS > 0 and
               numWS < a.width:
            line.removePrefix(' ')
          lineBlock.add(line & "\n")
          continue


    # html block
    block hblock:

      if a.kind == htmlBlock1:
        if line.contains(reHtmlBlock1Ends):
          lineBlock.add("\n" & line)
          result.add(openHTML(lineBlock))
          lineBlock = ""
          a = newAttrFlag()
          m = newMarkerFlag()
          continue
        else:
          lineBlock.add("\n" & line)
          continue

      if a.kind == htmlBlock2:
        if line.contains(reHtmlBlock2Ends):
          lineBlock.add("\n" & line)
          result.add(openHTML(lineBlock))
          lineBlock = ""
          a = newAttrFlag()
          m = newMarkerFlag()
          continue
        else:
          lineBlock.add("\n" & line)
          continue

      if a.kind == htmlBlock3:
        if line.contains(reHtmlBlock3Ends):
          lineBlock.add("\n" & line)
          result.add(openHTML(lineBlock))
          lineBlock = ""
          a = newAttrFlag()
          m = newMarkerFlag()
          continue
        else:
          lineBlock.add("\n" & line)
          continue

      if a.kind == htmlBlock4:
        if line.contains(reHtmlBlock4Ends):
          lineBlock.add("\n" & line)
          result.add(openHTML(lineBlock))
          lineBlock = ""
          a = newAttrFlag()
          m = newMarkerFlag()
          continue
        else:
          lineBlock.add("\n" & line)
          continue

      if a.kind == htmlBlock5:
        if line.contains(reHtmlBlock5Ends):
          lineBlock.add("\n" & line)
          result.add(openHTML(lineBlock))
          lineBlock = ""
          a = newAttrFlag()
          m = newMarkerFlag()
          continue
        else:
          lineBlock.add("\n" & line)
          continue

      if a.kind == htmlBlock6:
        if line.isEmptyOrWhitespace:
          result.add(openHTML(lineBlock))
          lineBlock = ""
          a = newAttrFlag()
          m = newMarkerFlag()
          continue
        else:
          lineBlock.add("\n" & line)
          continue

      if a.kind == htmlBlock7:
        if line.isEmptyOrWhitespace:
          result.add(openHTML(lineBlock))
          lineBlock = ""
          a = newAttrFlag()
          m = newMarkerFlag()
          continue
        else:
          lineBlock.add("\n" & line)
          continue

      if line.startsWith(reHtmlBlock1Begins):
        if lineBlock != "":
          result.add(openParagraph(lineBlock))
          lineBlock = ""
        if line.contains(reHtmlBlock1Ends):
          result.add(openHTML(line))
          m = newMarkerFlag()
          continue
        else:
          a = newAttrFlag()
          a.kind = htmlBlock1
          lineBlock.add(line)
          continue
    
      if line.startsWith(reHtmlBlock2Begins):
        if lineBlock != "":
          result.add(openParagraph(lineBlock))
          lineBlock = ""
        if line.contains(reHtmlBlock2Ends):
          result.add(openHTML(line))
          m = newMarkerFlag()
          continue
        else:
          a = newAttrFlag()
          a.kind = htmlBlock2
          lineBlock.add(line)
          continue
      
      if line.startsWith(reHtmlBlock3Begins):
        if lineBlock != "":
          result.add(openParagraph(lineBlock))
          lineBlock = ""
        if line.contains(reHtmlBlock3Ends):
          result.add(openHTML(line))
          m = newMarkerFlag()
          continue
        else: 
          a = newAttrFlag()
          a.kind = htmlBlock3
          lineBlock.add(line)
          continue
      
      if line.startsWith(reHtmlBlock4Begins):
        if lineBlock != "":
          result.add(openParagraph(lineBlock))
          lineBlock = ""
        if line.contains(reHtmlBlock4Ends):
          result.add(openHTML(line))
          m = newMarkerFlag()
          continue
        else:
          a = newAttrFlag()
          a.kind = htmlBlock4
          lineBlock.add(line)
          continue
      
      if line.startsWith(reHtmlBlock5Begins):
        if lineBlock != "":
          result.add(openParagraph(lineBlock))
          lineBlock = ""
        if line.contains(reHtmlBlock5Ends):
          result.add(openHTML(line))
          m = newMarkerFlag()
          continue
        else:
          a = newAttrFlag()
          a.kind = htmlBlock5
          lineBlock.add(line)
          continue
      
      if line.startsWith(reHtmlBlock6Begins):
        if lineBlock != "":
          result.add(openParagraph(lineBlock))
          lineBlock = ""
        a = newAttrFlag()
        a.kind = htmlBlock6
        lineBlock.add(line)
        continue
      
      if line.startsWith(reHtmlBlock7Begins):
        if lineBlock != "":
          lineBlock.add("\n" & line.strip(trailing = false))
          continue
        else: 
          a = newAttrFlag()
          a.kind = htmlBlock7
          lineBlock.add(line)
          continue
      


    #check for marker begins
    for i, c in line:

      if m.isAfterULMarker > 0:
        m.isAfterULMarker.dec


      if lineBlock != "" and line.match(reSetextHeader):
        a = newAttrFlag()
        a.kind = setextHeader
        break
      
      elif line.countWhitespace < 4 and
           line.delWhitespace.startsWith(reThematicBreak):
        a = newAttrFlag()
        a.kind = themanticBreak
        break
      
      elif line.match(reAnotherAtxHeader):
        a = newAttrFlag()
        a.kind = headerEmpty
        break



      if i == 0:
        case c

        of '#':
          m.numHeading = 1
          continue
        
        of ' ':
          m.numHeadSpace = 1
          continue

        of '`':
          m.numBacktick = 1

        of '~':
          m.numTild = 1
        
        of '\\':
          a = newAttrFlag()
          a.kind = paragraph
          break

        of '>':
          if a.kind == paragraph:
            result.add(openParagraph(lineBlock))
            lineBlock = ""
          line.delete(0, i)
          if (not line.isEmptyOrWhitespace) and
             line[0] == ' ':
            line.delete(0, 0)
          a = newAttrFlag()
          a.kind = blockQuote
          break

        of '-', '+', '*':
          m.isAfterULMarker = 2
          continue

        else: continue
    
      
      case c

      of '#':
        m.numHeading.inc
      
      of ' ':
        if m.numBacktick > 0: m.numBacktick = -128
        if (1..6).contains(m.numHeading):
          a = newAttrFlag()
          a.kind = header
          break
        if m.isAfterULMarker == 1:
          a.kind = unOrderedList
          break
        else:
          m.numHeadSpace.inc
          if m.numHeadSpace == 4 and a.kind != paragraph:
            a = newAttrFlag()
            a.kind = indentedCodeBlock
            break
          elif m.numHeadSpace == 4 and a.kind == paragraph:
            break

      of '`':
        m.numBacktick.inc
        if m.numBacktick == 3 and line.match(reFencedCodeBlockBack):
          a = newAttrFlag()
          let rem = line.delSpaceAndFence
          if rem != "":
            a.attr = rem.takeAttr
          a.width = line.countWhitespace
          a.numOpenfence = line.countBacktick
          a.kind = fencedCodeBlockBack
          break
      
      of '~':
        m.numTild.inc
        if m.numTild >= 3 and line.match(reFencedCodeBlockTild):
          a = newAttrFlag()
          let rem = line.delSpaceAndFence
          if rem != "":
            a.attr = rem.splitWhitespace[0]
          a.width = line.countWhitespace
          a.numOpenfence = line.countTild
          a.kind = fencedCodeBlockTild
          break

      of '>':
        if lineBlock != "":
          result.add(openParagraph(lineBlock))
          lineBlock = ""
        line.delete(0, i)
        if not line.isEmptyOrWhitespace and
            line[0] == ' ':
          line.delete(0, 0)
        a = newAttrFlag()
        a.kind = blockQuote
        break

      of '-', '+', '*':
        if m.isAfterULMarker > 0:
          break
        else:
          m.isAfterULMarker = 2

      else: 
        a = newAttrFlag()
        a.kind = paragraph
        break



    if a.kind != blockQuote and line.isEmptyOrWhitespace:
      a = newAttrFlag()
      a.kind = emptyLine

    if a.kind == none: 
      a = newAttrFlag()
      a.kind = paragraph
    #check for marker ends



    #line-adding begins
    if a.kind == fencedCodeBlockBack or
       a.kind == fencedCodeBlockTild:
      if lineBlock != "":
        result.add(openParagraph(lineBlock))
        lineBlock = ""
      continue

    elif a.kind == blockQuote:
      lineBlock.add(line)
      continue

    elif a.kind == unorderedList:
      let (n, s) = line.delULMarker
      a.width = n
      if lineBlock != "":
        result.add(openParagraph(lineBlock))
        lineBlock = ""
      lineBlock.add(s)
      continue

    elif a.kind == themanticBreak:
      if lineBlock != "":
        result.add(openParagraph(lineBlock))
        lineBlock = ""
      result.add(openThemanticBreak())
      a.kind = none

    elif a.kind == header:
      if lineBlock != "":
        result.add(openParagraph(lineBlock))
        lineBlock = ""
      result.add(openAtxHeader(line))
      a.kind = none
    
    elif a.kind == headerEmpty:
      if lineBlock != "":
        result.add(openParagraph(lineBlock))
        lineBlock = ""
      result.add(openAnotherAtxHeader(line))
      a.kind = none
    
    elif a.kind == setextHeader:
      if lineBlock == "":
        lineBlock.add(line)
        a.kind = paragraph
      else:
        var n: int
        if line.contains('='): n = 1
        else: n = 2
        result.add(openSetextHeader(n, lineBlock.strip(chars = {' ', '\t'})))
        lineBlock = ""
        a = newAttrFlag()
        a.kind = none
      
    elif a.kind == indentedCodeBlock:
      if lineBlock == "":
        line.delete(0, 3)
        lineBlock.add(line)
      else:
        lineBlock.add("\n" & line.strip(trailing = false))
    
    elif a.kind == blockQuote:
      if lineBlock != "":
        result.add(openParagraph(lineBlock))
      continue

    elif a.kind == emptyLine:
      #if flag.flagUnorderedList:
        #continue
      #elif flag.flagOrderedList:
        #continue
      #elif flag.flagHtmlBlock6:
          #mdast.add(openHtmlBlock(lineBlock))
          #lineBlock = ""
          #flag.flagHtmlBlock6 = false
          #m.kind = none
      #elif flag.flagHtmlBlock7:
          #mdast.add(openHtmlBlock(lineBlock))
          #lineBlock = ""
          #flag.flagHtmlBlock7 = false
          #m.kind = none
      if lineBlock != "":
        result.add(openParagraph(lineBlock))
        lineBlock = ""
        continue
      else:
        continue

    elif a.kind == paragraph:
      if lineBlock != "":
        lineBlock.add("\n" & line.strip(trailing = false))
      else:
        lineBlock.add(line.strip(trailing = false))
    #line-adding ends


  #after EOF
  if lineBlock != "":

    if a.kind == blockQuote:
      result.add(openBlockQuote(lineBlock.parseLines))

    elif a.kind == unOrderedList:
      if a.isLoose:
        a.listSeq.add(lineBlock.parseLines.openList)
        result.add(a.listSeq.openLooseUL)
      else:
        a.listSeq.add(lineBlock.parseLines.openList)
        result.add(a.listSeq.openLooseUL)

    elif a.kind == fencedCodeBlockBack or
      a.kind == fencedCodeBlockTild:
      lineBlock.removeSuffix('\n')
      result.add(openCodeBlock(fencedCodeBlock, a.attr, lineBlock))
    
    elif a.kind == indentedCodeBlock:
      if a.numEmptyLine != 0:
        var s = lineBlock.splitLines
        let l = s.len() - 1
        s.delete(l - a.numEmptyLine + 1, l)
        lineBlock = s.join("\n")
      result.add(openCodeBlock(indentedCodeBlock, "", lineBlock))

    elif a.kind == htmlBlock1 or
         a.kind == htmlBlock2 or
         a.kind == htmlBlock3 or
         a.kind == htmlBlock4 or
         a.kind == htmlBlock5 or
         a.kind == htmlBlock6 or
         a.kind == htmlBlock7:
      lineBlock.removeSuffix("\n")
      result.add(openHTML(lineBlock))

    else:
      result.add(openParagraph(lineBlock))
  
  return result