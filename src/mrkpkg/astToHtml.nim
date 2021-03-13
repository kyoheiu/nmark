import def, htmlgen

proc astToHtml*(resultHtml: var string, mdast: Block): string =
  case mdast.kind
  of leafBlock:

    case mdast.leafType

    of themanticBreak: resultHtml.add(hr() & "\p")

    of paragraph: resultHtml.add(p(mdast.inline.value) & "\p")

    of header1: resultHtml.add(h1(mdast.inline.value) & "\p")

    of header2: resultHtml.add(h2(mdast.inline.value) & "\p")

    of header3: resultHtml.add(h3(mdast.inline.value) & "\p")

    of header4: resultHtml.add(h4(mdast.inline.value) & "\p")

    of header5: resultHtml.add(h5(mdast.inline.value) & "\p")

    of header6: resultHtml.add(h6(mdast.inline.value) & "\p")

    of indentedCodeBlock: resultHtml.add(pre(code(mdast.inline.value & "\p")) & "\p")

    of fencedCodeBlock:
      if mdast.inline.value == "":
        resultHtml.add(pre(code(mdast.inline.value)) & "\p")
      else:
        resultHtml.add(pre(code(mdast.inline.value & "\p")) & "\p")

    else: return

  else:
    return