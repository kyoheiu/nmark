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

## performance comparison
One of the reason I'm working on this parser is that other markdown parser librarys written in Nim seemed relatively slow. Here is a comparison between `nim-markdown`, which I think is the standard Nim markdown parser, and `nmark`, through a static site generator(which, btw, I made) and `hyperfine`.

`./casa build` generates 100 same htmls containing a lot of markdown delimiter. For detail please check my [repo](https://github.com/kyoheiu/Casa).

### nim-markdown
| Command | Mean [ms] | Min [ms] | Max [ms] | Relative |
|:---|---:|---:|---:|---:|
| `./casa build` | 296.1 ± 12.2 | 287.6 | 322.4 | 1.00 |

### nmark
| Command | Mean [ms] | Min [ms] | Max [ms] | Relative |
|:---|---:|---:|---:|---:|
| `./casa build` | 54.4 ± 0.9 | 53.1 | 57.4 | 1.00 |

## caution
This is still work-in-progess project, and does not FULLY pass the [spec-test of CommonMark](https://spec.commonmark.org/0.29/). For example,

```
> foo
bar
===
```

... is, by `nmark`, converted to:

```
<blockquote>
<h1>foo
bar</h1>
</blockquote>
```

Though I believe `nmark` is enough for normal usage, I'm working on improving the accuracy and performance. And issues, pull requests always welcome.