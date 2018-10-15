COPIED_OUTPUT := $(patsubst app/%,dist/%, $(shell find app/images/ app/fonts -type f -name '*'))
OUTPUTJSFILES = $(patsubst app/%.coffee, dist/%.js, $(shell find app/ -type f -name '*.coffee'))

OPEN_CMD :=
ifeq ($(shell uname -s),Darwin)
	OPEN_CMD += open
else
	OPEN_CMD += xdg-open
endif

default: s

run:
	@coffee --nodejs --stack_size=4096 app/server.coffee

vendor:
	cd dist && tar cvfz toggl_pdf.tgz * .nvmrc
	mv dist/toggl_pdf.tgz toggl_pdf.tgz

vendor_staging: vendor
	rsync -avz -e "ssh -p 22" toggl_pdf.tgz toggl@office.toggl.com:/var/www/office/appseed/toggl_pdf/staging.tgz

vendor_production: vendor
	rsync -avz -e "ssh -p 22" toggl_pdf.tgz toggl@office.toggl.com:/var/www/office/appseed/toggl_pdf/production.tgz

release: $(COPIED_OUTPUT) dist/package.json dist/.nvmrc coffee node_modules
	@echo > /dev/null

node_modules: dist
	@cd dist && npm install --silent

coffee: $(OUTPUTJSFILES)
	@echo > /dev/null

dist/.nvmrc: .nvmrc
	@cp .nvmrc dist/.nvmrc

dist/%.js: app/%.coffee
	@coffee -co $(@D) $<

dist/fonts/%: app/fonts/%
	@mkdir -p $(@D)
	@cp $< $@

dist/images/%: app/images/%
	@mkdir -p $(@D)
	@cp $< $@

dist/package.json: dist
	@cp package.json dist/package.json

dist:
	@mkdir -p dist

clean:
	@rm -f *.pdf

i:
	@coffee --nodejs --stack_size=4096 testdata/test_invoice.coffee && $(OPEN_CMD) invoice.pdf

p:
	@coffee --nodejs --stack_size=4096 testdata/test_payment.coffee && $(OPEN_CMD) payment.pdf

s:
	@coffee --nodejs --stack_size=4096 testdata/test_summary.coffee && $(OPEN_CMD) summary.pdf

d:
	@coffee --nodejs --stack_size=4096 testdata/test_detailed.coffee && $(OPEN_CMD) detailed.pdf

w:
	@coffee --nodejs --stack_size=4096 testdata/test_weekly.coffee && $(OPEN_CMD) weekly.pdf

we:
	@coffee --nodejs --stack_size=4096 testdata/test_weekly_earnings.coffee && $(OPEN_CMD) weekly_earnings.pdf

pre:
	@coffee --nodejs --stack_size=4096 testdata/test_prepayment.coffee && $(OPEN_CMD) prepayment.pdf

test: clean
	@coffee --nodejs --stack_size=4096 testdata/test_invoice.coffee && file invoice.pdf | grep PDF && true
	@coffee --nodejs --stack_size=4096 testdata/test_payment.coffee && file payment.pdf | grep PDF && true
	@coffee --nodejs --stack_size=4096 testdata/test_summary.coffee && file summary.pdf | grep PDF && true
	@coffee --nodejs --stack_size=4096 testdata/test_detailed.coffee && file detailed.pdf | grep PDF && true
	@coffee --nodejs --stack_size=4096 testdata/test_weekly.coffee && file weekly.pdf | grep PDF && true
	@coffee --nodejs --stack_size=4096 testdata/test_weekly_earnings.coffee && file weekly_earnings.pdf | grep PDF && true

fonts:
	./merge.ff app/fonts/src/OpenSans-Regular.ttf app/fonts/src/OpenSansHebrew-Regular.ttf
	@cp app/fonts/src/OpenSans-Regular-merged.ttf app/fonts/OpenSans-Regular.ttf
	./merge.ff app/fonts/src/OpenSans-Bold.ttf app/fonts/src/OpenSansHebrew-Bold.ttf
	@cp app/fonts/src/OpenSans-Bold-merged.ttf app/fonts/OpenSans-Bold.ttf
	@rm app/fonts/src/OpenSans*-merged.ttf

.PHONY: node_modules
