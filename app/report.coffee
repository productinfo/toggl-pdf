PDFDocument = require 'pdfkit'
fs = require('fs')

class Report
  # 72 PPI A4 size in pixels
  @PAGE_WIDTH = 595
  @PAGE_HEIGHT = 842
  @MARGIN_BOTTOM = 50

  constructor: (@data) ->
    @pageNum = 1
    @posX = @posY = 0
    @doc = new PDFDocument size: 'A4'

    @initFonts()

  initFonts: ->
    @doc.registerFont('FontRegular', __dirname + '/fonts/NotoSans-Regular.ttf', 'Noto Sans')
    @doc.registerFont('FontBold', __dirname + '/fonts/NotoSans-Bold.ttf', 'Noto Sans Bold')
    @doc.font('FontRegular').fontSize(7)

  write: (filename) ->
    @doc.pipe fs.createWriteStream(filename)
    @finalize()
    @doc.end()

  output: (cb) ->
    @finalize()
    @doc.output (result) => cb result

  addPage: ->
    @doc.addPage()
    @posX = @posY = 0

  translate: (x, y) ->
    @posX += x
    @posY += y
    @doc.translate x, y

  zeroPad: (num) ->
    if num < 10 then '0' + num else num

  capitalize: (string) ->
    if string
      string = string.replace(/_/g, ' ')
      string[0].toUpperCase() + string[1..]
    else
      ''

  int: (str) ->
    parseInt str, 10

  createdWith: ->
    @doc.text 'Created with toggl.com', 473, 1, width: 0

  shortDuration: (seconds) =>
    splits = @splitDuration seconds
    "#{splits[0]} h #{splits[1]} min"

  timing: (name, func) ->
    console.time name
    func()
    console.timeEnd name

  decimalDuration: (milliseconds) ->
    (milliseconds / 1000 / 60 / 60).toFixed(2) + " h"

  classicDuration: (milliseconds) =>
    @splitDuration(milliseconds).join(':')

  splitDuration: (milliseconds) ->
    [
      @zeroPad(Math.floor(milliseconds / 3600000))
      @zeroPad(Math.floor(milliseconds % 3600000 / 60000))
      @zeroPad(Math.floor(milliseconds % 60000 / 1000))
    ]

  humanize: (paramName) ->
    {
    tag: 'Tags'
    task: 'Tasks'
    user: 'Users'
    client: 'Clients'
    project: 'Projects'
    }[paramName]

  reportHeader: (name) ->
    if @data.env?.name?
      name = @data.env.name
    @doc.fontSize(20).text name, 35, 1
    logo = @data.env?.logo or __dirname + '/images/toggl.png'
    try
      @doc.image logo, 480, -2, width: 80
    catch error
      console.log "IMAGE ERROR", @data.env?.logo

    @doc.fontSize(10).text "#{@data.params['since']}  -  #{@data.params['until']}", 35, 35

    amounts = for cur in @data.total_currencies when cur.amount > 0
      "#{cur.amount.toFixed(2)} #{cur.currency}"

    @doc.fontSize(10).text @shortDuration(@data.total_grand), 65, 50
    @doc.fontSize(10).text @shortDuration(@data.total_billable), 205, 50
    @doc.fontSize(10).text amounts.join(', '), 285, 50

    @doc.fillColor '#929292'
    @doc.fontSize(10).text 'Total', 35, 50
    @doc.fontSize(10).text 'Billable', 165, 50

  selectedFilters: ->
    yPos = 1
    for group in ['user', 'project', 'client', 'task', 'tag']
      @doc.fontSize(10).fillColor('#000')
      if @data.params["#{group}_names"]?.length > 0
        group_filter = "#{@data.params["#{group}_names"]}"
        group_size = @int @data.params["#{group}_count"]
        @doc.text group_filter, 35, yPos
        textWidth = @doc.widthOfString group_filter
        prefix = if group_size > 3 then " and #{group_size - 3} more" else ''
        @doc.fillColor('#929292').text "#{prefix} selected as #{group}s", 38 + textWidth, yPos
        yPos += 15
    @translate 0, yPos - 15

module.exports = Report
