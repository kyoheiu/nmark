import htmlgen, strutils
import defBlock, insertMarker

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

    of Blocktype.orderedLooseList:

      isTight = false
      var orderedListContainer: string
      for child in mdast.children:
        orderedListContainer.add(child.astToHtml(isTight, linkSeq))
      return ol("\p" & orderedListContainer) & "\p"

    of Blocktype.orderedTightList:

      isTight = true
      var orderedListContainer: string
      for child in mdast.children:
        orderedListContainer.add(child.astToHtml(isTight, linkSeq))
      isTight = false
      return ol("\p" & orderedListContainer) & "\p"

    else: return
  
  of olist:

    case mdast.olType:

    of Blocktype.orderedLooseList:

      isTight = false
      var orderedListContainer: string
      for child in mdast.children:
        orderedListContainer.add(child.astToHtml(isTight, linkSeq))
      return ol("\p" & orderedListContainer) & "\p"

    of Blocktype.orderedTightList:

      isTight = true
      var orderedListContainer: string
      for child in mdast.children:
        orderedListContainer.add(child.astToHtml(isTight, linkSeq))
      isTight = false
      return ol("\p" & orderedListContainer) & "\p"
  
    else: return


  else: return