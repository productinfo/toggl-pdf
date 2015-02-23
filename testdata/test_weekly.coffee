WeeklyReport  = require '../app/weekly_report'
data = require './data/weekly.json'
fs = require 'fs'

data.params =
  since: '2013-12-09'
  until: '2013-12-15'
  grouping: 'projects'
  tag_names: 'Master, Productive, nobill'
  task_names: 'Top-secret, Trip to Tokio'
data.env =
  logo: './testdata/testlogo.png'

report = new WeeklyReport data
report.output(fs.createWriteStream('weekly.pdf'))