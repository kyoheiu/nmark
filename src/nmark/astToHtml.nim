from strutils import replace
import htmlgen
import def, insertMarker

proc astToHtml*(mdast: Block, isTight: var bool, linkSeq: seq[Block]): string =

  case mdast.kind
  of leafBlock:

    case mdast.leafType

    of themanticBreak: return hr() & "\p"

    of paragraph:
      let value = mdast.raw.insertInline(linkSeq)
      if isTight: return value
      else: return p(value) & "\p"

    of header1: return h1(mdast.raw.insertInline(linkSeq)) & "\p"

    of header2: return h2(mdast.raw.insertInline(linkSeq)) & "\p"

    of header3: return h3(mdast.raw.insertInline(linkSeq)) & "\p"

    of header4: return h4(mdast.raw.insertInline(linkSeq)) & "\p"

    of header5: return h5(mdast.raw.insertInline(linkSeq)) & "\p"

    of header6: return h6(mdast.raw.insertInline(linkSeq)) & "\p"

    of htmlBlock: return mdast.raw & "\p"

    of indentedCodeBlock: return pre(code(mdast.raw.asLiteral & "\p")) & "\p"

    else: return

  of fencedCode:

    if mdast.codeText == "":
      if mdast.codeAttr != "":
        var t = pre(code(mdast.codeText.asLiteral)) & "\p"
        return t.replace("<code>", "<code class=\"language-" & mdast.codeAttr & "\">")
      else:
        return pre(code(mdast.codeText.asLiteral)) & "\p"

    else:
      if mdast.codeAttr != "":
        var t = pre(code(mdast.codeText.asLiteral & "\p")) & "\p"
        return t.replace("<code>", "<code class=\"language-" & mdast.codeAttr & "\">")
      else:
        return pre(code(mdast.codeText.asLiteral & "\p")) & "\p"

  of containerBlock:

    case mdast.containerType

    of Blocktype.blockQuote:

      isTight = false
      var blockQuoteContainer: string
      for child in mdast.children:
        blockQuoteContainer.add(child.astToHtml(isTight, linkSeq))
      return htmlgen.blockquote("\n" & blockquoteContainer) & "\p"

    of Blocktype.list:

      var listContainer: string
      for child in mdast.children:
        listContainer.add(child.astToHtml(isTight, linkSeq))
      if isTight:
        return li(listContainer) & "\p"
      else:
        return li("\p" & listContainer) & "\p"

    of Blocktype.unOrderedLooseList:

      isTight = false
      var unOrderedListContainer: string
      for child in mdast.children:
        unOrderedListContainer.add(child.astToHtml(isTight, linkSeq))
      return ul("\p" & unOrderedListContainer) & "\p"

    of Blocktype.unOrderedTightList:

      isTight = true
      var unOrderedListContainer: string
      for child in mdast.children:
        unOrderedListContainer.add(child.astToHtml(isTight, linkSeq))
      isTight = false
      return ul("\p" & unOrderedListContainer) & "\p"

    else: return
  
  of olist:

    case mdast.olType:

    of Blocktype.orderedLooseList:

      isTight = false
      var orderedListContainer: string
      for child in mdast.olChildren:
        orderedListContainer.add(child.astToHtml(isTight, linkSeq))
      if mdast.startNumber != 1:
        var t = ol("\p" & orderedListContainer) & "\p"
        return t.replace("<ol>", "<ol start=\"" & $mdast.startNumber & "\">")
      else:
        return ol("\p" & orderedListContainer) & "\p"

    of Blocktype.orderedTightList:

      isTight = true
      var orderedListContainer: string
      for child in mdast.olChildren:
        orderedListContainer.add(child.astToHtml(isTight, linkSeq))
      isTight = false
      if mdast.startNumber != 1:
        var t = ol("\p" & orderedListContainer) & "\p"
        return t.replace("<ol>", "<ol start=\"" & $mdast.startNumber & "\">")
      else:
        return ol("\p" & orderedListContainer) & "\p"
  
    else: return

  of tableBlock:
    var head: string
    for i, e in mdast.thR:
      case mdast.align[i]
      
      of nothing:
        head.add("<th>" & e.insertInline(linkSeq) & "</th>\p")

      of AlignKind.center:
        head.add("<th align=\"center\">" & e.insertInline(linkSeq) & "</th>\p")
        
      of left:
        head.add("<th align=\"left\">" & e.insertInline(linkSeq) & "</th>\p")

      of right:
        head.add("<th align=\"right\">" & e.insertInline(linkSeq) & "</th>\p")

    head = thead("\p" & tr("\p" & head) & "\p")
    
    var body: string
    var tdRow: string
    for s in mdast.tdR:
      for i, e in s:
        case mdast.align[i]

        of nothing:
          tdRow.add("\p" & "<td>" & e.insertInline(linkSeq) & "</td>")

        of ALignKind.center:
          tdRow.add("\p" & "<td align=\"center\">" & e.insertInline(linkSeq) & "</td>")
          
        of left:
          tdRow.add("\p" & "<td align=\"left\">" & e.insertInline(linkSeq) & "</td>")

        of right:
          tdRow.add("\p" & "<td align=\"right\">" & e.insertInline(linkSeq) & "</td>")
      
      body.add(tr(tdRow & "\p"))
      tdRow = ""
    
    body = tbody("\p" & body & "\p")

    return table("\p" & (head & "\p" & body) & "\p") & "\p"
          


  else: return