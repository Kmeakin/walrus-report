all:
	pandoc src/*.md \
	-o out/report.pdf \
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
