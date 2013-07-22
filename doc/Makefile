.PHONY:    default clean tarball

core = client debug globals mouse players text

interfaces = actionbar bankscreen interfaces mainscreen minimap

gametabs = abilitybook backpack gametab logout
lobby = lobby worlds


all:
	@python docgen.py `echo $(core) | sed -r \
		's/(\w+)/..\/lib\/core\/\1.simba/g'` > /dev/null
	@python docgen.py `echo $(interfaces) | sed -r \
		's/(\w+)/..\/lib\/interfaces\/\1.simba/g'` > /dev/null
	@python docgen.py `echo $(gametabs) | sed -r \
		's/(\w+)/..\/lib\/interfaces\/gametabs\/\1.simba/g'` > /dev/null
	@python docgen.py `echo $(lobby) | sed -r \
		's/(\w+)/..\/lib\/interfaces\/lobby\/\1.simba/g'` > /dev/null
	#@python docgen.py `echo $(misc) | sed -r \
	#	's/(\w+)/..\/SRL\/misc\/\1.simba/g'` > /dev/null
	@make -C sphinx/ singlehtml
	#@make -C sphinx/ html

clean:
	@rm -f `echo $(core) | sed -r 's/(\w+)/sphinx\/\1.rst/g'`
	@rm -f `echo $(interfaces) | sed -r 's/(\w+)/sphinx\/\1.rst/g'`
	@rm -f `echo $(gametabs) | sed -r 's/(\w+)/sphinx\/\1.rst/g'`
	@rm -f `echo $(lobby) | sed -r 's/(\w+)/sphinx\/\1.rst/g'`
	@make -C sphinx/ clean

tarball:
	@$(MAKE) all
	@tar cjf doc.tar.bz2 -C sphinx/_build/ html
