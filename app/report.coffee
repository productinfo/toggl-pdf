PDFDocument = require 'pdfkit'
bugsnag     = require 'bugsnag'
timeFormat  = require 'time-format-utils'

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

  output: (stream) ->
    @doc.pipe stream
    @finalize()
    @doc.end()

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

  groupSize: (group) ->
    group.split(',').length

  groupToLenght: (group, length) ->
    group.split(',').slice(0, length).join(', ')

  isFree: ->
    return not @data.env?.workspace?.pro

  createdWith: ->
    @doc.text 'Created with toggl.com', 473, 1, width: 0

  shortDuration: (seconds) =>
    splits = @splitDuration seconds
    "#{splits[0]} h #{splits[1]} min"

  timing: (name, func) ->
    console.time name
    func()
    console.timeEnd name

  displayDuration: (milliseconds) ->
    displayType = @data.params?.time_format_mode
    displayType ||= 'classic'
    result = timeFormat.secondsToExtHhmmss((milliseconds / 1000), displayType)
    if displayType is 'improved'
      return result.replace(/<[^>]*>/g, '') # time-format-utils returns some html with the improved type...
    return result

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
    unless @isFree()
      @doc.fontSize(10).text @shortDuration(@data.total_billable), 205, 50
      @doc.fontSize(10).text amounts.join(', '), 285, 50

    @doc.fillColor '#929292'
    @doc.fontSize(10).text 'Total', 35, 50
    unless @isFree()
      @doc.fontSize(10).text 'Billable', 165, 50

  selectedFilters: ->
    yPos = 1
    for group in ['user', 'project', 'client', 'task', 'tag']
      @doc.fontSize(10).fillColor('#000')
      if @data.params["#{group}_names"]?.length > 0
        group_filter = @groupToLenght("#{@data.params["#{group}_names"]}", 3)
        group_size = @int @data.params["#{group}_count"]
        
        # if the _count parameter is missing, try to guess the value
        if isNaN(group_size)
          group_size = @groupSize(@data.params["#{group}_names"])
        if group_filter.length > 60
          group_filter = group_filter.substring(0, 59) + '...'
        @doc.text group_filter, 35, yPos

        textWidth = @doc.widthOfString group_filter
        prefix = if group_size > 3 then " and #{group_size - 3} more" else ""
        if textWidth > 420
          textWidth = 420
        @doc.fillColor('#929292').text "#{prefix} selected as #{group}s", 38 + textWidth, yPos
        yPos += 15
    @translate 0, yPos - 15

module.exports = Report
