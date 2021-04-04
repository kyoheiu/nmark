import mrkpkg/mdToAst, mrkpkg/astToHtml, json

proc markdown*(path: string): string =
  let line = readFile(path)

  let seqAst = line.mdToAst

  #var s: seq[JsonNode]
  #for bl in seqAst:
    #s.add(%bl)
  #echo s

  var resultHtml: string
  var isTight = false

  for ast in seqAst:
    resultHtml.add(ast.astToHtml(isTight))

  return resultHtml



when isMainModule:
  let f = "testfiles/longtext.md"
  echo f.markdown