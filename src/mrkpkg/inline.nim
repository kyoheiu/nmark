import re
import def

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

proc newInline(s: string): Inline =
  return Inline(kind: text, value: s)


proc parseInline2*(s: string): seq[Inline] =

  var result: seq[Inline]
  var tempStr: string

  for c in s:
    case c

    of '*':
      if tempStr != "":
        result.add(newInline(tempStr))
        tempStr = ""
      result.add(newInline("*"))
    
    else:
      tempStr.add(c)
  
  return result