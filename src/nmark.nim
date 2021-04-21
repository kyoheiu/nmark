import json
import nmarkpkg/private/parseLines, nmarkpkg/private/astToHtml, nmarkpkg/private/defBlock



proc echoSeqBlock(s: seq[Block]) =
  var t: seq[JsonNode]
  for b in s:
    t.add(%b)
  echo t



proc markdown*(lines: string): string =
  let seqAst = lines.parseLines

  #echoSeqBlock seqAst

  var linkSeq: seq[Block]
  for e in seqAst:
    if e.kind == BlockKind.linkRef:
      linkSeq.add(e)
    elif e.kind == BlockKind.containerBlock:
      for c in e.children:
        if c.kind == BlockKind.linkRef:
          linkSeq.add(c)
    else:
      continue

  #echoSeqBlock linkSeq

  var resultHtml: string
  var isTight = false

  for ast in seqAst:
    resultHtml.add(ast.astToHtml(isTight, linkseq))

  return resultHtml


proc markdownFromFile*(path: string): string =
  let lines = readFile(path)

  let seqAst = lines.parseLines

  var linkSeq: seq[Block]
  for e in seqAst:
    if e.kind == BlockKind.linkRef:
      linkSeq.add(e)
    else:
      continue

  var resultHtml: string
  var isTight = false

  for ast in seqAst:
    resultHtml.add(ast.astToHtml(isTight, linkSeq))

  return resultHtml



when isMainModule:
  let
    f = parseFile("testfiles/spec-test.json")
  var
    begins = 327
    ends = 350
  for j in f:
    let
      j = f[begins-1]
      md = j["markdown"].getStr
      mdd = md.markdown
      hl = j["html"].getStr
      num = j["example"].getInt
    if markdown(md) != hl:
      echo num
      echo "---\p" & md & "---" 
      echo mdd
    else:
      echo $num & " -> Success"
    begins.inc
    if begins == ends:
      break