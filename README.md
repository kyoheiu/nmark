# nmark

Fast markdown parser, based on CommonMark, written in Nim.

## Usage

```nim
import nmark

let txt = """
> Lorem ipsum dolor
sit amet.
> - Qui *quodsi iracundia*
> - aliquando id
"""

echo txt.markdown
```
...and it's done.

```
# output
<blockquote>
<p>Lorem ipsum dolor
sit amet.</p>
<ul>
<li>Qui <em>quodsi iracundia</em></li>
<li>aliquando id</li>
</ul>
</blockquote>
```

### table
You can use tables in `nmark`.

```
| abc | defghi |
:-: | -----------:
bar | baz
```

is converted to:


```
<table>
<thead>
<tr>
<th align="center">abc</th>
<th align="right">defghi</th>
</tr>
</thead>
<tbody>
<tr>
<td align="center">bar</td>
<td align="right">baz</td>
</tr>
</tbody>
</table>
```
(Tables need to be separated from other blocks by empty line.)


## Performance comparison
One of the reason I'm working on this parser is that other markdown parser librarys written in Nim seemed relatively slow. Here is a comparison between [`nim-markdown`](https://github.com/soasme/nim-markdown), which I think is the standard Nim markdown parser, and `nmark`, through a static site generator(which, btw, I made) and `hyperfine`.

[Perfomance comparison detail](perfcmp.md)

As shown above, `nmark` is about 5 times faster than `nim-markdown`.

## Caution
This is still work-in-progess project, and does not FULLY pass the [spec-test of CommonMark](https://spec.commonmark.org/0.29/). For example,

```
> foo
bar
===
```

is, by `nmark`, converted to:

```
<blockquote>
<h1>foo
bar</h1>
</blockquote>
```

I'm working on improving the accuracy and performance. Issues, pull requests always welcome.
