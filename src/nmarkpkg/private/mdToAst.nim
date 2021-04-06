import strutils, sequtils, re
import defBlock

proc mdToAst*(s: string): seq[Block] =

  var flag = newFlag()
  var lineBlock: string
  var mdast: seq[Block]
  var resultSeq: seq[Block]

  for str in s.splitLines:
    var line = str

    flag.flagUnorderedListMarker = false
    flag.flagOrderedListMarker = false

    block unOrderedListBlock:

      if flag.flagUnorderedList:
        if line.countWhitespace >= flag.uldepth:
          if flag.hasEmptyLine: flag.looseUnordered = true
          line.delete(0,flag.uldepth - 1)
          lineBlock.add("\n" & line)
          flag.afterEmptyLine = false
          continue

        elif line.hasMarker(reTabStart):
          let tabAsSpace = line.countTab * 4
          if tabAsSpace >= flag.uldepth:
            if flag.hasEmptyLine: flag.looseUnordered = true
            line = repeat(" ", tabAsSpace - flag.uldepth) & line.delWhitespaceAndTab
            lineBlock.add("\n" & line)
            flag.afterEmptyLine = false
            continue
          else:
            if not flag.afterEmptyLine:
              lineBlock.add("\n" & line.strip(trailing = false))
              continue
            else:
              flag.afterEmptyLine = false
              mdast.add(lineBlock.mdToAst.openList)
              if flag.looseUnordered: resultSeq.add(mdast.openLooseUL)
              else: resultSeq.add(mdast.openTightUL)
              lineBlock = ""
              mdast = @[]
              flag.flagUnorderedList = false
              flag.looseUnordered = false
              flag.hasEmptyLine = false
              flag.uldepth = 0
              break unOrderedListBlock

        elif line.hasMarker(reUnorderedList):
          if flag.afterEmptyLine: flag.looseUnordered = true
          flag.afterEmptyLine = false
          mdast.add(lineBlock.mdToAst.openList)
          lineBlock = ""
          flag.uldepth = line.matchLen(reUnorderedList)
          line = line.replace(reUnorderedList)
          flag.flagUnorderedListMarker = true
          break unOrderedListBlock
        elif line.isEmptyOrWhitespace:
          lineBlock.add("\n")
          flag.hasEmptyLine = true
          flag.afterEmptyLine = true
          continue
        else:
          if not flag.afterEmptyLine:
            lineBlock.add("\n" & line.strip(trailing = false))
            continue
          else:
            flag.afterEmptyLine = false
            mdast.add(lineBlock.mdToAst.openList)
            if flag.looseUnordered: resultSeq.add(mdast.openLooseUL)
            else: resultSeq.add(mdast.openTightUL)
            lineBlock = ""
            mdast = @[]
            flag.flagUnorderedList = false
            flag.looseUnordered = false
            flag.hasEmptyLine = false
            flag.uldepth = 0
            break unOrderedListBlock
        
      elif line.hasMarker(reUnorderedList):
        if line.delWhitespace.hasMarker(reThematicBreak):
          break unOrderedListBlock
        if lineBlock != "":
          if flag.flagBlockQuote:
            resultSeq.add(openBlockQuote(lineBlock.mdToAst))
            flag.flagBlockQuote = false
          else:
            mdast.add(openParagraph(lineBlock))
        resultSeq = concat(resultSeq, mdast)
        lineBlock = ""
        mdast = @[]
        flag.uldepth = line.matchLen(reUnorderedList)
        line = line.replace(reUnorderedList)
        flag.flagUnorderedList = true
        flag.flagUnorderedListMarker = true
        break unOrderedListBlock



    block orderedListBlock:

      if flag.flagOrderedList:
        if line.countWhitespace >= flag.oldepth:
          if flag.hasEmptyLine: flag.looseOrdered = true
          line.delete(0,flag.oldepth - 1)
          lineBlock.add("\n" & line)
          flag.afterEmptyLine = false
          continue

        elif line.hasMarker(reTabStart):
          let tabAsSpace = line.countTab * 4
          if tabAsSpace >= flag.oldepth:
            if flag.hasEmptyLine: flag.looseOrdered = true
            line = repeat(" ", tabAsSpace - flag.oldepth) & line.delWhitespaceAndTab
            lineBlock.add("\n" & line)
            flag.afterEmptyLine = false
            continue
          else:
            if not flag.afterEmptyLine:
              lineBlock.add("\n" & line.strip(trailing = false))
              continue
            else:
              flag.afterEmptyLine = false
              mdast.add(lineBlock.mdToAst.openList)
              if flag.looseOrdered: resultSeq.add(mdast.openLooseOL)
              else: resultSeq.add(mdast.openTightOL)
              lineBlock = ""
              mdast = @[]
              flag.flagOrderedList = false
              flag.looseOrdered = false
              flag.hasEmptyLine = false
              flag.oldepth = 0
              break orderedListBlock

        elif line.hasMarker(reOrderedList):
          if flag.afterEmptyLine: flag.looseOrdered = true
          flag.afterEmptyLine = false
          mdast.add(lineBlock.mdToAst.openList)
          lineBlock = ""
          flag.oldepth = line.matchLen(reOrderedList)
          line = line.replace(reOrderedList)
          flag.flagOrderedListMarker = true
          break orderedListBlock
        elif line.isEmptyOrWhitespace:
          lineBlock.add("\n")
          flag.hasEmptyLine = true
          flag.afterEmptyLine = true
          continue
        else:
          if not flag.afterEmptyLine:
            lineBlock.add("\n" & line.strip(trailing = false))
            continue
          else:
            flag.afterEmptyLine = false
            mdast.add(lineBlock.mdToAst.openList)
            if flag.looseOrdered: resultSeq.add(mdast.openLooseOL)
            else: resultSeq.add(mdast.openTightOL)
            lineBlock = ""
            mdast = @[]
            flag.flagOrderedList = false
            flag.looseOrdered = false
            flag.hasEmptyLine = false
            flag.oldepth = 0
            break orderedListBlock
        
      elif line.hasMarker(reOrderedList):
        if lineBlock != "":
          if flag.flagBlockQuote:
            resultSeq.add(openBlockQuote(lineBlock.mdToAst))
            flag.flagBlockQuote = false
          else:
            mdast.add(openParagraph(lineBlock))
        resultSeq = concat(resultSeq, mdast)
        lineBlock = ""
        mdast = @[]
        flag.oldepth = line.matchLen(reOrderedList)
        line = line.replace(reOrderedList)
        flag.flagOrderedList = true
        flag.flagOrderedListMarker = true
        break orderedListBlock



    block bqBlock:

      if flag.flagBlockQuote:
        if line.hasMarker(reThematicBreak) or line.hasMarker(reUnorderedList) or line.hasMarker(reOrderedList) or line.hasMarker(reIndentedCodeBlock) or line.hasMarker(reFencedCodeBlockChar) or line.hasMarker(reFencedCodeBlockTild) or line.isEmptyOrWhitespace:

          resultSeq.add(openBlockQuote(lineBlock.mdToAst))
          lineBlock = ""
          mdast = @[]
          flag.flagBlockQuote = false
          break bqBlock

        else:
          if line.hasMarker(reBlockQuote):
            line = line.replace(reBlockQuote)
          lineBlock.add("\n" & line.strip(trailing = false))
          continue

      elif line.hasMarker(reBlockQuoteTab):
        if lineBlock != "":
          if flag.flagIndentedCodeBlock:
            lineBlock.removeSuffix("\n")
            mdast.add(openCodeBlock(indentedCodeBlock, lineBlock))
            lineBlock = ""
            flag.flagIndentedCodeBlock = false
          else: mdast.add(openParagraph(lineBlock))
          lineBlock = ""
        resultSeq = concat(resultSeq, mdast)
        mdast = @[]
        line = line.replace(reBlockQuoteTab)
        line = repeat("   ", line.countTab + 1) & line
        echo line
        flag.flagBlockQuote = true
        lineBlock.add(line.strip(trailing = false))
        continue

      elif line.hasMarker(reBlockQuote):
        if lineBlock != "":
          if flag.flagIndentedCodeBlock:
            lineBlock.removeSuffix("\n")
            mdast.add(openCodeBlock(indentedCodeBlock, lineBlock))
            lineBlock = ""
            flag.flagIndentedCodeBlock = false
          else: mdast.add(openParagraph(lineBlock))
          lineBlock = ""
        resultSeq = concat(resultSeq, mdast)
        mdast = @[]
        line = line.replace(reBlockQuote)
        flag.flagBlockQuote = true
        lineBlock.add(line.strip(trailing = false))
        continue
          


    block indentedCBlock:
      if flag.flagIndentedCodeBlock:
        if (not line.isEmptyOrWhitespace) and line.countWhitespace < 4:
          lineBlock.removeSuffix("\n")
          mdast.add(openCodeBlock(indentedCodeBlock, lineBlock))
          lineBlock = ""
          flag.flagIndentedCodeBlock = false
          break indentedCBlock
        elif line.isEmptyOrWhiteSpace:
          lineBlock.add("\n")
          continue
        else:
          line.delete(0,flag.indentedCodeBlockDepth)
          lineBlock.add("\n" & line)
          continue



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

    elif line.hasMarker(reIndentedCodeBlock):
      if lineBlock == "":
        flag.indentedCodeBlockDepth = line.countWhitespace - 1
        flag.flagIndentedCodeBlock = true
        line.delete(0, 3)
        lineBlock.add(line)
        echo lineBlock
      else:
        lineBlock.add("\n" & line.strip(trailing = false))

    elif line.hasMarker(reTabStart):
      if lineBlock == "":
        flag.indentedCodeBlockDepth = 3 
        flag.flagIndentedCodeBlock = true
        lineBlock.add(line.deleteUntilTab)
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

    elif line.isEmptyOrWhitespace:
      if flag.flagUnorderedList:
        continue
      if flag.flagOrderedList:
        continue
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
        continue
      else:
        continue

    else:
      if lineBlock != "":
        lineBlock.add("\n" & line.strip(trailing = false))
      else:
        lineBlock.add(line.strip(trailing = false))
