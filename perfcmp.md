# Perfomance comparison detail

## How to compare
`./casa build` generates 100 same htmls containing a lot of markdown delimiters. Contents and source code are in my [repo](https://github.com/kyoheiu/Casa).

## result
### nim-markdown@0.8.5 >>
| Command | Mean [ms] | Min [ms] | Max [ms] | Relative |
|:---|---:|---:|---:|---:|
| `./casa build` | 310.7 ± 25.9 | 299.3 | 384.1 | 1.00 |

### nmark@0.1.10>>
| Command | Mean [ms] | Min [ms] | Max [ms] | Relative |
|:---|---:|---:|---:|---:|
| `./casa build` | 68.1 ± 10.3 | 65.0 | 116.5 | 1.00 |
