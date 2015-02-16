http    = require 'http'
path    = require 'path'
express = require 'express'
bugsnag = require 'bugsnag'
routes  = require './routes'

if process.env.BUGSNAG_KEY
  bugsnag.register process.env.BUGSNAG_KEY

app = express()
app.set 'port', process.env.PORT || 8900
app.use bugsnag.requestHandler
app.use express.logger 'dev'
app.use app.router
app.use routes.notFound
app.use routes.internalError

app.get "/status", routes.getStatus
app.get "/reports/api/v2/summary.pdf", routes.getSummary
app.get "/reports/api/v2/details.pdf", routes.getDetails
app.get "/reports/api/v2/weekly.pdf",  routes.getWeekly
app.get "/workspaces/:workspace_id/invoices/:id.pdf", routes.getInvoice
app.get "/workspaces/:workspace_id/payments/:id.pdf", routes.getPayment

server = http.createServer(app).listen app.get('port'), ->
  console.log('Server at http://127.0.0.1:' + app.get 'port')
server.timeout = 29000