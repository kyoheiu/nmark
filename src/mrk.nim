import mrkpkg/mdToAst, mrkpkg/astToHtml, mrkpkg/inline


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
  echoSeqInline f.parseInline2
  #echo f.parseInline