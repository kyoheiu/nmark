import unittest, strutils, sequtils, json
import mrkpkg/def, mrkpkg/parseline, mrkpkg/parser

proc testProc*(file: string): string =
  var resultSeq: seq[Block]
  var mdast: seq[Block]
  var lineBlock: string
  var unorderedListSeq: seq[string]
  var orderedListSeq: seq[string]
  var flag = newFlag()
  var s = readFile(file)

  for line in s.splitLines:
    var str = line
    parseLine(flag, lineBlock, mdast, resultSeq, str)
  if lineBlock != "":
    mdast.add(openParagraph(lineBlock))
  resultSeq = concat(resultSeq, mdast)
  echo pretty(%resultSeq)
  var resultHtml: string
  for mdast in resultSeq:
    resultHtml.add(mdast.parseMdast)
  return resultHtml

test "test1":
  check testProc("testfiles/1.md") == """
<p>This is a test-file.</p>
<h1>heading</h1>
<h2>heading 2</h2>
<p>Nim is a programing language.</p>
<h3>heading 3</h3>
<p>This is a markdown-parser.</p>
<h4>heading 4</h4>
<p>Hello, World!</p>
"""

test "example32":
  check testProc("testfiles/example32.md") == """
<h1>foo</h1>
<h2>foo</h2>
<h3>foo</h3>
<h4>foo</h4>
<h5>foo</h5>
<h6>foo</h6>
"""