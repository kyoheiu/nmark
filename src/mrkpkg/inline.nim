import re

let
  codespan = re"(`)([^`]*)(`)"
  emphasis = re"(\*)(\S+)([^\*]*)(\S)(\*)"

proc parseInline*(line: string): string =
  line.replacef(codespan, "<code>$2</code>")
  .replacef(emphasis, "<em>$2$3$4</em>")