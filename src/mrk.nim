import strutils, sequtils
import mrkpkg/def, mrkpkg/mdToAst, mrkpkg/astToHtml

proc mdParser*(path: string): string =
  var flag = newFlag()
  var lineBlock: string
  var mdast: seq[Block]
  var resultSeq: seq[Block]
  let s = readFile(path)

  for line in s.splitLines:
    var str = line
    mdToAst(flag, lineBlock, mdast, resultSeq, str)

  if flag.flagBlockQuote:
    if lineBlock != "":
      mdast.add(openParagraph(lineBlock))
    resultSeq.add(openQuoteBlock(mdast))
    mdast = @[]

  elif lineBlock != "":
    if flag.flagIndentedCodeBlock:
      mdast.add(openCodeBlock(indentedCodeBlock, lineBlock))
    else:
      mdast.add(openParagraph(lineBlock))

  resultSeq = concat(resultSeq, mdast)

  var resultHtml: string

  for mdast in resultSeq:
    resultHtml.add(mdast.astToHtml)

  return resultHtml

when isMainModule:
  mdParser()