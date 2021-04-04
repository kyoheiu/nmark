from strutils import removeSuffix
import json
import readInline, parseInline

type
  SplitFlag = ref SObj
  SObj = object
    toAutoLink: bool
    toMailLink: bool
    toLinktext: bool
    toLinkDestination: bool
    toImagetext: bool
    toImageDestination: bool
    deleteLineBreak: bool

proc newSplitFlag(): SplitFlag =
  SplitFlag(
    toAutoLink: false,
    toMailLink: false,
    toLinktext: false,
    toLinkDestination: false,
    toImagetext: false,
    toImageDestination: false,
    deleteLineBreak: false
  )

proc returnMatchedDelim(s: seq[DelimStack], position: int): DelimStack =
  for delim in s:
    if delim.position == position:
      return delim
    else: continue

proc insertMarker(line: string, delimSeq: seq[DelimStack]): string =
  
  var delimPos: seq[int]
  var flag = newSplitFlag()
  
  for delim in delimSeq:
    delimPos.add(delim.position)

  var tempStr: string
  var linkText: string
  var linkDestination: string
  var skipCount: int

  for i, c in line:

    block hardBreak:
      if c == '\n' and flag.deleteLineBreak:
        continue
      else: break hardBreak

    if skipCount > 0:
      skipCount.dec
      continue

    elif flag.toAutoLink:
      if c == '>':
        result.add("<a href=\"" & tempStr & "\">" & tempStr & "</a>")
        tempStr = ""
        flag.toAutoLink = false
      else:
        tempStr.add(c)

    elif flag.toMailLink:
      if c == '>':
        result.add("<a href=\"mailto:" & tempStr & "\">" & tempStr & "</a>")
        tempStr = ""
        flag.toMailLink = false
      else:
        tempStr.add(c)
    
    elif flag.toLinktext:
      if c == ']':
        flag.toLinktext = false
        flag.toLinkDestination = true
        skipCount = 1
      else:
        linkText.add(c)
    
    elif flag.toLinkDestination:
      if c == ')':
        flag.toLinkDestination = false
        let delimInLink = linkText.processEmphasis
        let processedText = linkText.insertMarker(delimInLink)
        result.add("<a href=\"" & linkDestination & "\">" & processedText & "</a>")
        linkText = ""
        linkDestination = ""
      else:
        linkDestination.add(c)

    elif flag.toImagetext:
      if c == ']':
        flag.toImagetext = false
        flag.toImageDestination = true
        skipCount = 1
      else:
        linkText.add(c)
    
    elif flag.toImageDestination:
      if c == ')':
        flag.toImageDestination = false
        result.add("<img src=\"" & linkDestination & "\" alt=\"" & linkText & "\" />")
        linkText = ""
        linkDestination = ""
      else:
        linkDestination.add(c)
    
    elif delimPos.contains(i):
    
      let currentDelim = delimSeq.returnMatchedDelim(i)

      case currentDelim.typeDelim

      of "<":
        if currentDelim.potential == linkOpener:
          flag.toAutoLink = true
        elif currentDelim.potential == mailOpener:
          flag.toMailLink = true
      
      of "[":
        if currentDelim.potential == opener:
          flag.toLinktext = true
      
      of "![":
        if currentDelim.potential == opener:
          flag.toImagetext = true
          skipCount = 1

      of "`":
        if currentDelim.potential == opener:
          result.add("<code>")
          flag.deleteLineBreak = true
          if currentDelim.numDelim > 1:
            skipCount = currentDelim.numDelim - 1
        
        else:
          result.add("</code>")
          flag.deleteLineBreak = false
          if currentDelim.numDelim > 1:
            skipCount = currentDelim.numDelim - 1
        
      of "emphasis":
        if currentDelim.potential == opener:
          result.add("<em>")
        else:
          result.add("</em>")
        
      of "strong":
        if currentDelim.potential == opener:
          result.add("<strong>")
          skipCount = 1
        else:
          result.add("</strong>")
          skipCount = 1
      
      of " ":
        if currentDelim.potential == opener:
          result.add("<br />\p")
          skipCount = currentDelim.numDelim

      else:
        result.add(c)

    else:
      result.add(c)

  result.removeSuffix({' ', '\n'})
  
  return result



proc echoDelims(r: seq[DelimStack]) =
  var j: seq[JsonNode]
  for element in r:
    j.add(%element)
  
  echo j



proc insertInline*(line: string): string =
  insertMarker(line, line.parseInline)