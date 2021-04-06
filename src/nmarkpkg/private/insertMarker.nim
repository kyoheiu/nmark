from strutils import removeSuffix
from htmlparser import entityToUtf8
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
    toEntity: bool
    toEscape: bool
    toCode: bool

proc newSplitFlag(): SplitFlag =
  SplitFlag(
    toAutoLink: false,
    toMailLink: false,
    toLinktext: false,
    toLinkDestination: false,
    toImagetext: false,
    toImageDestination: false,
    toEntity: false,
    toEscape: false,
    toCode: false
  )

proc returnMatchedDelim(s: seq[DelimStack], position: int): DelimStack =
  for delim in s:
    if delim.position == position:
      return delim
    else: continue

proc tagToLiteral*(line: string): string =
  for c in line:
    case c
      of '<':
        result.add("&lt;")
        continue
      
      of '>':
        result.add("&gt;")
        continue
    
      else:
        result.add(c)
        continue



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

    block codeBlock:
      if flag.toCode:
        case c
        
        of '\n':
          continue

        of '<':
          result.add("&lt;")
          continue
        
        of '>':
          result.add("&gt;")
          continue

        of '"':
          result.add("&quot;")
      
        else:
          break codeBlock

    if skipCount > 0:
      skipCount.dec
      continue

    if flag.toEscape:
      case c

      of '"':
        result.add("&quot;")
        flag.toEscape = false
      
      of '&':
        result.add("&amp;")
        flag.toEscape = false

      of '<':
        result.add("&lt;")
        flag.toEscape = false

      of '>':
        result.add("&gt;")
        flag.toEscape = false
      
      of '\n':
        result.add("<br />")
        flag.toEscape = false
      
      else:
        result.add(c)
        flag.toEscape = false

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
    
    elif flag.toEntity:
      if c == ';':
        tempStr.add(c)
        let sliceStr = tempStr[1..^2]
        let entity = sliceStr.entityToUtf8
        if entity != "":
          result.add(entity)
        else:
          result.add(tempStr)
        tempStr = ""
        flag.toEntity = false
      else:
        tempStr.add(c)
    
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
          flag.toCode = true
          if currentDelim.numDelim > 1:
            skipCount = currentDelim.numDelim - 1
        
        else:
          result.add("</code>")
          flag.toCode = false
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
          result.add("<br />\n")
          skipCount = currentDelim.numDelim
      
      of "&":
        flag.toEntity = true
        tempStr.add(c)

      of "\\":
        flag.toEscape = true

      else:
        result.add(c)
    
    elif c == '"':
      result.add("&quot;")

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