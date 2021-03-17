import mrkpkg/mdParser, mrkpkg/astToHtml



proc markdown*(path: string): string =
  let s = readFile(path)
  let seqAst = s.mdParser
 
  var resultHtml: string

  for ast in seqAst:
    resultHtml.add(ast.astToHtml)

  return resultHtml



when isMainModule:
  echo markdown("testfiles/1.md")