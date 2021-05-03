import nmark/mdToAst, nmark/astToHtml, nmark/def

proc markdown*(lines: string): string =
  let seqAst = lines.mdToAst

  #echoObj seqAst

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