Report = require './report'
moment = require 'moment'

class WeeklyReport extends Report
  constructor: (@data) ->
    @LEFT = 35
    super @data

  finalize: ->
    @translate 0, 50
    @reportHeader 'Weekly report'

    @translate 0, 75
    @selectedFilters()

    @translate 0, 30
    @reportTable()

    @translate 0, 10
    @createdWith()

  fileName: ->
    "Toggl #{@data.params?.grouping} #{@data.params?.since} to #{@data.params?.until}"

  reportTable: ->
    @doc.font('FontBold').fontSize(7).fill('#6f7071')
    @doc.text 'Client - project', @LEFT, 1

    day = moment @data.params['since']
    for dayNum in [0...7]
      @doc.text day.format('MMM D'), 250 + dayNum * 40, 1
      day.add 1, 'day'
    @doc.text 'Total', 530, 1, width: 0
    @translate 0, 15

    @doc.fill('#000').strokeColor('#dde7f7')
    for row in @data.data
      @doc.font 'FontBold'
      @drawRow row
      for subRow in row.details
        @doc.font 'FontRegular'
        @drawRow subRow

  rowTitle: (row) ->
    names = []
    names.push row.user if row.user?
    names.push row.client if row.client?
    names.push row.project if row.project?
    names.push '(no project)' if names.length < 1
    names.join ' - '

  slotDuration: (seconds) ->
    if seconds > 0
      @splitDuration(seconds).slice(0, 2).join(':')
    else
      ""

  drawRow: (row) ->
    @doc.text @rowTitle(row.title), @LEFT, 1
    for slot, i in row.totals
      @doc.text @slotDuration(slot), 250 + i * 40, 1, width: 0
    @translate 0, 15
    if @posY > Report.PAGE_HEIGHT - Report.MARGIN_BOTTOM
      @addPage()
      @translate 0, 30

module.exports =  WeeklyReport
