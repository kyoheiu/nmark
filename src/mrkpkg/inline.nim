import re

let
  codespan = re"(`)([^`]*)(`)"
  emphasis = re"(\*)(\S+)([^\*]*)(\S)(\*)"

#type
  #InlineFlag = ref IFObj
  #IFObj = object
    #flagEmphasisAste: bool
    #flagEmphasisScor: bool
    #flagStrongAste: bool
    #flagStrongScor: bool

#proc newInlineFlag*(): InlineFlag =
  #InlineFlag(
    #preEmphaAste: false,
    #emphasisAste: false,
    #preEmphaScor: false,
    #emphasisScor: false,
    #preStrongAste: false,
    #strongAste: false,
    #preStrongScor: false,
    #strongScor: false
  #)

proc parseInline*(line: string): string =
  line.replacef(codespan, "<code>$2</code>")
  .replacef(emphasis, "<em>$2$3$4</em>")



#proc parseInline2*(inlines: seq[Block]): string =
  #var result: string
  #for inline in inlines:
    #result.add(inline.value)