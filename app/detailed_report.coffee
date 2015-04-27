Report = require './report'
moment = require 'moment'

class DetailedReport extends Report
  constructor: (@data) ->
    @LEFT = 35
    super(@data)

  finalize: ->
    @translate 0, 50
    @reportHeader('Detailed report')

    @translate 0, 75
    @selectedFilters()

    @translate 0, 30
    @reportTable()

    @translate 0, 10
    @createdWith()

  fileName: ->
    "Toggl_time_entries_#{@data.params?.since}_to_#{@data.params?.until}"

  insertSpaces = (str) ->
    if str.length <= 79
      return str

    result = []
    for substr in str.split(' ')
      if substr.indexOf(' ') > 78 || (substr.indexOf(' ') == -1 && substr.length > 78)
        result.push insertSpaces([substr.slice(0, 78), ' ', substr.slice(78)].join(''))
      else
        result.push substr

    result.join(' ')

  getDescription = (description) ->
    if description
      insertSpaces description
    else
      '(no description)'

  calculateDuration: (duration) =>
    timeFormatMode = @data.params?.time_format_mode
    isDecimalFormat = timeFormatMode is 'decimal'
    fn = if isDecimalFormat then @decimalDuration else @classicDuration
    fn duration

  reportTable: ->
    @doc.font('FontBold').fontSize(7).fill('#6f7071')
    @doc.text 'Date', @LEFT, 1
    @doc.text 'Description', 65, 1
    @doc.text 'Duration', 405, 1
    @doc.text 'User', 465, 1
    @translate 0, 5

    @doc.fill('#000').strokeColor('#dde7f7')
    TSIZE = "2013-09-04T14:43:52".length
    for row, i in @data.data
      start       = moment(row.start[...TSIZE])
      description = getDescription row.description
      lineCount   = description.length / 90
      duration    = @displayDuration(row.dur)
      @doc.font 'FontBold'
      @doc.text "#{start.format('MM-DD')}", @LEFT, 7
      @doc.text description, 65, 9, { width: 330, lineCap: lineCount }
      @doc.text duration, 405, 7
      @doc.font 'FontRegular'
      @doc.text row.user, 465, 7, width: 120, height: 11

      # If the we have multiline description then lets move the lines down
      @translate 0, lineCount * 11 if lineCount > 0

      @doc.fontSize(7).fillColor 'grey'
      rowProject = if row.client? then "#{row.client} - " else ''
      rowProject += row.project or '(no project)'
      rowProject += " - #{row.task}" if row.task?
      rowProject += " - [#{row.tags.join(', ')}]" if row.tags.length > 0
      @doc.text rowProject?.slice(0, 90), 65, 22, width: 330, height: 11

      if row.use_stop
        stop = if row.end? then moment(row.end[...TSIZE]) else moment()
        @doc.text start.format('HH:mm') + '-' + stop.format('HH:mm'), 405, 20
      @doc.fillColor('black')
      if row.is_billable
        @doc.text row.billable + ' ' + row.cur, 465, 20

      @doc.lineWidth(0.5).moveTo(@LEFT, 35).lineTo(550, 35).stroke(1)
      @translate 0, 32
      if @posY > Report.PAGE_HEIGHT - Report.MARGIN_BOTTOM
        @addPage()
        @translate 0, 30
        @doc.strokeColor('#dde7f7')

module.exports = DetailedReport
