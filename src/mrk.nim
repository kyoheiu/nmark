import mrkpkg/mdToAst, mrkpkg/astToHtml
import json


proc markdown*(path: string): string =
  let s = readFile(path)
  let seqAst = s.mdToAst

  var resultHtml: string

  for ast in seqAst:
    resultHtml.add(ast.astToHtml)

  return resultHtml



when isMainModule:
  echo markdown("testfiles/simpleList.md")