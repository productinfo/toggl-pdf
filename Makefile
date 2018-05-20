COPIED_OUTPUT := $(patsubst app/%,dist/%, $(shell find app/images/ app/fonts -type f -name '*'))
OUTPUTJSFILES = $(patsubst app/%.coffee, dist/%.js, $(shell find app/ -type f -name '*.coffee'))

default: s

run:
	./node_modules/coffeescript/bin/coffee --nodejs --stack_size=4096 app/server.coffee

vendor:
	cd dist && tar cvfz toggl_pdf.tgz *
	mv dist/toggl_pdf.tgz toggl_pdf.tgz

vendor_staging: vendor
	rsync -avz -e "ssh -p 22" toggl_pdf.tgz toggl@office.toggl.com:/var/www/office/appseed/toggl_pdf/staging.tgz

vendor_production: vendor
	rsync -avz -e "ssh -p 22" toggl_pdf.tgz toggl@office.toggl.com:/var/www/office/appseed/toggl_pdf/production.tgz

release: $(COPIED_OUTPUT) dist/package.json coffee node_modules
	@echo > /dev/null

node_modules: dist
	@cd dist && npm install --silent

coffee: $(OUTPUTJSFILES)
	@echo > /dev/null

dist/%.js: app/%.coffee
	./node_modules/coffeescript/bin/coffee -co $(@D) $<

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
	./node_modules/coffeescript/bin/coffee --nodejs --stack_size=4096 testdata/test_invoice.coffee && open invoice.pdf

p:
	./node_modules/coffeescript/bin/coffee --nodejs --stack_size=4096 testdata/test_payment.coffee && open payment.pdf

s:
	./node_modules/coffeescript/bin/coffee --nodejs --stack_size=4096 testdata/test_summary.coffee && open summary.pdf

d:
	./node_modules/coffeescript/bin/coffee --nodejs --stack_size=4096 testdata/test_detailed.coffee && open detailed.pdf

w:
	./node_modules/coffeescript/bin/coffee --nodejs --stack_size=4096 testdata/test_weekly.coffee && open weekly.pdf

we:
	./node_modules/coffeescript/bin/coffee --nodejs --stack_size=4096 testdata/test_weekly_earnings.coffee && open weekly_earnings.pdf

pre:
	./node_modules/coffeescript/bin/coffee --nodejs --stack_size=4096 testdata/test_prepayment.coffee && open prepayment.pdf

test: clean
	./node_modules/coffeescript/bin/coffee --nodejs --stack_size=4096 testdata/test_invoice.coffee && file invoice.pdf | grep PDF && true
	./node_modules/coffeescript/bin/coffee --nodejs --stack_size=4096 testdata/test_payment.coffee && file payment.pdf | grep PDF && true
	./node_modules/coffeescript/bin/coffee --nodejs --stack_size=4096 testdata/test_summary.coffee && file summary.pdf | grep PDF && true
	./node_modules/coffeescript/bin/coffee --nodejs --stack_size=4096 testdata/test_detailed.coffee && file detailed.pdf | grep PDF && true
	./node_modules/coffeescript/bin/coffee --nodejs --stack_size=4096 testdata/test_weekly.coffee && file weekly.pdf | grep PDF && true
	./node_modules/coffeescript/bin/coffee --nodejs --stack_size=4096 testdata/test_weekly_earnings.coffee && file weekly_earnings.pdf | grep PDF && true

fonts:
	./merge.ff app/fonts/src/OpenSans-Regular.ttf app/fonts/src/OpenSansHebrew-Regular.ttf
	@cp app/fonts/src/OpenSans-Regular-merged.ttf app/fonts/OpenSans-Regular.ttf
	./merge.ff app/fonts/src/OpenSans-Bold.ttf app/fonts/src/OpenSansHebrew-Bold.ttf
	@cp app/fonts/src/OpenSans-Bold-merged.ttf app/fonts/OpenSans-Bold.ttf
	@rm app/fonts/src/OpenSans*-merged.ttf

.PHONY: node_modules
