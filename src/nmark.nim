import json
import nmarkpkg/private/mdToAst, nmarkpkg/private/astToHtml, nmarkpkg/private/defBlock



proc echoSeqBlock(s: seq[Block]) =
  var t: seq[JsonNode]
  for b in s:
    t.add(%b)
  echo t



proc markdown*(line: string): string =
  let seqAst = line.mdToAst

  var resultHtml: string
  var isTight = false

  for ast in seqAst:
    resultHtml.add(ast.astToHtml(isTight))

  return resultHtml & "\n"


proc markdownFromFile*(path: string): string =
  let line = readFile(path)

  let seqAst = line.mdToAst

  var resultHtml: string
  var isTight = false

  for ast in seqAst:
    resultHtml.add(ast.astToHtml(isTight))

  return resultHtml



when isMainModule:
  let
    f = parseFile("testfiles/spec-test.json")
    j = f[200]
    md = j["markdown"].getStr
    hl = j["html"].getStr
    num = j["example"].getInt
  if markdown(md) != hl: echo "Success"
  else:
    echo $num
    stdout.write markdown(md)
    stdout.write hl