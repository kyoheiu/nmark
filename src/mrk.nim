import strutils, sequtils, json
import mrkpkg/def, mrkpkg/mdToAst, mrkpkg/astToHtml

when isMainModule:

  var flag = newFlag()
  var lineBlock: string
  var mdast: seq[Block]
  var resultSeq: seq[Block]
  let s = readFile("testfiles/atxHeadings.md")

  for line in s.splitLines:
    var str = line
    mdToAst(flag, lineBlock, mdast, resultSeq, str)
  if lineBlock != "":
    mdast.add(openParagraph(lineBlock))
  resultSeq = concat(resultSeq, mdast)
  echo pretty(%resultSeq)
  #var resultHtml: string
  #for mdast in resultSeq:
    #resultHtml.add(mdast.astToHtml)
  #echo resultHtml
