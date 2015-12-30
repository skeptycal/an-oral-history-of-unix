# Usage:
# $ make -f ../an-oral-history-of-unix/main.mk

PHONY: help
help:
	$(info $(help))@:

define help =
compile		produce html, epub, pdf
html			$(html.out)
epub			$(epub.put)
pdf			$(pdf.out)
endef

.DELETE_ON_ERROR:
pp-%:
	@echo "$(strip $($*))" | tr ' ' \\n

src := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
out := .

%.txt: %.doc
	antiword $< | recode -f utf8..us > $@

doc.src := $(src)/src-doc
doc := $(wildcard $(doc.src)/*.doc)
txt := $(patsubst $(doc.src)/%.doc, %.txt, $(doc))
vpath %.doc $(doc.src)

.PHONY: txt
txt: $(txt)

node_modules: package.json
	npm install
	touch $@

.PHONY: npm
npm: node_modules

# html

txt.dir := $(src)/txt
txt := $(wildcard $(txt.dir)/*.txt)
vpath %.txt $(txt.dir)

html.dest := $(patsubst $(txt.dir)/%.txt, %.html, $(txt))

$(html.dest): %.html: %.txt
	$(src)/txt2md "MSM" "$(basename $(notdir $<))" < $< | $(src)/md2html > $@

.PHONY: html
html: $(html.dest)

# ebook

toc.html: $(html.dest) $(src)/metadata.xml
	$(src)/toc -m $(src)/metadata.xml $(html.dest) > $@

pages.src := $(wildcard $(src)/pages/*.html)
pages.dest := $(notdir $(pages.src))
$(pages.dest): %.html: $(src)/pages/%.html
	cp $< $@

book.zip: $(html.dest) toc.html $(pages.dest)
	-rm $@
	zip -0 -q $@ $^

book.epub: book.zip $(src)/style.epub.css
	ebook-convert $< $@ \
		--level1-toc '//*[@class="title"]' \
		--disable-font-rescaling \
		--epub-inline-toc \
		--use-auto-toc \
		--no-default-epub-cover \
		--no-svg-cover \
		--minimum-line-height 0 \
		--breadth-first \
		--extra-css $(src)/style.epub.css \
		-m $(src)/metadata.xml