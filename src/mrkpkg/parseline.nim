import strutils, sequtils, re, def

proc parseLine*(line: var string) =
  flag.flagBlockQuoteMarker = false

  block unorderedListDashBlock:
    if flag.flagUnorderedListDash:
      if line.hasMarker(reUnorderedListDash):
        unorderedListSeq.add(line.replace(reUnorderedListDash))
      else:
        mdast.add(openContainerBlock(unOrderedList, unorderedListSeq))
        unorderedListSeq = @[]
        flag.flagUnorderedListDash = false
        break unorderedListDashBlock

  block orderedListDashSpaceBlock:
    if flag.flagOrderedListSpace:
      if line.hasMarker(reOrderedListSpaceStart):
        orderedListSeq.add(line.replace(reOrderedListSpace))
      else:
        mdast.add(openContainerBlock(orderedList, orderedListSeq))
        orderedListSeq = @[]
        flag.flagOrderedListSpace = false
        break orderedListDashSpaceBlock

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

  block blockQuoteBlock:
    if flag.flagBlockQuote:
      if line.hasMarker(reBlockQuote):
        line = line.replace(reBlockQuote)
        flag.flagBlockQuoteMarker = true
      break blockQuoteBlock
    if line.hasMarker(reBlockQuote):
      if lineBlock != "":
        mdast.add(openParagraph(lineBlock))
        lineBlock = ""
      resultSeq = concat(resultSeq, mdast)
      mdast = @[]
      line = line.replace(reBlockQuote)
      flag.flagBlockQuote = true
      flag.flagBlockQuoteMarker = true
      break blockQuoteBlock
        
  if flag.flagFencedCodeBlock:
    if not line.hasMarker(reFencedCodeBlock):
      lineBlock.add(line & "\n")
    else:
      lineBlock.removeSuffix("\n")
      mdast.add(openCodeBlock(fencedCodeBlock, lineBlock))
      lineblock = ""
      flag.flagFencedCodeBlock = false

  elif line.hasMarker(reUnorderedListDash):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
      lineBlock = ""
    unorderedListSeq.add(line.replace(reUnorderedListDash))
    flag.flagUnorderedListDash = true

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
  
  elif line.hasMarker(reOrderedListSpaceStart):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
      lineBlock = ""
    orderedListSeq.add(line.replace(reOrderedListSpaceStart))
    flag.flagOrderedListSpace = true

  elif line.hasMarker(reOrderedListPareStart):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
      lineBlock = ""
    orderedListSeq.add(line.replace(reOrderedListPareStart))
    flag.flagOrderedListPare = true

  elif line.hasMarker(reIndentedCodeBlock):
    if lineBlock == "":
      flag.indentedCodeBlockDepth = line.countWhitespace - 1
      flag.flagIndentedCodeBlock = true
      var mutLine = line
      mutLine.delete(0,flag.indentedCodeBlockDepth)
      lineBlock.add(mutLine)

  elif line.hasMarker(reFencedCodeBlock):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
      lineBlock = ""
    flag.flagFencedCodeBlock = true
  
  elif line.hasMarker(reAtxHeader):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
    mdast.add(openAtxHeader(line))
    lineBlock = ""
  
  elif line.hasMarker(reSetextHeader1):
    if lineBlock == "":
      lineBlock.add(line)
    else:
      mdast.add(openSetextHeader(header1, lineBlock))
      lineBlock = ""
  
  elif line.hasMarker(reSetextHeader2):
    if lineBlock != "":
      mdast.add(openSetextHeader(header2, lineBlock))
      lineBlock = ""
    else:
      mdast.add(openThemanticBreak())
  
  elif line.hasMarker(reThematicBreak):
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
      lineBlock = ""
    mdast.add(openThemanticBreak())

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
    if not lineBlock.isEmptyOrWhitespace:
      mdast.add(openParagraph(lineBlock))
      lineBlock = ""

  else:
    if lineBlock != "":
      line = "\n" & line
    lineBlock.add(line)