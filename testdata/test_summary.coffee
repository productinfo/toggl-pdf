SummaryReport  = require '../app/summary_report'
data = require './data/summary.json'

data.params =
  since: '2013-04-29'
  until: '2013-05-05'
  subgrouping: 'tasks'
  grouping: 'projects'
  time_format_mode: 'decimal'
  tag_names: 'Master, Productive, nobill'
  task_names: 'Top-secret, Trip to Tokio'

report = new SummaryReport(data)
report.write('summary.pdf')
