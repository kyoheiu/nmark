from strutils import removeSuffix, isEmptyOrWhiteSpace
from sequtils import filter, any
from unicode import toLower
from htmlparser import entityToUtf8
import json
import readInline, parseInline, defBlock

type
  SplitFlag = ref SObj
  SObj = object
    toAutoLink: bool
    toMailLink: bool
    toHtmlTag: bool
    toLinktext: bool
    toLinkDestination: bool
    toImagetext: bool
    toImageDestination: bool
    toLinkRef: bool
    toEntity: bool
    toEscape: bool
    toCode: bool
    afterBS: bool
    isLink: bool
    isImage: bool
    startPos: int
    urlPos: int

proc newSplitFlag(): SplitFlag =
  SplitFlag(
    toAutoLink: false,
    toMailLink: false,
    toHtmlTag: false,
    toLinktext: false,
    toLinkDestination: false,
    toImagetext: false,
    toImageDestination: false,
    toLinkRef: false,
    toEntity: false,
    toEscape: false,
    toCode: false,
    afterBS: false,
    isLink: false,
    isImage: false,
    startPos: 0,
    urlPos: 0
  )

type linkKind = enum
  toUrl
  toUrlLT
  skipToTitle
  toTitleDouble
  toTitleSingle
  toTitlePare
  afterTitle
  broken
  none

proc returnMatchedDelim(s: seq[DelimStack], position: int): DelimStack =
  for delim in s:
    if delim.position == position:
      return delim
    else: continue

proc hasCanCloseLinkRef(s: seq[DelimStack], i: int): bool =
  let filtered = s.filter(proc(x: DelimStack): bool = x.position >= i)
  return filtered.any(proc(x: DelimStack): bool = x.typeDelim == "]" and x.potential == canClose)

proc asLiteral*(line: string): string =
  for c in line:
    case c
      of '<':
        result.add("&lt;")
        continue
      
      of '>':
        result.add("&gt;")
        continue

      of '"':
        result.add("&quot;")

      else:
        result.add(c)
        continue



