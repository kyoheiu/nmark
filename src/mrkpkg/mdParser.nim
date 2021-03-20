import strutils, sequtils
import def, mdToAst

proc mdParser*(s: string): seq[Block] =
  var flag = newFlag()
  var lineBlock: string
  var mdast: seq[Block]
  var resultSeq: seq[Block]

  for line in s.splitLines:
    var str = line
    mdToAst(flag, lineBlock, mdast, resultSeq, str)

  if flag.flagBlockQuote:
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
    resultSeq.add(openContainerBlock(blockQuote, mdast))
    mdast = @[]

  elif flag.flagUnorderedList:
    if lineBlock != "":
      mdast.add(openList(lineBlock))
    resultSeq.add(openContainerBlock(unOrderedList, mdast))
    mdast = @[]

  elif flag.flagOrderedList:
    if lineBlock != "":
      mdast.add(openList(lineBlock))
    resultSeq.add(openContainerBlock(orderedList, mdast))
    mdast = @[]
  
  elif lineBlock != "":
    if flag.flagIndentedCodeBlock:
      mdast.add(openCodeBlock(indentedCodeBlock, lineBlock))
    else:
      mdast.add(openParagraph(lineBlock))

  resultSeq = concat(resultSeq, mdast)

  return resultSeq