import strutils, sequtils, re
import defBlock

type
  MarkerFlag* = ref MFObj
  MFObj = object
    numHeadSpace: int
    numHeading: int
    numBacktick: int
    numTild: int
    numOpenfence: int
    numQuote: int
    numEmptyLine: int
    isAfterEmptyLine: bool
    attr: string
    kind: BlockType
    width: int
  
proc newMarkerFlag(): MarkerFlag =
  MarkerFlag(
    numHeadSpace: 0,
    numHeading: 0,
    numBacktick: 0,
    numTild: 0,
    numOpenfence: 0,
    numQuote: 0,
    numEmptyLine: 0,
    isAfterEmptyLine: false,
    attr: "",
    kind: none,
    width: 0
  )



proc parseLines*(s: string): seq[Block] =

  var m = newMarkerFlag()
  var lineBlock: string

  for str in s.splitLines:
    var line = str



    block bqblock:
      if m.kind == blockQuote:

        if line.isEmptyOrWhitespace:
          result.add(openBlockQuote(lineBlock.parseLines))
          lineBlock = ""
          m = newMarkerFlag()
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
            m.kind = none
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
              m.kind = paragraph
              break

            of '>':
              line.delete(0, 0)
              if (not line.isEmptyOrWhitespace) and
                line[0] == ' ':
                line.delete(0, 0)
              if line.isEmptyOrWhitespace:
                m.isAfterEmptyLine = true
                break
              else:
                m.isAfterEmptyLine = false
                break

            else: continue
    
      
          case c

          of '#':
            m.numHeading.inc
          
          of ' ':
            if m.numBacktick > 0: m.numBacktick = -128
            if (1..6).contains(m.numHeading):
              m = newMarkerFlag()
              m.kind = header
              break
            else:
              m.numHeadSpace.inc
              if m.numHeadSpace == 4:
                m.kind = indentedCodeBlock
                break

          of '`':
            m.numBacktick.inc
            if m.numBacktick == 3 and line.match(reFencedCodeBlockBack):
              m = newMarkerFlag()
              let rem = line.delSpaceAndFence
              if rem != "":
                m.attr = rem.takeAttr
              m.width = line.countWhitespace
              m.numOpenfence = line.countBacktick
              m.kind = fencedCodeBlockBack
              break
          
          of '~':
            m.numTild.inc
            if m.numTild >= 3 and line.match(reFencedCodeBlockTild):
              m = newMarkerFlag()
              let rem = line.delSpaceAndFence
              if rem != "":
                m.attr = rem.splitWhitespace[0]
              m.width = line.countWhitespace
              m.numOpenfence = line.countTild
              m.kind = fencedCodeBlockTild
              break

          of '>':
            line.delete(0, i)
            if (not line.isEmptyOrWhitespace) and
              line[0] == ' ':
              line.delete(0, 0)
            if line.isEmptyOrWhitespace:
              m.isAfterEmptyLine = true
              break
            else:
              m.isAfterEmptyLine = false
              break

          else:
            if m.isAfterEmptyLine: m.kind = paragraph
            break

        if m.kind == blockQuote:
          lineBlock.add("\n" & line)
          continue
        else:
          result.add(openBlockQuote(lineBlock.parseLines))
          lineBlock = ""
          m = newMarkerFlag()
          break bqblock





    block iCBblock:
      if m.kind == indentedCodeBlock:
        if (not line.isEmptyOrWhitespace) and
          line.countWhitespace < 4:
          if m.numEmptyLine != 0:
            var s = lineBlock.splitLines
            let l = s.len() - 1
            s.delete(l - m.numEmptyLine + 1, l)
            lineBlock = s.join("\n")
          result.add(openCodeBlock(indentedCodeBlock, "", lineBlock))
          lineBlock = ""
          m.numEmptyLine = 0
          m.kind = none
          break iCBblock
        elif line.isEmptyOrWhiteSpace:
          m.numEmptyLine.inc
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
          m.numEmptyLine = 0
          continue



    block fencedCodeBackblock:
      if m.kind == fencedCodeBlockBack:
        let rem = line.delSpaceAndFence

        if rem != "":
          let numWS = line.countWhitespace
          if numWS >= m.width:
            line.delete(0, m.width - 1)
          if numWS > 0 and
               numWS < m.width:
            line.removePrefix(' ')
          lineBlock.add(line & "\n")
          continue

        elif line.match(reFencedCodeBlockBack) and
            line.countBacktick >= m.numOpenfence:
          lineBlock.removeSuffix("\n")
          result.add(openCodeBlock(fencedCodeBlock, m.attr, lineBlock))
          lineBlock = ""
          m = newMarkerFlag()
          continue

        else:
          let numWS = line.countWhitespace
          if numWS >= m.width:
            line.delete(0, m.width - 1)
          if numWS > 0 and
               numWS < m.width:
            line.removePrefix(' ')
          lineBlock.add(line & "\n")
          continue



    block fencedCodeTildblock:
      if m.kind == fencedCodeBlockTild:
        if line.match(reFencedCodeBlockTild) and
            line.countTild >= m.numOpenfence:
          lineBlock.removeSuffix("\n")
          result.add(openCodeBlock(fencedCodeBlock, m.attr, lineBlock))
          lineBlock = ""
          m = newMarkerFlag()
          continue
        else:
          let numWS = line.countWhitespace
          if numWS >= m.width:
            line.delete(0, m.width - 1)
          if numWS > 0 and
               numWS < m.width:
            line.removePrefix(' ')
          lineBlock.add(line & "\n")
          continue


    # html block
    block hblock:

      if m.kind == htmlBlock1:
        if line.contains(reHtmlBlock1Ends):
          lineBlock.add("\n" & line)
          result.add(openHTML(lineBlock))
          lineBlock = ""
          m = newMarkerFlag()
          continue
        else:
          lineBlock.add("\n" & line)
          continue

      if m.kind == htmlBlock2:
        if line.contains(reHtmlBlock2Ends):
          lineBlock.add("\n" & line)
          result.add(openHTML(lineBlock))
          lineBlock = ""
          m = newMarkerFlag()
          continue
        else:
          lineBlock.add("\n" & line)
          continue

      if m.kind == htmlBlock3:
        if line.contains(reHtmlBlock3Ends):
          lineBlock.add("\n" & line)
          result.add(openHTML(lineBlock))
          lineBlock = ""
          m = newMarkerFlag()
          continue
        else:
          lineBlock.add("\n" & line)
          continue

      if m.kind == htmlBlock4:
        if line.contains(reHtmlBlock4Ends):
          lineBlock.add("\n" & line)
          result.add(openHTML(lineBlock))
          lineBlock = ""
          m = newMarkerFlag()
          continue
        else:
          lineBlock.add("\n" & line)
          continue

      if m.kind == htmlBlock5:
        if line.contains(reHtmlBlock5Ends):
          lineBlock.add("\n" & line)
          result.add(openHTML(lineBlock))
          lineBlock = ""
          m = newMarkerFlag()
          continue
        else:
          lineBlock.add("\n" & line)
          continue

      if m.kind == htmlBlock6:
        if line.isEmptyOrWhitespace:
          result.add(openHTML(lineBlock))
          lineBlock = ""
          m = newMarkerFlag()
          continue
        else:
          lineBlock.add("\n" & line)
          continue

      if m.kind == htmlBlock7:
        if line.isEmptyOrWhitespace:
          result.add(openHTML(lineBlock))
          lineBlock = ""
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
          m.kind = htmlBlock1
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
          m.kind = htmlBlock2
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
          m.kind = htmlBlock3
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
          m.kind = htmlBlock4
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
          m.kind = htmlBlock5
          lineBlock.add(line)
          continue
      
      if line.startsWith(reHtmlBlock6Begins):
        if lineBlock != "":
          result.add(openParagraph(lineBlock))
          lineBlock = ""
        m.kind = htmlBlock6
        lineBlock.add(line)
        continue
      
      if line.startsWith(reHtmlBlock7Begins):
        if lineBlock != "":
          lineBlock.add("\n" & line.strip(trailing = false))
          continue
        else:
          m.kind = htmlBlock7
          lineBlock.add(line)
          continue
      


    #check for marker begins
    for i, c in line:



      if lineBlock != "" and line.match(reSetextHeader):
        m.kind = setextHeader
        break
      
      elif line.countWhitespace < 4 and
           line.delWhitespace.startsWith(reThematicBreak):
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

        of '`':
          m.numBacktick = 1

        of '~':
          m.numTild = 1
        
        of '\\':
          m.kind = paragraph
          break

        of '>':
          if m.kind == paragraph:
            result.add(openParagraph(lineBlock))
            lineBlock = ""
          line.delete(0, i)
          if (not line.isEmptyOrWhitespace) and
             line[0] == ' ':
            line.delete(0, 0)
          m.kind = blockQuote
          break

        else: continue
    
      
      case c

      of '#':
        m.numHeading.inc
      
      of ' ':
        if m.numBacktick > 0: m.numBacktick = -128
        if (1..6).contains(m.numHeading):
          m = newMarkerFlag()
          m.kind = header
          break
        else:
          m.numHeadSpace.inc
          if m.numHeadSpace == 4 and m.kind != paragraph:
            m = newMarkerFlag()
            m.kind = indentedCodeBlock
            break
          elif m.numHeadSpace == 4 and m.kind == paragraph:
            break

      of '`':
        m.numBacktick.inc
        if m.numBacktick == 3 and line.match(reFencedCodeBlockBack):
          m = newMarkerFlag()
          let rem = line.delSpaceAndFence
          if rem != "":
            m.attr = rem.takeAttr
          m.width = line.countWhitespace
          m.numOpenfence = line.countBacktick
          m.kind = fencedCodeBlockBack
          break
      
      of '~':
        m.numTild.inc
        if m.numTild >= 3 and line.match(reFencedCodeBlockTild):
          m = newMarkerFlag()
          let rem = line.delSpaceAndFence
          if rem != "":
            m.attr = rem.splitWhitespace[0]
          m.width = line.countWhitespace
          m.numOpenfence = line.countTild
          m.kind = fencedCodeBlockTild
          break

      of '>':
        if lineBlock != "":
          result.add(openParagraph(lineBlock))
          lineBlock = ""
        line.delete(0, i)
        if not line.isEmptyOrWhitespace and
            line[0] == ' ':
          line.delete(0, 0)
        m.kind = blockQuote
        break

      else:
        m = newMarkerFlag()
        m.kind = paragraph
        break



    if m.kind != blockQuote and line.isEmptyOrWhitespace:
      m.kind = emptyLine

    if m.kind == none:
      m.kind = paragraph
    #check for marker ends



    #line-adding begins
    if m.kind == fencedCodeBlockBack or
       m.kind == fencedCodeBlockTild:
      if lineBlock != "":
        result.add(openParagraph(lineBlock))
        lineBlock = ""
      continue

    elif m.kind == blockQuote:
      lineBlock.add(line)
      continue


    elif m.kind == themanticBreak:
      if lineBlock != "":
        result.add(openParagraph(lineBlock))
        lineBlock = ""
      result.add(openThemanticBreak())
      m.kind = none

    elif m.kind == header:
      if lineBlock != "":
        result.add(openParagraph(lineBlock))
        lineBlock = ""
      result.add(openAtxHeader(line))
      m.kind = none
    
    elif m.kind == headerEmpty:
      if lineBlock != "":
        result.add(openParagraph(lineBlock))
        lineBlock = ""
      result.add(openAnotherAtxHeader(line))
      m.kind = none
    
    elif m.kind == setextHeader:
      if lineBlock == "":
        lineBlock.add(line)
        m.kind = paragraph
      else:
        var n: int
        if line.contains('='): n = 1
        else: n = 2
        result.add(openSetextHeader(n, lineBlock.strip(chars = {' ', '\t'})))
        lineBlock = ""
        m.kind = none
      
    elif m.kind == indentedCodeBlock:
      if lineBlock == "":
        line.delete(0, 3)
        lineBlock.add(line)
      else:
        lineBlock.add("\n" & line.strip(trailing = false))
    
    elif m.kind == blockQuote:
      if lineBlock != "":
        result.add(openParagraph(lineBlock))
      continue

    elif m.kind == emptyLine:
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
        m = newMarkerFlag()
        continue
      else:
        m = newMarkerFlag()
        continue

    elif m.kind == paragraph:
      if lineBlock != "":
        lineBlock.add("\n" & line.strip(trailing = false))
      else:
        lineBlock.add(line.strip(trailing = false))
    #line-adding ends


  #after EOF

  if m.kind == blockQuote:
    result.add(openBlockQuote(lineBlock.parseLines))
    return result

  if lineBlock != "":
    if m.kind == fencedCodeBlockBack or
      m.kind == fencedCodeBlockTild:
      lineBlock.removeSuffix('\n')
      result.add(openCodeBlock(fencedCodeBlock, m.attr, lineBlock))
    
    elif m.kind == indentedCodeBlock:
      if m.numEmptyLine != 0:
        var s = lineBlock.splitLines
        let l = s.len() - 1
        s.delete(l - m.numEmptyLine + 1, l)
        lineBlock = s.join("\n")
      result.add(openCodeBlock(indentedCodeBlock, "", lineBlock))

    elif m.kind == htmlBlock1:
      lineBlock.removeSuffix("\n")
      result.add(openHTML(lineBlock))

    else:
      result.add(openParagraph(lineBlock))
  
  return result