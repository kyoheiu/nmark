from strutils import removeSuffix, isEmptyOrWhiteSpace, isAlphaNumeric, toLowerAscii
from sequtils import filter, any
from unicode import toLower
from htmlparser import entityToUtf8
import readInline, parseInline, def

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
    toImageRef: bool
    toEntity: bool
    toEscape: bool
    toCode: bool
    afterBS: bool
  
  LinkFlag = ref LObj
  LObj = object
    isLink: bool
    isImage: bool
    startPos: int
    urlPos: int
    linkText: string
    url: string
    title: string
    numOpenP: int
    numCloseP: int
    afterBS: bool
    parseLink: linkKind

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
    toImageRef: false,
    toEntity: false,
    toEscape: false,
    toCode: false,
    afterBS: false,
  )

proc newLinkFlag(): LinkFlag =
  LinkFlag(
    isLink: false,
    isImage: false,
    startPos: 0,
    urlPos: 0,
    linkText: "",
    url: "",
    title: "",
    numOpenP: 0,
    numCloseP: 0,
    afterBS: false,
    parseLink: none
  )

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

      of '&':
        result.add("&amp;")

      else:
        result.add(c)
        continue



proc insertMarker(line: string, linkSeq: seq[Block], delimSeq: seq[DelimStack]): string =
  
  var delimPos: seq[int]
  var flag = newSplitFlag()
  var l = newLinkFlag()

  for delim in delimSeq:
    delimPos.add(delim.position)

  var tempStr: string
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
        
        of '&':
          tempStr.add("&amp;")

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
        result.add("<br />" & c)
        flag.toEscape = false
      
      of unchangedChar:
        result.add(c)
        flag.toEscape = false
      
      else:
        result.add("\\" & c)
        flag.toEscape = false

    elif flag.toAutoLink:
      if c == '>':
        var linkDest: string
        for d in tempStr:
          if d == '\\':
            linkDest.add("%5C")
          else: linkDest.add(d)
        result.add("<a href=\"" & linkDest & "\">" & tempStr & "</a>")
        linkDest = ""
        tempStr = ""
        flag.toAutoLink = false
      else:
        if c == '&':
          tempStr.add("&amp;")
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
        if l.numOpenP > l.numCloseP:
          l.numCloseP.inc
          l.linkText.add(c)
        else:
          l.numOpenP = 0
          l.numCloseP = 0
          flag.toLinktext = false
          flag.toLinkDestination = true
          l.urlPos = i
          skipCount = 1
      elif c == '[':
        if line[i-1] != '\\':
          l.numOpenP.inc
        l.linkText.add(c)
      elif c == '\\':
        continue
      else:
        l.linkText.add(c)
    
    elif flag.toLinkDestination:

      # parse link contents     
      if l.parseLink != toTitlePare and c == ')' and not l.afterBS:
        if l.numOpenP > l.numCloseP and l.parseLink == toUrl:
          l.url.add(c)
          l.numCloseP.inc
          continue
        if l.parseLink == toUrlLT:
          l.url.add(c)
          continue
        else:
          if l.isLink:
            if l.url.isEmptyOrWhitespace and l.title.isEmptyOrWhitespace:
              let processedText = l.linkText.insertMarker(linkSeq, l.linkText.parseInline)
              result.add("<a href=\"\">" & processedText & "</a>")
              flag.toLinkDestination = false
              l = newLinkFlag()
              continue
            
            elif l.parseLink == broken:
              for j, d in line[l.startpos..i]:
                if d == '<':
                  tempStr.add("&lt;")
                elif d == '>':
                  tempStr.add("&gt;")
                elif d == '\\':
                  continue
                else:
                  tempStr.add(d)
              result.add(tempStr)
              tempstr = ""
              flag.toLinkDestination = false
              l = newLinkFlag()
              continue

            elif l.parseLink == toUrl or l.parseLink == skipToTitle:
              let processedText = l.linkText.insertMarker(linkSeq, l.linkText.parseInline)
              result.add("<a href=\"" & l.url & "\">" & processedText & "</a>")
              flag.toLinkDestination = false
              l = newLinkFlag()
              continue
            
            elif l.parseLink == afterTitle:
              let processedText = l.linkText.insertMarker(linkSeq, l.linkText.parseInline)
              result.add("<a href=\"" & l.url & "\" title=\"" & l.title & "\">" & processedText & "</a>")
              flag.toLinkDestination = false
              l = newLinkFlag()
              continue
            
            else:
              result.add(line[l.startPos..i])
              flag.toLinkDestination = false
              l = newLinkFlag()
              continue
          
          elif l.isImage:
            if l.url.isEmptyOrWhitespace and l.title.isEmptyOrWhitespace:
              result.add("<img src=\"\" alt=\">" & l.linkText & "<\" />")
              flag.toLinkDestination = false
              l = newLinkFlag()
              continue
            
            elif l.parseLink == broken:
              for j, d in line[l.startpos..i]:
                if d == '<':
                  tempStr.add("&lt;")
                elif d == '>':
                  tempStr.add("&gt;")
                elif d == '\\':
                  continue
                else:
                  tempStr.add(d)
              result.add(tempStr)
              tempstr = ""
              flag.toLinkDestination = false
              l = newLinkFlag()
              continue

            elif l.parseLink == toUrl or l.parseLink == skipToTitle:
              result.add("<img src=\"" & l.url & "\" alt=\"" & l.linkText & "\" />")
              flag.toLinkDestination = false
              l = newLinkFlag()
              continue
            
            elif l.parseLink == afterTitle:
              result.add("<img src=\"" & l.url & "\" alt=\"" & l.linkText & "\" title=\"" & l.title & "\" />")
              flag.toLinkDestination = false
              l = newLinkFlag()
              continue
            
            else:
              result.add(line[l.startPos..i])
              flag.toLinkDestination = false
              l = newLinkFlag()
              continue
      
      elif l.parseLink != toTitlePare and c == ')' and l.afterBS:
        if l.parseLink == toUrl:
          l.url.add(c)
          continue

      elif i == l.urlPos+2:
        case c
        of '<':
          l.parseLink = toUrlLT
          continue
        of '\\':
          l.parseLink = toUrl
          l.afterBS = true
          continue
        else:
          l.parseLink = toUrl
          if c == '"': l.url.add("%22")
          else: l.url.add(c)
          continue
      
      case l.parseLink
      of toUrl:
        if c == ' ':
          l.parseLink = skipToTitle
        elif c == '\\':
          l.afterBS = true
          continue
        elif c == '"':
          l.afterBS = false
          l.url.add("%22")
        elif c == '(':
          if not l.afterBS:
            l.url.add(c)
            l.numOpenP.inc
          else:
            l.afterBS = false
            l.url.add(c)
        elif puncChar.contains(c):
          l.afterBS = false
          l.url.add(c)
        else:
          if l.afterBS:
            l.afterBS = false
          l.url.add(c)
      of toUrlLT:
        if c == '>':
          if not flag.afterBS:
            l.parseLink = skipToTitle
          else:
            l.parseLink = broken
        elif c == ' ':
          l.url.add("%20")
        elif c == '"':
          l.url.add("&quot;")
        elif c == '\\':
          flag.afterBS = true
        else:
          if l.afterBS:
            l.afterBS = false
          l.url.add(c)
      of skipToTitle:
        if c == ' ': continue
        elif c == '"':
          l.parseLink = toTitleDouble
        elif c == '\'':
          l.parseLink = toTitleSingle
        elif c == '(':
          l.parseLink = toTitlePare
        else:
          l.parseLink = broken
          continue
      of toTitleDouble:
        if c == '"' and line[i-1] != '\\':
          l.parseLink = afterTitle
        elif c == '"' and line[i-1] == '\\':
          l.title.add("&quot;")
        elif c == '\\': continue
        else: l.title.add(c)
      of toTitleSingle:
        if c == '\'' and line[i-1] != '\\':
          l.parseLink = afterTitle
          continue
        elif c == '"':
          l.title.add("&quot;")
        elif c == '\\': continue
        else: l.title.add(c)
      of toTitlePare:
        if c == ')' and line[i-1] != '\\':
          l.parseLink = afterTitle
          continue
        elif c == '\\': continue
        else: l.title.add(c)
      of afterTitle:
        if c == ' ': continue
        else:
          l.parseLink = broken
          continue
      of broken:
        result.add(line[l.startPos..i])
        flag.toLinkDestination = false
        l = newLinkFlag()
        continue

      of none:
        result.add(line[l.startPos..i])
        flag.toLinkDestination = false
        l = newLinkFlag()
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
                let delimInLink = tempStr.processEmphasis
                let processedText = tempStr.insertMarker(linkSeq, delimInLink)
                if e.linkTitle == "":
                  result.add("<a href=\"" & e.linkUrl & "\">" & processedText & "</a>")
                  tempStr = ""
                  break
                else:
                  result.add("<a href=\"" & e.linkUrl & "\" title=\"" & e.linkTitle & "\">" & processedText &  "</a>")
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

    elif flag.toImageRef:
      if c == ']':
        if flag.afterBS:
          flag.afterBS = false
          continue
        else:
          flag.toImageRef = false
          if linkSeq.len() != 0:
            for e in linkSeq:
              if e.linkLabel.toLower == tempStr.toLower:
                if e.linkTitle == "":
                  result.add("<img src=\"" & e.linkUrl & "\" alt=\"" & tempStr & "\" />")
                  tempStr = ""
                  break
                else:
                  result.add("<img src=\"" & e.linkUrl & "\" alt=\"" & tempStr & "\" title=\"" & e.linkTitle & "\" />")
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
        if c.isAlphaNumeric:
          tempStr.add(c)
        continue

    elif flag.toEntity:
      if c == ';':
        tempStr.add(c)
        let sliceStr = tempStr[1..^2]
        let entity = sliceStr.entityToUtf8
        if entity == "\"":
          result.add("&quot;")
        elif entity == "&":
          result.add("&amp;")
        elif entity != "":
          result.add(entity)
        else:
          result.add("&amp;" & sliceStr & ";")
        tempStr = ""
        flag.toEntity = false
      else:
        tempStr.add(c)
    
    elif c == '\\':
        flag.toEscape = true
    
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
          l.isLink = true
          l.startPos = i
        elif currentDelim.potential == canOpen and
             delimSeq.hasCanCloseLinkRef(i):
          flag.toLinkRef = true
        else:
          result.add(c)
      
      of "![":
        if currentDelim.potential == opener:
          flag.toLinktext = true
          l.isImage = true
          l.startPos = i
          skipCount = 1
        elif currentDelim.potential == canOpen and
             delimSeq.hasCanCloseLinkRef(i):
          flag.toImageRef = true
        else:
          result.add(c)

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
    
    elif c == '&':
      result.add("&amp;")

    else:
      if flag.toCode:
        tempStr.add(c)
        continue
      result.add(c)

  if flag.toEscape: result.add('\\')

  elif flag.toLinktext: result.add(line[l.startPos..^1])

  elif flag.toLinkDestination: result.add(line[l.startPos..^1])

  result.removeSuffix({' ', '\n'})
  
  return result



proc insertInline*(line: string, linkSeq: seq[Block]): string =
  #echoDelims line.parseInline
  insertMarker(line, linkSeq, line.parseInline)