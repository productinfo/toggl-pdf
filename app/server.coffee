http    = require 'http'
path    = require 'path'
express = require 'express'
bugsnag = require 'bugsnag'
morgan  = require('morgan')
routes  = require './routes'

if process.env.BUGSNAG_KEY
  bugsnag.register process.env.BUGSNAG_KEY

app = express()
app.set 'port', process.env.PORT || 8900
app.use bugsnag.requestHandler
app.use morgan('combined')
#app.use routes.notFound
#app.use routes.internalError

app.get "/status", routes.getStatus
app.get "/reports/api/v2/summary.pdf", routes.getSummary
app.get "/reports/api/v2/details.pdf", routes.getDetails
app.get "/reports/api/v2/weekly.pdf",  routes.getWeekly
app.get "/workspaces/:workspace_id/invoices/:id.pdf", routes.getInvoice
app.get "/workspaces/:workspace_id/payments/:id.pdf", routes.getPayment
app.get "/workspaces/:workspace_id/prepayments/:id.pdf", routes.getPrepayment

server = http.createServer(app).listen app.get('port'), ->
  console.log 'Server at http://127.0.0.1:' + app.get('port'), 'started with conf:', JSON.stringify {
    API_HOST: process.env.API_HOST or 'https://www.toggl.com'
    REPORTS_API_HOST: process.env.REPORTS_API_HOST or 'https://www.toggl.com'
    NODE_ENV: process.env.NODE_ENV or 'none'
  }, null, 2

server.timeout = 29000
