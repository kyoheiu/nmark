import mrkpkg/mdToAst, mrkpkg/astToHtml

proc markdown*(path: string): string =
  let line = readFile(path)

  let seqAst = line.mdToAst

  var resultHtml: string
  var isTight = false

  for ast in seqAst:
    resultHtml.add(ast.astToHtml(isTight))

  return resultHtml



when isMainModule:
  let f = "testfiles/longtext.md"
  echo f.markdown