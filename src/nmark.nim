import json
import nmarkpkg/private/parseLines, nmarkpkg/private/astToHtml, nmarkpkg/private/defBlock



proc echoSeqBlock(s: seq[Block]) =
  var t: seq[JsonNode]
  for b in s:
    t.add(%b)
  echo t



proc markdown*(lines: string): string =
  let seqAst = lines.parseLines

  var resultHtml: string
  var isTight = false

  for ast in seqAst:
    resultHtml.add(ast.astToHtml(isTight))

  return resultHtml


proc markdownFromFile*(path: string): string =
  let lines = readFile(path)

  let seqAst = lines.parseLines

  var resultHtml: string
  var isTight = false

  for ast in seqAst:
    resultHtml.add(ast.astToHtml(isTight))

  return resultHtml



when isMainModule:
  let
    f = parseFile("testfiles/spec-test.json")
    n = 80
    j = f[n-1]
    md = j["markdown"].getStr
    hl = j["html"].getStr
    num = j["example"].getInt
  if markdown(md) != hl:
    echo md
    echo  markdown(md)
  else:
    echo "Success"