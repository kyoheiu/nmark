import strutils, sequtils, re
import def

proc mdToAst*(flag:var FlagContainer, lineBLock:var string, mdast:var seq[Block], resultSeq:var seq[Block], line: var string) =
  flag.flagBlockQuoteMarker = false
  flag.flagUnorderedListMarker = false
  flag.flagOrderedListMarker = false

  block unOrderedListBlock:
    if flag.flagUnorderedList:
      if line.hasMarker(reUnorderedList):
        mdast.add(openList(lineBlock))
        lineBlock = ""
        line = line.replace(reUnorderedList)
        flag.flagUnorderedListMarker = true
        break unorderedListBlock
      elif line.hasMarker(reThematicBreak) or line.hasMarker(reOrderedList) or line.hasMarker(reIndentedCodeBlock) or line.hasMarker(reFencedCodeBlockChar) or line.hasMarker(reFencedCodeBlockTild) or line.isEmptyOrWhitespace:
        flag.flagUnorderedList = false
        if lineBlock != "":
          mdast.add(openList(lineBlock))
        resultSeq.add(openContainerBlock(unOrderedList, mdast))
        lineBlock = ""
        mdast = @[]
        flag.flagUnorderedList = false
        break unOrderedListBlock
      
    elif line.hasMarker(reUnorderedList):
      if line.delWhitespace.hasMarker(reThematicBreak):
        break unOrderedListBlock
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      resultSeq = concat(resultSeq, mdast)
      mdast = @[]
      line = line.replace(reUnorderedList)
      flag.flagUnorderedList = true
      flag.flagUnorderedListMarker = true
      break unOrderedListBlock

  block orderedListBlock:
    if flag.flagOrderedList:
      if line.hasMarker(reOrderedList):
        mdast.add(openList(lineBlock))
        lineBlock = ""
        line = line.replace(reOrderedList)
        flag.flagOrderedListMarker = true
        break orderedListBlock
      elif line.hasMarker(reThematicBreak) or line.hasMarker(reUnorderedList) or line.hasMarker(reIndentedCodeBlock) or line.hasMarker(reFencedCodeBlockChar) or line.hasMarker(reFencedCodeBlockTild) or line.isEmptyOrWhitespace:
        flag.flagOrderedList = false
        if lineBlock != "":
          mdast.add(openList(lineBlock))
        resultSeq.add(openContainerBlock(orderedList, mdast))
        lineBlock = ""
        mdast = @[]
        flag.flagOrderedList = false
        break orderedListBlock

    elif line.hasMarker(reOrderedList):
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      resultSeq = concat(resultSeq, mdast)
      mdast = @[]
      line = line.replace(reOrderedList)
      flag.flagOrderedList = true
      flag.flagOrderedListMarker = true
      break orderedListBlock

  block blockQuoteBlock:

    if flag.flagBlockQuote:
      if line.hasMarker(reBlockQuote):
        line = line.replace(reBlockQuote)
        flag.flagBlockQuoteMarker = true
        break blockQuoteBlock
      elif line.hasMarker(reThematicBreak) or line.hasMarker(reUnorderedList) or line.hasMarker(reOrderedList) or line.hasMarker(reIndentedCodeBlock) or line.hasMarker(reFencedCodeBlockChar) or line.hasMarker(reFencedCodeBlockTild) or line.isEmptyOrWhitespace:

        flag.flagBlockQuote = false
        if lineBlock != "":

          var bflag = newFlag()
          var blineBlock: string
          var bmdast: seq[Block]
          var bresultSeq: seq[Block]

          for bline in lineBlock.splitLines:
            var bstr = bline
            mdToAst(bflag, blineBlock, bmdast, bresultSeq, bstr)

          if bflag.flagBlockQuote:
            if blineBlock != "":
              bmdast.add(openParagraph(blineBlock))
            bresultSeq.add(openContainerBlock(blockQuote, bmdast))
            bmdast  = @[]

          elif bflag.flagUnorderedList:
            if blineBlock != "":
              bmdast.add(openList(blineBlock))
            bresultSeq.add(openContainerBlock(unOrderedList, bmdast))
            bmdast  = @[]

          elif bflag.flagOrderedList:
            if blineBlock != "":
              bmdast.add(openList(lineBlock))
            bresultSeq.add(openContainerBlock(orderedList, bmdast))
            bmdast  = @[]
          
          elif blineBlock != "":
            if bflag.flagIndentedCodeBlock:
              bmdast.add(openCodeBlock(indentedCodeBlock, blineBlock))
            else:
              bmdast.add(openParagraph(blineBlock))

          bresultSeq = concat(bresultSeq, bmdast)
          
          resultSeq.add(openContainerBlock(blockQuote, bresultSeq))
        lineBlock = ""
        mdast = @[]
        flag.flagBlockQuote = false
        break blockQuoteBlock

      else:
        lineBlock.add("\n" & line.strip(trailing = false))
        return

    elif line.hasMarker(reBlockQuote):
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      resultSeq = concat(resultSeq, mdast)
      mdast = @[]
      line = line.replace(reBlockQuote)
      flag.flagBlockQuote = true
      flag.flagBlockQuoteMarker = true
      lineBlock.add(line.strip(trailing = false))
      return
        
  block indentedCodeBlocks:
    if flag.flagIndentedCodeBlock:
      if line.hasMarker(reBreakIndentedCode):
        lineBlock.removeSuffix("\n")
        mdast.add(openCodeBlock(indentedCodeBlock, lineBlock))
        lineBlock = ""
        flag.flagIndentedCodeBlock = false
        break indentedCodeBlocks
      else:
        var mutLine = line
        mutLine.delete(0,flag.indentedCodeBlockDepth)
        lineBlock.add("\n" & mutLine)
        return

  if flag.flagFencedCodeBlockChar:
    if line.hasMarker(reFencedCodeBlockChar) and line.countBacktick >= flag.openingFenceLength:
      lineBlock.removeSuffix("\n")
      mdast.add(openCodeBlock(fencedCodeBlock, lineBlock))
      lineBlock = ""
      flag.flagFencedCodeBlockChar = false
    else:
      if line.countWhitespace <= flag.fencedCodeBlocksdepth:
        lineBLock.add(line.strip & "\n")
      else:
        line.delete(0, flag.fencedCodeBlocksdepth - 1)
        lineBlock.add(line & "\n")

  elif flag.flagFencedCodeBlockTild:
    if line.hasMarker(reFencedCodeBlockTild) and line.countBacktick >= flag.openingFenceLength: 
      lineBlock.removeSuffix("\n")
      mdast.add(openCodeBlock(fencedCodeBlock, lineBlock))
      lineBlock = ""
      flag.flagFencedCodeBlockTild = false
    else:
      if line.countWhitespace <= flag.fencedCodeBlocksdepth:
        lineBLock.add(line.strip & "\n")
      else:
        line.delete(0, flag.fencedCodeBlocksdepth - 1)
        lineBlock.add(line & "\n")

  elif flag.flagHtmlBlock1:
    if line.hasMarker(reHtmlBlock1Ends):
      lineBlock.add("\n" & line)
      mdast.add(openHtmlBlock(lineBLock))
      lineBlock = ""
      flag.flagHtmlBlock1 = false
    else:
      lineBlock.add("\n" & line)

  elif flag.flagHtmlBlock2:
    if line.hasMarker(reHtmlBlock2Ends):
      lineBlock.add("\n" & line)
      mdast.add(openHtmlBlock(lineBLock))
      lineBlock = ""
      flag.flagHtmlBlock2 = false
    else:
      lineBlock.add("\n" & line)

  elif flag.flagHtmlBlock3:
    if line.hasMarker(reHtmlBlock2Ends):
      lineBlock.add("\n" & line)
      mdast.add(openHtmlBlock(lineBLock))
      lineBlock = ""
      flag.flagHtmlBlock3 = false
    else:
      lineBlock.add("\n" & line)

  elif flag.flagHtmlBlock4:
    if line.hasMarker(reHtmlBlock2Ends):
      lineBlock.add("\n" & line)
      mdast.add(openHtmlBlock(lineBLock))
      lineBlock = ""
      flag.flagHtmlBlock4 = false
    else:
      lineBlock.add("\n" & line)

  elif flag.flagHtmlBlock5:
    if line.hasMarker(reHtmlBlock2Ends):
      lineBlock.add("\n" & line)
      mdast.add(openHtmlBlock(lineBLock))
      lineBlock = ""
      flag.flagHtmlBlock5 = false
    else:
      lineBlock.add("\n" & line)

  elif flag.flagHtmlBlock6:
    if line.isEmptyOrWhitespace:
      mdast.add(openHtmlBlock(lineBLock))
      lineBlock = ""
      flag.flagHtmlBlock6 = false
    else:
      lineBlock.add("\n" & line)
  
  elif flag.flagHtmlBlock7:
    if line.isEmptyOrWhitespace:
      mdast.add(openHtmlBlock(lineBLock))
      lineBlock = ""
      flag.flagHtmlBlock7 = false
    else:
      lineBlock.add("\n" & line)

  elif flag.flagLinkReference:
    if line.isEmptyOrWhitespace:
      mdast.add(openLinkReference(lineBlock))
    else:
      lineBLock.add(line.strip(trailing = false))

  #elif line.hasMarker(reUnorderedList):
    #if lineBlock != "":
      #mdast.add(openParagraph(lineBlock))
      #lineBlock = ""
    #unorderedListSeq.add(line.replace(reUnorderedListDash))
    #flag.flagUnorderedListDash = true

  #elif line.isUnorderedListPlus:
    #if lineBlock != "":
      #mdast.add(openParagraph(lineBlock))
      #lineBlock = ""
    #unorderedListSeq.add(line.replace(reUnorderedListPlus))
    #flag.flagUnorderedListPlus = true

  #elif line.isUnorderedListAste:
    #if lineBlock != "":
      #mdast.add(openParagraph(lineBlock))
      #lineBlock = ""
    #unorderedListSeq.add(line.replace(reUnorderedListAste))
    #flag.flagUnorderedListAste = true
  
  #elif line.hasMarker(reOrderedListSpaceStart):
    #if lineBlock != "":
      #mdast.add(openParagraph(lineBlock))
      #lineBlock = ""
    #orderedListSeq.add(line.replace(reOrderedListSpaceStart))
    #flag.flagOrderedListSpace = true

  #elif line.hasMarker(reOrderedListPareStart):
    #if lineBlock != "":
      #mdast.add(openParagraph(lineBlock))
      #lineBlock = ""
    #orderedListSeq.add(line.replace(reOrderedListPareStart))
    #flag.flagOrderedListPare = true

  elif line.hasMarker(reIndentedCodeBlock):
    if lineBlock == "":
      flag.indentedCodeBlockDepth = line.countWhitespace - 1
      flag.flagIndentedCodeBlock = true
      var mutLine = line
      mutLine.delete(0,flag.indentedCodeBlockDepth)
      lineBlock.add(mutLine)
    else:
      lineBlock.add("\n" & line.strip(trailing = false))

  elif line.hasMarker(reFencedCodeBlockChar):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
      lineBlock = ""
    flag.flagFencedCodeBlockChar = true
    flag.openingFenceLength = line.countBacktick
    flag.fencedCodeBlocksdepth = line.countWhitespace

  elif line.hasMarker(reFencedCodeBlockTild):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
      lineBlock = ""
    flag.flagFencedCodeBlockTild = true
    flag.openingFenceLength = line.countBacktick
    flag.fencedCodeBlocksdepth = line.countWhitespace
  
  elif line.hasMarker(reHtmlBlock1Begins):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
      lineBlock = ""
    if not flag.flagBlockQuote:
      flag.flagHtmlBlock1 = true
      lineBlock.add(line)
 
  elif line.hasMarker(reHtmlBlock2Begins):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
      lineBlock = ""
    if not flag.flagBlockQuote:
      flag.flagHtmlBlock2 = true
      lineBlock.add(line)
  
  elif line.hasMarker(reHtmlBlock3Begins):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
      lineBlock = ""
    if not flag.flagBlockQuote:
      flag.flagHtmlBlock3 = true
      lineBlock.add(line)
  
  elif line.hasMarker(reHtmlBlock4Begins):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
      lineBlock = ""
    if not flag.flagBlockQuote:
      flag.flagHtmlBlock4 = true
      lineBlock.add(line)
  
  elif line.hasMarker(reHtmlBlock5Begins):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
      lineBlock = ""
    if not flag.flagBlockQuote:
      flag.flagHtmlBlock5 = true
      lineBlock.add(line)
  
  
  elif line.hasMarker(reHtmlBlock6Begins):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
      lineBlock = ""
    if not flag.flagBlockQuote:
      flag.flagHtmlBlock6 = true
      lineBlock.add(line)
  
  elif line.hasMarker(reHtmlBlock7Begins):
    if lineBlock == "" and not flag.flagBlockQuote:
      flag.flagHtmlBlock7 = true
      lineBlock.add(line)

  elif line.hasMarker(reAtxHeader):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
    mdast.add(openAtxHeader(line))
    lineBlock = ""
  
  elif line.hasMarker(reAnotherAtxHeader):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
    mdast.add(openAtxHeader(line))
    lineBlock = ""
  
  elif line.hasMarker(reBreakOrHeader):
    if lineBlock != "":
      mdast.add(openSetextHeader(header2, lineBlock))
      lineBlock = ""
    else:
      mdast.add(openThemanticBreak())

  elif line.delWhitespace.hasMarker(reThematicBreak):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
      lineBlock = ""
    mdast.add(openThemanticBreak())

  elif line.hasMarker(reSetextHeader1):
    if lineBlock == "":
      lineBlock.add(line)
    else:
      mdast.add(openSetextHeader(header1, lineBlock))
      lineBlock = ""

  elif line.hasMarker(reLinkLabel):
    if lineBlock != "":
      lineBlock.add("\n" & line.strip(trailing = false))
    else:
      flag.flagLinkReference = true
      lineBlock.add("\n" & line.strip(trailing = false))

  elif line.isEmptyOrWhitespace:
    if flag.flagBlockQuote:
      if flag.flagBlockQuoteMarker:
        return
      else:
        if lineBlock != "":
          mdast.add(openParagraph(lineBlock))
        resultSeq.add(openContainerBlock(blockQuote, mdast))
        lineBlock = ""
        mdast = @[]
        flag.flagBlockQuote = false
        flag.flagHtmlBlock6 = false
        flag.flagHtmlBlock7 = false
    if flag.flagUnorderedList:
      if flag.flagUnorderedListMarker:
        return
      else:
        if lineBlock != "":
          mdast.add(openParagraph(lineBlock))
        resultSeq.add(openContainerBlock(blockQuote, mdast))
        lineBlock = ""
        mdast = @[]
        flag.flagUnorderedList = false
    if flag.flagOrderedList:
      if flag.flagOrderedListMarker:
        return
      else:
        if lineBlock != "":
          mdast.add(openParagraph(lineBlock))
        resultSeq.add(openContainerBlock(blockQuote, mdast))
        lineBlock = ""
        mdast = @[]
        flag.flagOrderedList = false
    elif flag.flagHtmlBlock6:
        mdast.add(openHtmlBlock(lineBlock))
        lineBlock = ""
        flag.flagHtmlBlock6 = false
    elif flag.flagHtmlBlock7:
        mdast.add(openHtmlBlock(lineBlock))
        lineBlock = ""
        flag.flagHtmlBlock7 = false
    elif lineBlock != "":
      mdast.add(openParagraph(lineBlock))
      lineBlock = ""
      return
    else:
      return

  else:
    if lineBlock != "":
      lineBlock.add("\n" & line.strip(trailing = false))
    else:
      lineBlock.add(line.strip(trailing = false))