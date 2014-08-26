WeeklyReport  = require '../app/weekly_report'
data = require './data/weekly.json'

data.params =
  since: '2013-12-09'
  until: '2013-12-15'
  grouping: 'projects'
  tag_names: 'Master, Productive, nobill'
  task_names: 'Top-secret, Trip to Tokio'

report = new WeeklyReport data
report.write 'weekly.pdf'
