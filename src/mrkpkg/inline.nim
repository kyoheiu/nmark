import re

let
  codespan = re"(`)([^`]*)(`)"
  emphasis = re"(\*)(\S+)([^\*]*)(\S)(\*)"

type
  InlineFlag = ref IFObj
  IFObj = object
    flagEmphasisAste: bool
    flagEmphasisScor: bool
    flagStrongAste: bool
    flagStrongScor: bool

proc newInlineFlag*(): InlineFlag =
  InlineFlag(
    flagEmphasisAste: false,
    flagEmphasisScor: false,
    flagStrongAste: false,
    flagStrongScor: false
  )

proc parseInline*(line: string): string =
  line.replacef(codespan, "<code>$2</code>")
  .replacef(emphasis, "<em>$2$3$4</em>")

#proc parseEmphasis*(line: string): string =
  #for c in line:
    #if c == "*":
