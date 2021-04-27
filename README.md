# nmark

A fast markdown parser, based on CommonMark.

## Usage

```
import nmark

let f = readfile("1.md")
echo f.markdown
```

...and it's done!

```
<h3>Headings</h3>
<p>The following HTML <code>&lt;h1&gt;—&lt;h6&gt;</code> elements represent six levels of section headings. <code>&lt;h1&gt;</code> is the highest section level while <code>&lt;h6&gt;</code> is the lowest.</p>
<h1>H1</h1>
<h2>H2</h2>
<h3>H3</h3>
<h4>H4</h4>
<h5>H5</h5>
<h6>H6</h6>
<h3>Paragraph</h3>
...
```

## perf comparison
By using a static site generator(which, btw, I made) and `hyperfine`, let's compare the existing markdown parser written in Nim and nmark.

### the existing parser
| Command | Mean [ms] | Min [ms] | Max [ms] | Relative |
|:---|---:|---:|---:|---:|
| `./casa build` | 296.1 ± 12.2 | 287.6 | 322.4 | 1.00 |

### nmark
| Command | Mean [ms] | Min [ms] | Max [ms] | Relative |
|:---|---:|---:|---:|---:|
| `./casa build` | 54.4 ± 0.9 | 53.1 | 57.4 | 1.00 |

(Detail in my [repo](https://github.com/kyoheiu/Casa))

## caution
This is work-in-progess project, and does not FULLY pass the [spec-test of CommonMark](https://spec.commonmark.org/0.29/). For example,

```
> foo
bar
===
```

... is converted to:

```
<blockquote>
<h1>foo
bar</h1>
</blockquote>
```

Though I BELIEVE this markdown parser is ENOUGH for normal usage, I'm working on improving the perf and 
