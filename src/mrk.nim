import mrkpkg/mdToAst, mrkpkg/astToHtml, mrkpkg/inline
import json


proc markdown*(path: string): string =
  let s = readFile(path)
  let seqAst = s.mdToAst

  var resultHtml: string
  var isTight = false

  for ast in seqAst:
    resultHtml.add(ast.astToHtml(isTight))

  return resultHtml



when isMainModule:
  let f = readFile("testfiles/inlineCodespan.md")
  let c = f.readCodeSpan
  let a = f.readAutoLink
  let e = f.readEmphasis
 
  let r = f.readAutoLink & f.readLinkOrImage & f.readCodeSpan & f.readEmphasis

  var j: seq[JsonNode]
  for element in r:
    j.add(%element)
  
  echo j
    