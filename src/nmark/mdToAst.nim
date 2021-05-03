from re import match, startsWith, contains
import strutils, sequtils
import def

proc mdToAst*(s: string): seq[Block] =

  var lineBlock: string
  var a = newAttrFlag()

  for str in s.splitLines:
    var line = str
    var m = newMarkerFlag()



    block bqblock:
      if a.kind == blockQuote:

        if line.isEmptyOrWhitespace:
          result.add(openBlockQuote(lineBlock.mdToAst))
          lineBlock = ""
          a = newAttrFlag()
          break bqblock

        # check if (lazy) continuation lines
        for i, c in line:

          if i == 0 :

            if line.startsWith(reHtmlBlock1Begins) or
              line.startsWith(reHtmlBlock2Begins) or
              line.startsWith(reHtmlBlock3Begins) or
              line.startsWith(reHtmlBlock4Begins) or
              line.startsWith(reHtmlBlock5Begins) or
              line.startsWith(reHtmlBlock6Begins) or
              line.startsWith(reHtmlBlock7Begins1) or
              line.startsWith(reHtmlBlock7Begins2) or
              line.countWhitespace < 4 and line.delWhitespace.startsWith(reThematicBreak) or
              line.isUL or
              line.isOL:
              a.kind = none
              break

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

            else:
              if a.isAfterEmptyLine: a.kind = paragraph
              break
      
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
                if a.isAfterEmptyLine:
                  a.kind = indentedCodeBlock
                  break
                else:
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
          result.add(openBlockQuote(lineBlock.mdToAst))
          lineBlock = ""
          a = newAttrFlag()
          m = newMarkerFlag()
          break bqblock



    block listblock:
      if a.kind == unOrderedList or
         a.kind == orderedList:
        m.tabNum = line.countTab
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
        elif m.tabNum * 4 >= a.width:
          if a.isAfterEmptyLine:
            a.isLoose = true
          a.isAfterEmptyLine = false
          var tempStr = line
          tempStr.delete(0, m.tabNum-1)
          tempStr = (' ').repeat(m.tabNum * 4) & tempStr
          lineBlock.add("\n" & tempStr[a.width..^1])
          continue

        else:

          if line.isUL or line.match(reEmptyUL):
            if a.isAfterEmptyLine:
              a.isAfterEmptyLine = false
              a.isLoose = true
            let (n, s, marker) = line.delULMarker
            if a.kind == unOrderedList and a.markerType == marker:
              a.listSeq.add(lineBlock.mdToAst.openList)
              lineBlock = s
              a.width = n
              continue
            elif a.kind == unOrderedList:
              a.listSeq.add(lineBlock.mdToAst.openList)
              if a.isLoose:
                result.add(a.listSeq.openLooseUL)
              else:
                result.add(a.listSeq.openTightUL)
              a = newAttrFlag()
              lineBlock = s
              a.width = n
              a.markerType = marker
              a.kind = unOrderedList
              continue
            else:
              a.listSeq.add(lineBlock.mdToAst.openList)
              if a.isLoose:
                result.add(a.listSeq.openLooseOL(a.startNum))
              else:
                result.add(a.listSeq.openTightOL(a.startNum))
              a = newAttrFlag()
              lineBlock = s
              a.width = n
              a.markerType = marker
              a.kind = unOrderedList
              continue

          if line.isOL or line.match(reEmptyOL):
            if a.isAfterEmptyLine:
              a.isAfterEmptyLine = false
              a.isLoose = true
            let (n, startNum, s, marker) = line.delOLMarker
            if a.kind == orderedList and a.markerType == marker:
              a.listSeq.add(lineBlock.mdToAst.openList)
              lineBlock = s
              a.width = n
              continue
            elif a.kind == orderedList:
              a.listSeq.add(lineBlock.mdToAst.openList)
              if a.isLoose:
                result.add(a.listSeq.openLooseOL(a.startNum))
              else:
                result.add(a.listSeq.openTightOL(a.startNum))
              a = newAttrFlag()
              lineBlock = s
              a.width = n
              a.markerType = marker
              a.startNum = startNum
              a.kind = orderedList
              continue
            else:
              a.listSeq.add(lineBlock.mdToAst.openList)
              if a.isLoose:
                result.add(a.listSeq.openLooseUL)
              else:
                result.add(a.listSeq.openTightUL)
              a = newAttrFlag()
              lineBlock = s
              a.width = n
              a.markerType = marker
              a.kind = unOrderedList
              continue
              
          if a.isAfterEmptyLine:
            if a.isLoose:
              a.listSeq.add(lineBlock.mdToAst.openList)
              if a.kind == unOrderedList:
                result.add(a.listSeq.openLooseUL)
              if a.kind == orderedList:
                result.add(a.listSeq.openLooseOL(a.startNum))
              lineBlock = ""
              a = newAttrFlag()
              break listblock
            else:
              a.listSeq.add(lineBlock.mdToAst.openList)
              if a.kind == unOrderedList:
                result.add(a.listSeq.openTightUL)
              if a.kind == orderedList:
                result.add(a.listSeq.openTightOL(a.startNum))
              lineBlock = ""
              a = newAttrFlag()
              break listblock

          else:

            for i, c in line:

              if i == 0 :
                
                if line.startsWith(reHtmlBlock1Begins) or
                  line.startsWith(reHtmlBlock2Begins) or
                  line.startsWith(reHtmlBlock3Begins) or
                  line.startsWith(reHtmlBlock4Begins) or
                  line.startsWith(reHtmlBlock5Begins) or
                  line.startsWith(reHtmlBlock6Begins) or
                  line.startsWith(reHtmlBlock7Begins1) or
                  line.startsWith(reHtmlBlock7Begins2) or
                  line.countWhitespace < 4 and line.delWhitespace.startsWith(reThematicBreak):
                  a.was = a.kind
                  a.kind = none
                  break

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
                  a.was = a.kind
                  a.kind = paragraph
                  break

                of '>':
                  a.was = a.kind
                  a.kind = blockQuote
                  break

                else: continue
        
          
              case c

              of '#':
                m.numHeading.inc
              
              of ' ':
                if m.numBacktick > 0: m.numBacktick = -128
                if (1..6).contains(m.numHeading):
                  a.was = a.kind
                  a.kind = header
                  break
                else:
                  m.numHeadSpace.inc
                  continue

              of '`':
                m.numBacktick.inc
                if m.numBacktick == 3 and line.match(reFencedCodeBlockBack):
                  a.was = a.kind
                  a.kind = fencedCodeBlockBack
                  break
              
              of '~':
                m.numTild.inc
                if m.numTild >= 3 and line.match(reFencedCodeBlockTild):
                  a.was = a.kind
                  a.kind = fencedCodeBlockTild
                  break

              of '>':
                a.was = a.kind
                a.kind = blockQuote
                break

              else:
                break

            if a.kind == unOrderedList or
               a.kind == orderedList:
              lineBlock.add("\n" & line)
              continue
            else:
              if a.isLoose:
                a.listSeq.add(lineBlock.mdToAst.openList)
                if a.was == unOrderedList:
                  result.add(a.listSeq.openLooseUL)
                if a.was == orderedList:
                  result.add(a.listSeq.openLooseOL(a.startNum))
                lineBlock = ""
                a = newAttrFlag()
                m = newMarkerFlag()
                break listblock
              else:
                a.listSeq.add(lineBlock.mdToAst.openList)
                if a.was == unOrderedList:
                  result.add(a.listSeq.openTightUL)
                if a.was == orderedList:
                  result.add(a.listSeq.openTightOL(a.startNum))
                lineBlock = ""
                a = newAttrFlag()
                m = newMarkerFlag()
                break listblock



    block tableBlock:
      if a.kind == table:
        if line.isEmptyOrWhitespace:
          result.add(openTable(a.align, a.th, a.td))
          a = newAttrFlag()
          continue
        
        else:
          var parsedLine = line.parseTableElement
          a.td.addTableElement(parsedLine, a.columnNum)
          continue




    block iCBblock:
      if a.kind == indentedCodeBlock:
        m.tabNum = line.countTab
        if m.tabNum > 0:
          var tempStr = line
          tempStr.delete(0, m.tabNum-1)
          tempStr = (' ').repeat((m.tabNum-1) * 4) & tempStr
          lineBlock.add("\n" & tempStr)
          continue
        elif (not line.isEmptyOrWhitespace) and
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
      
      if line.startsWith(reHtmlBlock7Begins1) or
         line.startsWith(reHtmlBlock7Begins2):
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
      if m.isAfterNumber > 0:
        m.isAfterNumber.dec
      if m.isAfterOLMarker > 0:
        m.isAfterOLMarker.dec

      if i == 0:

        if line.match(reEmptyUL):
          if a.kind != paragraph:
            a = newAttrFlag()
            a.kind = unOrderedList
            break

        if line.match(reEmptyOL):
          if a.kind != paragraph:
            a = newAttrFlag()
            a.kind = orderedList
            break

        if lineBlock != "" and line.match(reSetextHeader):
          a = newAttrFlag()
          a.kind = setextHeader
          break
        
        if line.countWhitespace < 4 and
            line.delWhitespace.startsWith(reThematicBreak):
          a = newAttrFlag()
          a.kind = thematicBreak
          break
        
        if line.match(reAnotherAtxHeader):
          a = newAttrFlag()
          a.kind = headerEmpty
          break

        if line.isTable:
          a.kind = table
          break

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
          m.tabNum = line.countTab
          if (not line.isEmptyOrWhitespace) and
             line[0] == ' ':
            line.delete(0, 0)
          elif (not line.isEmptyOrWhitespace) and
             m.tabNum > 0:
            line.delete(0, m.tabNum - 1)
            line = (' ').repeat(m.tabNum * 3) & line 
          a = newAttrFlag()
          a.kind = blockQuote
          break

        of '-', '+', '*':
          m.isAfterULMarker = 2
          continue

        of olNum:
          m.isAfterNumber = 2
        
        of '\t':
          a.kind = indentedCodeBlock
          line.delete(0,0)
          line = "    " & line
          break

        else:
          a = newAttrFlag()
          a.kind = paragraph
          break
    
      
      case c

      of '#':
        m.numHeadSpace = 0
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
        elif m.isAfterOLmarker == 1:
          a.kind = orderedList
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
        m.numHeadSpace = 0
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
        m.numHeadSpace = 0
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
        if m.numHeadSpace > 0:
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
        m.numHeadSpace = 0
        if m.isAfterULMarker > 0:
          break
        else:
          m.isAfterULMarker = 2
      
      of olNum:
        m.numHeadSpace = 0
        if m.numHeading == 0 and m.isAfterULMarker == 0:
          m.isAfterNumber = 2
        else:
          a.kind = paragraph
          break

      of '.', ')':
        m.numHeadSpace = 0
        if m.isAfterNumber == 1:
          m.isAfterOLMarker = 2
        else: break

      of '\t':
        if m.isAfterULMarker == 1:
          a.kind = unOrderedList
          break
        elif m.isAfterOLmarker == 1:
          a.kind = orderedList
          break
        elif (1..6).contains(m.numHeading):
          a = newAttrFlag()
          a.kind = header
          break
        elif m.numHeadSpace > 0:
          a.kind = indentedCodeBlock
          m.tabPos = i
          break

      
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

    elif a.kind == unOrderedList:
      let (n, s, marker) = line.delULMarker
      a.width = n
      a.markerType = marker
      if lineBlock != "":
        result.add(openParagraph(lineBlock))
        lineBlock = ""
      lineBlock.add(s)
      continue

    elif a.kind == orderedList:
      let (n, startNum, s, marker) = line.delOLMarker
      if startNum >= 1000000000:
        a = newAttrFlag()
        a.kind = paragraph
        if lineBlock != "":
          lineBlock.add("\n" & line.strip(trailing = false))
          continue
        else:
          lineBlock.add(line.strip(trailing = false))
          continue
      elif startNum != 1 and lineBlock != "":
        a.kind = paragraph
        lineBlock.add("\n" & line.strip(trailing = false))
        continue
      a.markerType = marker
      a.width = n
      a.startNum = startNum
      if lineBlock != "":
        result.add(openParagraph(lineBlock))
        lineBlock = ""
      lineBlock.add(s)
      continue

    elif a.kind == thematicBreak:
      if lineBlock != "":
        result.add(openParagraph(lineBlock))
        lineBlock = ""
      result.add(openthematicBreak())
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
      if lineBlock != "":
        lineBlock.add("\n" & line.strip(trailing = false))
        a.kind = paragraph
      else:
        if m.tabPos > 0:
          line.delete(0, m.tabPos)
        else: line.delete(0, 3)
        lineBlock.add(line)
    
    elif a.kind == blockQuote:
      if lineBlock != "":
        result.add(openParagraph(lineBlock))
      continue

    elif a.kind == table:
      a.align = line.parseTableDelim
      a.columnNum = a.align.len()
      a.th = lineBlock.parseTableElement
      if a.th.len() != a.columnNum:
        a = newAttrFlag()
        a.kind = paragraph
        if lineBlock == "":
          lineBlock.add(line.strip(trailing = false))
        else:
          lineBlock.add("\n" & line.strip(trailing = false))
      else:
        lineBlock = ""
        continue

    elif a.kind == emptyLine:
      if lineBlock != "":
        result.add(openParagraph(lineBlock))
        lineBlock = ""
        a = newAttrFlag()
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
      result.add(openBlockQuote(lineBlock.mdToAst))

    elif a.kind == unOrderedList:
      if a.isLoose:
        a.listSeq.add(lineBlock.mdToAst.openList)
        result.add(a.listSeq.openLooseUL)
      else:
        a.listSeq.add(lineBlock.mdToAst.openList)
        result.add(a.listSeq.openTightUL)

    elif a.kind == orderedList:
      if a.isLoose:
        a.listSeq.add(lineBlock.mdToAst.openList)
        result.add(a.listSeq.openLooseOL(a.startNum))
      else:
        a.listSeq.add(lineBlock.mdToAst.openList)
        result.add(a.listSeq.openTightOL(a.startNum))

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
    
    elif a.kind == table:
      result.add(openTable(a.align, a.th, a.td))

    else:
      result.add(openParagraph(lineBlock))
  
  return result