# loop ends


  if flag.flagBlockQuote:
    if lineBlock != "":
      resultSeq.add(openBlockQuote(lineBlock.mdToAst))
    return resultSeq

  elif flag.flagUnorderedList:
    if lineBlock != "":
      mdast.add(lineBlock.mdToAst.openList)
    if flag.looseUnordered: resultSeq.add(mdast.openLooseUL)
    else: resultSeq.add(mdast.openTightUL)
    return resultSeq

  elif flag.flagOrderedList:
    if lineBlock != "":
      mdast.add(lineBlock.mdToAst.openList)
    if flag.looseOrdered: resultSeq.add(mdast.openLooseOL)
    else: resultSeq.add(mdast.openTightOL)
    return resultSeq

  elif flag.flagIndentedCodeBlock:
    lineBlock.removeSuffix("\n")
    mdast.add(openCodeBlock(indentedCodeBlock, lineBlock))

  elif flag.flagHtmlBlock6:
      mdast.add(openHtmlBlock(lineBlock))
  elif flag.flagHtmlBlock7:
      mdast.add(openHtmlBlock(lineBlock))
  
  elif lineBlock != "":
    if flag.flagIndentedCodeBlock:
      mdast.add(openCodeBlock(indentedCodeBlock, lineBlock))
    else:
      mdast.add(openParagraph(lineBlock))

  resultSeq = concat(resultSeq, mdast)
  
  return resultSeq