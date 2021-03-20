import def, inline, re, htmlgen, strutils

proc astToHtml*(mdast: Block): string =
  case mdast.kind
  of leafBlock:

    case mdast.leafType

    of themanticBreak: return hr() & "\p"

    of paragraph:
      let value = mdast.inline.value.replace(reSoftBreak, "<br />\p").strip(leading = false).parseInline
      return p(value) & "\p"

    of header1: return h1(mdast.inline.value) & "\p"

    of header2: return h2(mdast.inline.value) & "\p"

    of header3: return h3(mdast.inline.value) & "\p"

    of header4: return h4(mdast.inline.value) & "\p"

    of header5: return h5(mdast.inline.value) & "\p"

    of header6: return h6(mdast.inline.value) & "\p"

    of htmlBlock: return mdast.inline.value & "\p"

    of indentedCodeBlock: return pre(code(mdast.inline.value & "\p")) & "\p"

    of fencedCodeBlock:
      if mdast.inline.value == "":
        return pre(code(mdast.inline.value)) & "\p"
      else:
        return pre(code(mdast.inline.value & "\p")) & "\p"

    of list : return li(mdast.inline.value) & "\p"

    else: return

  of containerBlock:

    case mdast.containerType

    of Blocktype.blockQuote:

      var blockQuoteContainer: string
      for child in mdast.children:
        blockQuoteContainer.add(child.astToHtml)
      return htmlgen.blockquote("\p" & blockquoteContainer) & "\p"

    of Blocktype.unOrderedList:

      var unOrderedListContainer: string
      for child in mdast.children:
        unOrderedListContainer.add(child.astToHtml)
      return ul("\p" & unOrderedListContainer) & "\p"

    of Blocktype.orderedList:

      var orderedListContainer: string
      for child in mdast.children:
        orderedListContainer.add(child.astToHtml)
      return ol("\p" & orderedListContainer) & "\p"

    else: return