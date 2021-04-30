all:
	pandoc src/*.md \
	--bibliography=src/biblio.bib \
	-s \
	--filter pandoc-crossref \
	--citeproc \
	-o out/report.pdf \
	--table-of-contents \
	--highlight-style pygments \
	-V fontsize=12pt \
	-V papersize=a4paper \
	-V documentclass:report \
	--number-sections \
	--pdf-engine=xelatex \
	# --lua-filter=lua-filters/diagram-generator/diagram-generator.lua \
	# --lua-filter lua-filters/wordcount/wordcount.lua \
	# -M wordcount=process-anyway

fuck:
	pandoc src/fuck.md \
	--bibliography=src/biblio.bib \
	--citeproc \
	-o out/fuck.pdf

wordcount:
	pandoc src/*.md \
	--lua-filter lua-filters/wordcount/wordcount.lua

spellcheck:
	pandoc src/*.md \
	--lua-filter lua-filters/spellcheck/spellcheck.lua

clean:
	rm -f out/*
	rm -rf _minted-*
	rm -rf report.*
