import strutils, sequtils, json
import mrkpkg/def, mrkpkg/parseline, mrkpkg/parser

when isMainModule:

  var s = readFile("testfiles/2.md")

  for line in s.splitLines:
    var str = line
    parseLine(str)
  if lineBlock != "":
    mdast.add(openParagraph(lineBlock))
    resultSeq = concat(resultSeq, mdast)
  echo pretty(%resultSeq)
  var resultHtml: string
  for mdast in resultSeq:
    resultHtml.add(mdast.parseMdast)
  echo resultHtml

proc testProc*(lines: string): string =
  var s = readFile(lines)
  for line in s.splitLines:
    var str = line
    parseLine(str)
  if lineBlock != "":
    mdast.add(openParagraph(lineBlock))
    resultSeq = concat(resultSeq, mdast)
  var resultHtml: string
  for mdast in resultSeq:
    resultHtml.add(mdast.parseMdast)
  return resultHtml