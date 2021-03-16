import unittest
import mrk

test "test1":
  check mdParser("testfiles/1.md") == """
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
  check mdParser("testfiles/themanticBreak.md") == """
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

test "atxHeadings":
  check mdParser("testfiles/atxHeadings.md") == """
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

test "setextHeadings":
  check mdParser("testfiles/setextHeadings.md") == """
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

test "indentedCodeBlocks":
  check mdParser("testfiles/indentedCodeBlocks.md") == """
<pre><code>a simple
  indented code block

chunk1

chunk2



chunk3
</code></pre>
<p>Foo
bar</p>
<pre><code>foo
</code></pre>
<p>bar</p>
<h1>Heading</h1>
<pre><code>foo
</code></pre>
<h2>Heading</h2>
<pre><code>foo
</code></pre>
<hr />
<pre><code>foo  
</code></pre>
"""

test "fencedCodeBlocks":
  check mdParser("testfiles/fencedCodeBlocks.md") == """
<pre><code>first
~~~
</code></pre>
<pre><code>second
```
</code></pre>
<pre><code>third
```
</code></pre>
<pre><code></code></pre>
<pre><code>fourth
 fourth
fourth
</code></pre>
<pre><code>```
fifth
```
</code></pre>
<pre><code>sixth
~~~ ~~
</code></pre>
"""

test "simpleBlockQuote":
  check mdParser("testfiles/simpleBlockQuote.md") == """
<blockquote><h1>Foo</h1>
<p>bar
baz</p>
</blockquote>
"""

test "simpleHtmlBlock":
  check mdParser("testfiles/simpleHtmlBlock.md") == """
<table>
  <tr>
    <td>
           hi
    </td>
  </tr>
</table>
<p>okay.</p>
"""

test "simpleParagraph":
  check mdParser("testfiles/simpleParagraph.md") == """
<p>aaa
bbb</p>
<p>aaa<br />
bbb</p>
<p>aaa</p>
<p>bbb</p>
"""

#test "simpleLinkReference":
  #check mdParser("testfiles/simpleLinkReference.md") == """
#<p><a href="/url" title="title">foo</a></p>
#<p><a href="my%20url" title="title">Foo bar</a></p>
#"""