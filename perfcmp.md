# Perfomance comparison detail

## How to compare
`./casa build` generates 100 same htmls containing a lot of markdown delimiters. Contents and source code are in my [repo](https://github.com/kyoheiu/Casa).

## result
### nim-markdown@0.8.5 >>
| Command | Mean [ms] | Min [ms] | Max [ms] | Relative |
|:---|---:|---:|---:|---:|
| `./casa build` | 304.1 ± 7.7 | 298.5 | 324.5 | 1.00 |

### nmark@"0.1.10">>
| Command | Mean [ms] | Min [ms] | Max [ms] | Relative |
|:---|---:|---:|---:|---:|
| `./casa build` | 66.3 ± 6.3 | 64.3 | 98.7 | 1.00 |
