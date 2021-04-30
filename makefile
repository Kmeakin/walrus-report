all:
	pandoc src/*.md \
	-s \
	-o out/report.pdf \
	--table-of-contents \
	--highlight-style pygments \
	-V fontsize=12pt \
	-V papersize=a4paper \
	-V documentclass:report \
	--number-sections \
	--pdf-engine=xelatex \
	--filter pandoc-crossref \
	--lua-filter=lua-filters/diagram-generator/diagram-generator.lua \
	--lua-filter lua-filters/wordcount/wordcount.lua \
	-M wordcount=process-anyway

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
