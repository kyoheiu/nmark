import json
import nmark/parseLines, nmark/astToHtml, nmark/defBlock

proc markdown(lines: string): string =
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

  var isTight = false

  for ast in seqAst:
    result.add(ast.astToHtml(isTight, linkseq))

  return result



proc specTest() =
  let
    f = parseFile("testfiles/spec-test.json")
  var
    begins = 1
    ends = 100
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



when isMainModule:
  specTest()
  #let f = readFile("testfiles/table.md")
  #echo f.markdown