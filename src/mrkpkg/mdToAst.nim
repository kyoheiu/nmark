import strutils, sequtils, re, def

proc mdToAst*(flag:var FlagContainer, lineBLock:var string, mdast:var seq[Block], resultSeq:var seq[Block], line: var string) =
  flag.flagBlockQuoteMarker = false

  #block unorderedListDashBlock:
    #if flag.flagUnorderedListDash:
      #if line.hasMarker(reUnorderedListDash):
        #unorderedListSeq.add(line.replace(reUnorderedListDash))
      #else:
        #mdast.add(openContainerBlock(unOrderedList, unorderedListSeq))
        #unorderedListSeq = @[]
        #flag.flagUnorderedListDash = false
        #break unorderedListDashBlock

  #block orderedListDashSpaceBlock:
    #if flag.flagOrderedListSpace:
      #if line.hasMarker(reOrderedListSpaceStart):
        #orderedListSeq.add(line.replace(reOrderedListSpace))
      #else:
        #mdast.add(openContainerBlock(orderedList, orderedListSeq))
        #orderedListSeq = @[]
        #flag.flagOrderedListSpace = false
        #break orderedListDashSpaceBlock

  block blockQuoteBlock:
    if flag.flagBlockQuote:
      if line.hasMarker(reBlockQuote):
        line = line.replace(reBlockQuote)
        flag.flagBlockQuoteMarker = true
        break blockQuoteBlock
      elif line.hasMarker(reThematicBreak) or line.hasMarker(reUnorderedListDash) or line.hasMarker(reIndentedCodeBlock) or line.hasMarker(reFencedCodeBlockChar) or line.hasMarker(reFencedCodeBlockTild) or line.isEmptyOrWhitespace:
        flag.flagBlockQuote = false
        if lineBlock != "":
          mdast.add(openParagraph(lineBlock))
        resultSeq.add(openQuoteBlock(mdast))
        lineBlock = ""
        mdast = @[]
        flag.flagBlockQuote = false
        break blockQuoteBlock
    elif line.hasMarker(reBlockQuote):
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      resultSeq = concat(resultSeq, mdast)
      mdast = @[]
      line = line.replace(reBlockQuote)
      flag.flagBlockQuote = true
      flag.flagBlockQuoteMarker = true
      break blockQuoteBlock
        
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

  #elif line.hasMarker(reUnorderedListDash):
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
        resultSeq.add(openQuoteBlock(mdast))
        lineBlock = ""
        mdast = @[]
        flag.flagBlockQuote = false
        flag.flagHtmlBlock6 = false
        flag.flagHtmlBlock7 = false
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