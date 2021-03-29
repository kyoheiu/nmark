import mrkpkg/mdToAst, mrkpkg/astToHtml, mrkpkg/readInline, mrkpkg/parseInline
import json, algorithm


proc markdown*(path: string): string =
  let s = readFile(path)
  let seqAst = s.mdToAst

  var resultHtml: string
  var isTight = false

  for ast in seqAst:
    resultHtml.add(ast.astToHtml(isTight))

  return resultHtml



when isMainModule:
  let f = readFile("testfiles/inline.md")
 
  var r = (f.readAutoLink & f.readLinkOrImage & f.readCodeSpan & f.readEmphasisAste & f.readEmphasisUnder & f.readHardBreak).sortedByIt(it.position).parseAutoLink

  var j: seq[JsonNode]
  for element in r:
    j.add(%element)
  
  echo j
    