proc insertMarker(line: string, linkSeq: seq[Block], delimSeq: seq[DelimStack]): string =
  
  var delimPos: seq[int]
  var flag = newSplitFlag()
  var
    url: string
    title: string
    numOpenP: int
    numCloseP: int
    isAfterBreak = false
    isAfterBS = false
    isAfterWS = false
    isUrlLT = false
    lf = toUrl


  for delim in delimSeq:
    delimPos.add(delim.position)

  var tempStr: string
  var linkText: string
  var skipCount: int

  for i, c in line:

    if skipCount > 0:
      skipCount.dec
      continue

    block codeBlock:
      if flag.toCode:
        case c
        
        of '\n':
          tempStr.add(" ")
          continue

        of '<':
          tempstr.add("&lt;")
          continue
        
        of '>':
          tempStr.add("&gt;")
          continue

        of '"':
          tempStr.add("&quot;")

        of '`':
          break codeBlock

        else:
          tempStr.add(c)
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
    
    elif flag.toHtmlTag:
      if c == '>':
        result.add("<" & tempStr & ">")
        tempStr = ""
        flag.toHtmlTag = false
      else:
        tempStr.add(c)
    
    elif flag.toLinktext:
      if c == ']':
        flag.toLinktext = false
        flag.toLinkDestination = true
        flag.urlPos = i
        skipCount = 1
      else:
        linkText.add(c)
    
    elif flag.toLinkDestination:

      # parse link contents     
      if c == ')':
        if lf == toUrlLT: url.add(c)
        else:
          if flag.isLink:
            if url.isEmptyOrWhitespace and title.isEmptyOrWhitespace:
              let delimInLink = linkText.processEmphasis
              let processedText = linkText.insertMarker(linkSeq, delimInLink)
              result.add("<a href=\"\">" & processedText & "</a>")
              flag.toLinkDestination = false
              continue
            
            elif lf == broken:
              result.add(line[flag.startPos..i])
              flag .toLinkDestination = false
              continue

            elif lf == toUrl or lf == skipToTitle:
              let delimInLink = linkText.processEmphasis
              let processedText = linkText.insertMarker(linkSeq, delimInLink)
              result.add("<a href=\"" & url & "\">" & processedText & "</a>")
              flag.toLinkDestination = false
              continue
            
            elif lf == afterTitle:
              let delimInLink = linkText.processEmphasis
              let processedText = linkText.insertMarker(linkSeq, delimInLink)
              result.add("<a href=\"" & url & "\" title=\"" & title & "\">" & processedText & "</a>")
              flag.toLinkDestination = false
              continue
            
            else:
              result.add(line[flag.startPos..i])
              flag .toLinkDestination = false
              continue

      elif i == flag.urlPos+2:
        case c
        of '<':
          lf = toUrlLT
          continue
        else:
          lf = toUrl
          url.add(c)
          continue
      
      case lf
      of toUrl:
        if c == ' ':
          lf = skipToTitle
        else:
          url.add(c)
      of toUrlLT:
        if c == '>':
          lf = skipToTitle
        elif c == ' ':
          url.add("%20")
        else:
          url.add(c)
      of skipToTitle:
        if c == ' ': continue
        elif c == '"':
          lf = toTitleDouble
        elif c == '\'':
          lf = toTitleSingle
        elif c == '(':
          lf = toTitlePare
        else:
          lf = broken
          continue
      of toTitleDouble:
        if c == '"' and line[i-1] != '\\':
          lf = afterTitle
          continue
        else: title.add(c)
      of toTitleSingle:
        if c == '\'' and line[i-1] != '\\':
          lf = afterTitle
          continue
        else: title.add(c)
      of toTitlePare:
        if c == ')' and line[i-1] != '\\':
          lf = afterTitle
          continue
        else: title.add(c)
      of afterTitle:
        if c == ' ': continue
        else:
          lf = broken
          continue
      of broken:
        result.add(line[flag.startPos..i])
        flag.toLinkDestination = false
        continue

      of none:
        result.add(line[flag.startPos..i])
        flag.toLinkDestination = false
        continue


    
    elif flag.toLinkRef:
      if c == ']':
        if flag.afterBS:
          tempStr.add(c)
          flag.afterBS = false
          continue
        else:
          flag.toLinkRef = false
          if linkSeq.len() != 0:
            for e in linkSeq:
              if e.linkLabel.toLower == tempStr.toLower:
                if e.linkTitle == "":
                  result.add("<a href=\"" & e.linkUrl & "\">" & tempStr & "</a>")
                  tempStr = ""
                  break
                else:
                  result.add("<a href=\"" & e.linkUrl & "\" title=\"" & e.linkTitle & "\">" & tempStr &  "</a>")
                  tempStr = ""
                  break
              else:
                continue
            if tempStr != "":
              result.add("[" & tempStr & "]")
              tempStr = ""
          else:
            result.add("[" & tempStr & "]")
            tempStr = ""
            continue

      elif c == '\\':
        flag.afterBS = true
        continue
      else:
        if flag.afterBS:
          flag.afterBS = false
        tempStr.add(c)
        continue

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
        elif currentDelim.potential == htmlTag:
          flag.toHtmlTag = true
        else:
          result.add("&lt;")
      
      of "[":
        if currentDelim.potential == opener:
          flag.toLinktext = true
          flag.isLink = true
          flag.startPos = i
        elif currentDelim.potential == canOpen and
             delimSeq.hasCanCloseLinkRef(i):
          flag.toLinkRef = true
        else:
          result.add(c)
      
      of "![":
        if currentDelim.potential == opener:
          flag.toLinktext = true
          flag.isImage = true
          flag.startPos = i
          skipCount = 1

      of "`":
        if currentDelim.potential == opener:
          result.add("<code>")
          flag.toCode = true
          if currentDelim.numDelim > 1:
            skipCount = currentDelim.numDelim - 1
        
        else:
          if tempStr[0] == ' ' and tempStr[^1] == ' ' and
             not (tempStr.isEmptyOrWhiteSpace):
            tempStr = tempStr[1..^2]
          result.add(tempStr & "</code>")
          tempStr = ""
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

      of ">":
        result.add("&gt;")

      else:
        result.add(c)
    
    elif c == '"':
      result.add("&quot;")

    elif c == '<':
      result.add("&lt;")
        
    elif c == '>':
      result.add("&gt;")

    else:
      if flag.toCode:
        tempStr.add(c)
        continue
      result.add(c)

  if flag.toEscape: result.add('\\')

  result.removeSuffix({' ', '\n'})
  
  return result



proc echoDelims(r: seq[DelimStack]) =
  var j: seq[JsonNode]
  for element in r:
    j.add(%element)
  
  echo j



proc insertInline*(line: string, linkSeq: seq[Block]): string =
  #echoDelims line.parseInline
  insertMarker(line, linkSeq, line.parseInline)