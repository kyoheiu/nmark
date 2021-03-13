import strutils, sequtils, json
import mrkpkg/def, mrkpkg/parseline, mrkpkg/parser

when isMainModule:

  var flag = newFlag()
  var lineBlock: string
  var mdast: seq[Block]
  var resultSeq: seq[Block]
  let s = readFile("testfiles/1.md")

  for line in s.splitLines:
    var str = line
    parseLine(flag, lineBlock, mdast, resultSeq, str)
  if lineBlock != "":
    mdast.add(openParagraph(lineBlock))
  resultSeq = concat(resultSeq, mdast)
  echo pretty(%resultSeq)
  #var resultHtml: string
  #for mdast in resultSeq:
    #resultHtml.add(mdast.parseMdast)
  #echo resultHtml
