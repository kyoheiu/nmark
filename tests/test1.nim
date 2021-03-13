import unittest, strutils, sequtils
import mrkpkg/def, mrkpkg/mdToAst, mrkpkg/astToHtml

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
    mdToAst(flag, lineBlock, mdast, resultSeq, str)
  if lineBlock != "":
    mdast.add(openParagraph(lineBlock))
  resultSeq = concat(resultSeq, mdast)
  var resultHtml: string
  for mdast in resultSeq:
    resultHtml.add(mdast.astToHtml)
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

test "themanticBreak":
  check testProc("testfiles/themanticBreak.md") == """
<hr />
<hr />
<hr />
<p>--
**
__</p>
<hr />
<hr />
<hr />
<hr />
<hr />
<hr />
<p>_ _ _ _ a</p>
<p>a------</p>
<p>---a---</p>
"""

test "setextHeadings":
  check testProc("testfiles/setextHeadings.md") == """
<h2>Foo1</h2>
<h1>Foo2</h1>
<h2>Foo3</h2>
<h2>Foo4</h2>
<h1>Foo5</h1>
<pre><code>Foo6
---

Foo7
</code></pre>
<hr />
<h2>Foo8</h2>
<p>Foo9
= =</p>
<p>Foo10</p>
<hr />
"""

test "atxHeadings":
  check testProc("testfiles/atxHeadings.md") == """
<h1>foo</h1>
<h2>foo</h2>
<h3>foo</h3>
<h4>foo</h4>
<h5>foo</h5>
<h6>foo</h6>
<p>####### foo</p>
<p>#5 bolt</p>
<p>#hashtag</p>
<h3>foo</h3>
<h2>foo</h2>
<h1>foo</h1>
<h1>foo</h1>
<pre><code># foo
</code></pre>
<p>foo
# bar</p>
<h1>foo</h1>
<h5>foo</h5>
<p>Foo bar</p>
<h1>baz</h1>
<p>Bar foo</p>
<h2></h2>
<h1></h1>
<h3></h3>
"""