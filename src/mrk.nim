import mrkpkg/mdToAst, mrkpkg/astToHtml


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
  echo f.parseInline