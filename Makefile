default: s

run:
	@coffee --nodejs --stack_size=4096 app/server.coffee

dist: dist_dir
	@coffee -co dist app
	@cp -R app/fonts dist/
	@cp -R app/images dist/
	@cp package.json dist/
	@cd dist && npm install --silent

dist_dir:
	@if [ ! -d "dist" ]; then mkdir -p dist; fi

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
