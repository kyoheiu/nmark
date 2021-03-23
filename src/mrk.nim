import mrkpkg/def, mrkpkg/mdToAst, mrkpkg/astToHtml
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
  echo markdown("testfiles/simpleList4.md")