import strutils, sequtils, json
import def, parseline, parser

when isMainModule:
  var s = readFile("testfiles/2.md")
  for line in s.splitLines:
    var str = line
    parseLine(mdast, str)
  if lineBlock != "":
    mdast.add(openParagraph(lineBlock))
    resultSeq = concat(resultSeq, mdast)
  echo pretty(%resultSeq)
  var resultHtml: string
  for mdast in resultSeq:
    resultHtml.add(mdast.parseMdast)
  echo resultHtml