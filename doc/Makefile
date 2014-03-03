.PHONY:    default clean tarball

core = client debug globals mouse players text

interfaces = actionbar bankscreen chatbox chooseoption conversationbox interfaces lodestone mainscreen minimap options pinscreen production progressscreen toolscreen

gametabs = backpack gametab stats
lobby = lobby worlds

misc = antiban items smart srlplayerform srlstats

tesseract = tesseract

utilities = color drawing math pixelshift time wrappers
types = extendedarrays integerarrays stringarrays tbox tpoint tpointarrays types



all:
	@python docgen.py `echo $(core) | sed -r \
		's/(\w+)/..\/lib\/core\/\1.simba/g'` > /dev/null
	@python docgen.py `echo $(interfaces) | sed -r \
		's/(\w+)/..\/lib\/interfaces\/\1.simba/g'` > /dev/null
	@python docgen.py `echo $(gametabs) | sed -r \
		's/(\w+)/..\/lib\/interfaces\/gametabs\/\1.simba/g'` > /dev/null
	@python docgen.py `echo $(lobby) | sed -r \
		's/(\w+)/..\/lib\/interfaces\/lobby\/\1.simba/g'` > /dev/null
	@python docgen.py `echo $(misc) | sed -r \
		's/(\w+)/..\/lib\/misc\/\1.simba/g'` > /dev/null
	@python docgen.py `echo $(tesseract) | sed -r \
		's/(\w+)/..\/lib\/tesseract\/\1.simba/g'` > /dev/null
	@python docgen.py `echo $(utilities) | sed -r \
		's/(\w+)/..\/lib\/utilities\/\1.simba/g'` > /dev/null
	@python docgen.py `echo $(types) | sed -r \
		's/(\w+)/..\/lib\/utilities\/types\/\1.simba/g'` > /dev/null
	@make -C sphinx/ html

clean:
	rm -f `echo $(core) | sed -r 's/(\w+)/sphinx\/\1.rst/g'`
	rm -f `echo $(interfaces) | sed -r 's/(\w+)/sphinx\/\1.rst/g'`
	rm -f `echo $(gametabs) | sed -r 's/(\w+)/sphinx\/\1.rst/g'`
	rm -f `echo $(lobby) | sed -r 's/(\w+)/sphinx\/\1.rst/g'`
	rm -f `echo $(misc) | sed -r 's/(\w+)/sphinx\/\1.rst/g'`
	rm -f `echo $(utilities) | sed -r 's/(\w+)/sphinx\/\1.rst/g'`
	rm -f `echo $(types) | sed -r 's/(\w+)/sphinx\/\1.rst/g'`
	@make -C sphinx/ clean

tarball:
	@$(MAKE) all
	@tar cjf doc.tar.bz2 -C sphinx/_build/ html
