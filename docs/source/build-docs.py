#!/usr/bin/env python3
"""Builds the Watchlog docs (.docx and .pdf) from the Markdown masters here.

    python3 build-docs.py

Needs pandoc and LibreOffice. The Overview master has lines like
    <!-- fig: image2.png 2.4, image3.png 3.5 | Caption text -->
The plain Overview leaves them out. The "(with screenshots)" version puts
the pictures there (side by side when there are two) with the caption
under them in italics. Pictures live in media/.
"""
import os, re, subprocess, sys, tempfile, shutil

HERE = os.path.dirname(os.path.abspath(__file__))
DOCS = os.path.dirname(HERE)
REF = os.path.join(HERE, "reference.docx")
FIG = re.compile(r"^<!-- fig: (.*?) \| (.*?) -->$", re.M)


def figure(m):
    pics = []
    for part in m.group(1).split(","):
        name, width = part.split()
        pics.append(f"![](media/{name}){{width={width}in}}")
    caption = m.group(2).strip()
    if len(pics) == 1:
        body = pics[0]
    else:
        body = "| " + " | ".join(pics) + " |\n|" + "---|" * len(pics)
    return f"{body}\n\n*{caption}*"


def build(md_text, name):
    tmp = tempfile.mkdtemp()
    src = os.path.join(HERE, f".{name}.tmp.md")
    with open(src, "w", encoding="utf-8") as f:
        f.write(md_text)
    docx = os.path.join(DOCS, name + ".docx")
    subprocess.run(["pandoc", src, "-f", "markdown-implicit_figures", "-o", docx,
                    "--reference-doc", REF, "--resource-path", HERE], check=True, cwd=HERE)
    os.remove(src)
    subprocess.run(["soffice", "--headless", "--convert-to", "pdf", "--outdir", tmp, docx],
                   check=True, stdout=subprocess.DEVNULL)
    shutil.copy(os.path.join(tmp, name + ".pdf"), os.path.join(DOCS, name + ".pdf"))
    pages = subprocess.run(["pdfinfo", os.path.join(DOCS, name + ".pdf")], capture_output=True,
                           text=True).stdout
    print(name, "-", re.search(r"Pages:\s+(\d+)", pages).group(1), "pages")


def main():
    read = lambda n: open(os.path.join(HERE, n + ".md"), encoding="utf-8").read()
    ov = read("Watchlog - Overview")
    build(re.sub(r"\n*" + FIG.pattern.strip("^$") + r"\n", "\n", ov, flags=re.M), "Watchlog - Overview")
    build(FIG.sub(figure, ov), "Watchlog - Overview (with screenshots)")
    for n in ("Watchlog - Summary", "Watchlog - IT Summary"):
        build(read(n), n)


if __name__ == "__main__":
    main()
