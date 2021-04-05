import nmarkpkg/mdToAst, nmarkpkg/astToHtml

proc markdown*(line: string): string =
  let seqAst = line.mdToAst

  var resultHtml: string
  var isTight = false

  for ast in seqAst:
    resultHtml.add(ast.astToHtml(isTight))

  return resultHtml


proc markdownFromFile*(path: string): string =
  let line = readFile(path)

  let seqAst = line.mdToAst

  var resultHtml: string
  var isTight = false

  for ast in seqAst:
    resultHtml.add(ast.astToHtml(isTight))

  return resultHtml



when isMainModule:
  let f = "testfiles/entity.md"
  echo f.markdownFromFile