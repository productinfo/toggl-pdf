FONTS_INPUT := $(wildcard app/fonts/*.ttf)
FONTS_OUTPUT := $(patsubst app/%,dist/%, $(FONTS_INPUT))

IMAGES_INPUT := $(wildcard app/images/*)
IMAGES_OUTPUT := $(patsubst app/%,dist/%, $(IMAGES_INPUT))

COFFEEFILES = $(shell find app/ -type f -name '*.coffee')
OUTPUTJSFILES = $(patsubst app/%.coffee, dist/%.js, $(COFFEEFILES))

default: s

run:
	@coffee --nodejs --stack_size=4096 app/server.coffee

release: $(IMAGES_OUTPUT) $(FONTS_OUTPUT) dist/package.json coffee node_modules
	@echo > /dev/null

node_modules: dist
	@cd dist && npm install --silent

coffee: $(OUTPUTJSFILES)
	@echo > /dev/null

dist/%.js: app/%.coffee
	coffee -co $(@D) $<

dist/fonts/%.ttf: $(FONTS_INPUT) dist/fonts
	cp $< $@

dist/images/%: $(IMAGES_INPUT) dist/images
	cp $< $@

dist/package.json: dist
	cp package.json dist/package.json

dist/fonts: dist
	mkdir -p dist/fonts

dist/images: dist
	mkdir -p dist/images

dist:
	mkdir -p dist

clean:
	@rm -f *.pdf

i:
	@coffee --nodejs --stack_size=4096 testdata/test_invoice.coffee && open invoice.pdf

p:
	@coffee --nodejs --stack_size=4096 testdata/test_payment.coffee && open payment.pdf

s:
	@coffee --nodejs --stack_size=4096 testdata/test_summary.coffee && open summary.pdf

d:
	@coffee --nodejs --stack_size=4096 testdata/test_detailed.coffee && open detailed.pdf

w:
	@coffee --nodejs --stack_size=4096 testdata/test_weekly.coffee && open weekly.pdf

test: clean
	@coffee --nodejs --stack_size=4096 testdata/test_invoice.coffee && file invoice.pdf | grep PDF && true
	@coffee --nodejs --stack_size=4096 testdata/test_payment.coffee && file payment.pdf | grep PDF && true
	@coffee --nodejs --stack_size=4096 testdata/test_summary.coffee && file summary.pdf | grep PDF && true
	@coffee --nodejs --stack_size=4096 testdata/test_detailed.coffee && file detailed.pdf | grep PDF && true
	@coffee --nodejs --stack_size=4096 testdata/test_weekly.coffee && file weekly.pdf | grep PDF && true

fonts:
	./merge.ff app/fonts/src/OpenSans-Regular.ttf app/fonts/src/OpenSansHebrew-Regular.ttf
	@cp app/fonts/src/OpenSans-Regular-merged.ttf app/fonts/OpenSans-Regular.ttf
	./merge.ff app/fonts/src/OpenSans-Bold.ttf app/fonts/src/OpenSansHebrew-Bold.ttf
	@cp app/fonts/src/OpenSans-Bold-merged.ttf app/fonts/OpenSans-Bold.ttf
	@rm app/fonts/src/OpenSans*-merged.ttf
