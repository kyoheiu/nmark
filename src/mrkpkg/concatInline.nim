import readInline, parseInline

type
  InlineType* = enum
    autoLink,
    link,
    image,
    code,
    em,
    strong,
    text
  
  Inline* = ref InlineObj
  InlineObj = object
    kind: InlineType
    value: string

  SplitFlag = ref SObj
  SObj = object
    toAutoLink: bool
    toLink: bool
    toImage: bool
    toCode: bool
    toEm: bool
    toStrong: bool

proc newSplitFlag(): SplitFlag =
  SplitFlag(
    toAutoLink: false,
    toLink: false,
    toImage: false,
    toCode: false,
    toEm: false,
    toStrong:false
  )

proc newInline(textType: InlineType, str: string): Inline =
  Inline(kind: textType, value: str)

proc returnMatchedDelim(s: seq[DelimStack], position: int): DelimStack =
  for delim in s:
    if delim.position == position:
      return delim
    else: continue



proc splitInline*(line: string, delimSeq: seq[DelimStack]): seq[Inline] =
  
  var delimPos: seq[int]
  
  for delim in delimSeq:
    delimPos.add(delim.position)

  var inlines: seq[Inline] 
  var tempStr: string
  var flag = newSplitFlag()

  for i, c in line:
    
    if flag.toAutoLink:
      if delimPos.contains(i):
        let currentDelim = delimSeq.returnMatchedDelim(i)
        if currentDelim.typeDelim == ">":
          tempStr.add(c)
          inlines.add(newInline(autolink, tempStr))
          tempStr = ""
      else: tempStr.add(c)
        
    elif delimPos.contains(i):
      inlines.add(newInline(text, tempStr))
      tempStr = ""
    
      let currentDelim = delimSeq.returnMatchedDelim(i)

      case currentDelim.typeDelim

      of "<":
        flag.toAutoLink = true
        tempStr.add(c)

    else:
      tempStr.add(c)

  if tempStr != "":
    inlines.add(newInline(text, tempStr))

  return inlines
  