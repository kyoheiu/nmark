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
One of the reason I'm working on this parser is that other markdown parser librarys written in Nim seemed relatively slow. Here is a comparison between `nim-markdown`, which I think is the standard Nim markdown parser, and `nmark`, through a static site generator(which, btw, I made) and `hyperfine`.

`./casa build` generates 100 same htmls containing a lot of markdown delimiter. For detail please check my [repo](https://github.com/kyoheiu/Casa).

### nim-markdown@0.8.5 >>
| Command | Mean [ms] | Min [ms] | Max [ms] | Relative |
|:---|---:|---:|---:|---:|
| `./casa build` | 296.1 ± 12.2 | 287.6 | 322.4 | 1.00 |

### nmark@0.1.5 >>
| Command | Mean [ms] | Min [ms] | Max [ms] | Relative |
|:---|---:|---:|---:|---:|
| `./casa build` | 53.9 ± 5.7 | 51.8 | 86.1 | 1.00 |

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
