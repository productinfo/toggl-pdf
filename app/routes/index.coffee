url         = require 'url'
async       = require 'async'
https       = require 'https'
bugsnag     = require 'bugsnag'
querystring = require 'querystring'

Invoice        = require '../invoice'
Payment        = require '../payment'
WeeklyReport   = require '../weekly_report'
SummaryReport  = require '../summary_report'
DetailedReport = require '../detailed_report'

exports.getWeekly = (req, res) ->
  report = new WeeklyReport
  dataPath = getReportUrl 'weekly.json'
  generateReport report, dataPath, req, res

exports.getDetails = (req, res) ->
  report = new DetailedReport
  dataPath = getReportUrl 'details.json'
  generateReport report, dataPath, req, res

exports.getSummary = (req, res) ->
  report = new SummaryReport
  dataPath = getReportUrl 'summary.json'
  generateReport report, dataPath, req, res

exports.getInvoice = (req, res) ->
  invoice = new Invoice
  dataPath = getInvoiceUrl req.params
  generatePayment invoice, dataPath, req, res

exports.getPayment = (req, res) ->
  payment = new Payment
  dataPath = getPaymentUrl req.params
  generatePayment payment, dataPath, req, res

exports.getStatus = (req, res) ->
  res.send 200, 'OK'

exports.notFound = (req, res, next) ->
  res.send 404, 'This is not the page you are looking for!'

exports.internalError = (err, req, res, next) ->
  bugsnag.notify err,
    headers: req['headers'],
    parsedUrl: req['_parsedUrl']
  res.send 500, 'Looks like something went wrong!'

###### Helpers ######

getReportUrl = (path) ->
  "/reports/api/v2/#{path}"

getInvoiceUrl = (params) ->
  "/api/v8/workspaces/#{params['workspace_id']}/invoices/#{params['id']}"

getPaymentUrl = (params) ->
  "/api/v8/workspaces/#{params['workspace_id']}/payments/#{params['id']}"

pdfHeaders = (filename) ->
  'Content-Type': 'application/pdf'
  'Content-Disposition': "attachment; filename=#{filename}.pdf"

makeRequest = (queryPath, headers, cb) ->
  apiHost = process.env.API_HOST or 'www.toggl.com'
  options =
    path: queryPath
    hostname: apiHost
    headers: headers

  request =  https.get options
  request.on 'response', (res) ->
    chunks = []
    res.on 'data', (chunk) -> chunks.push(chunk)

    res.on 'error', (err) ->
      console.log 'error'
      cb err, null

    res.on 'end', ->
      if res.statusCode is 200
        cb null, JSON.parse chunks.join('')
      else
        cb "API responded with #{res.statusCode} - #{chunks.join('')}", null

fetchImage = (data, cb) ->
  logo = data.logo or data.workspace?.logo
  return cb(null, data) unless logo?
  parts = url.parse logo
  options =
    path: parts.path
    host: parts.host
  request =  https.get options
  request.on 'error', -> cb(null, data)
  request.on 'response', (res) ->
    chunks = []
    res.setEncoding('binary')
    res.on 'data', (chunk) -> chunks.push(chunk)
    res.on 'end', ->
      data.logo = new Buffer chunks.join(''), 'binary' if res.statusCode is 200
      cb null, data

generatePayment = (payment, dataPath, req, res) ->
  headers = cookie: req.headers.cookie, authorization: req.headers.authorization
  makeRequest dataPath, headers, (err, results) ->
    if err?
      console.log "generatePayment FAILED", dataPath, err
      if err.indexOf("API responded with 403") > -1
        res.send 403, 'Session has expired, log in again.'
      else
        res.send 400, 'Bad request'
    else
      payment.data = results.data
      
      res.writeHead 200, pdfHeaders(payment.fileName())
      payment.output(res)

generateReport = (report, dataPath, req, res) ->
  parsedURL = url.parse req.url
  envPath   = getReportUrl "env.json?#{parsedURL.query}"
  headers   = cookie: req.headers.cookie, authorization: req.headers.authorization
  params    = querystring.parse parsedURL.query
  dataPath  = dataPath + "?view=print&string_title=true&bars_count=31&#{parsedURL.query}"

  if params.bookmark_token
    envPath = getReportUrl "bookmark/#{params.bookmark_token}"

  makePdf = (err, results) ->
    if err?
      console.log 'generateReport FAILED', err, results
      if err.indexOf("API responded with 403") > -1
        res.writeHead 403, 'Content-Type': 'text/plain'
        res.end 'Session has expired, log in again.'
      else
        res.writeHead 400, 'Content-Type': 'text/plain'
        res.end 'Bad request'
    else
      report.data = results.data
      report.data.params = params
      report.data.env = results.env

      console.time("  * PDF time")
      res.writeHead 200, pdfHeaders(report.fileName())
      report.output(res)

  apiRequests =
    env: (callback) ->
      makeRequest envPath, headers, (err, data) ->
        if err? then callback(err, data) else fetchImage(data, callback)
    data: (callback) ->
      makeRequest dataPath, headers, (err, data) -> callback(err, data)

  async.parallel apiRequests, makePdf
