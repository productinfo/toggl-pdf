DetailedReport  = require '../app/detailed_report'
data = require './data/detailed.json'
fs = require 'fs'

data.params =
  user_count: 4
  since: '2013-04-29'
  until: '2013-05-05'
  subgrouping: 'tasks'
  grouping: 'projects'
  time_format_mode: 'decimal'
  user_names: 'Katie, Mike, Nick, Paul'
  project_names: 'Toggl Support, Integrations, Факилиз вёвындо ад хёз, Ножтро аппэльлььантюр ыам ан'
  client_names: 'Toggl, Teamweek'

report = new DetailedReport(data)
report.output(fs.createWriteStream('detailed.pdf'))
