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
	
wordcount:
	pandoc src/*.md \
	--lua-filter filters/wordcount.lua
