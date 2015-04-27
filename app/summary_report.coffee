Report = require './report'
moment = require 'moment'

RAD = Math.PI / 180
COLORS = ['#F2C5FE', '#A18CCA', '#8DE7FE', '#31B4DE',
  '#DDCAB1', '#8E4F00', '#DB8820', '#404775']

class SummaryReport extends Report
  finalize: ->
    @translate 0, 50
    @reportHeader('Summary report')

    @translate 0, 75
    @selectedFilters()

    @translate 0, 50
    @barChart()

    @translate 0, 180
    @pieChart()

    @translate 280, 0
    @subPieChart()

    @addPage()
    @reportTable()

    @translate 0, 10
    @createdWith()

  fileName: ->
    "Toggl_#{@data.params?.grouping}_#{@data.params?.since}_to_#{@data.params?.until}"

  sector: (cx, cy, r, startAngle, endAngle) ->
    sweepFlag = endAngle - startAngle > 180
    x1 = cx - r * Math.cos -startAngle * RAD
    y1 = cy + r * Math.sin -startAngle * RAD

    x2 = cx - r * Math.cos -endAngle * RAD
    y2 = cy + r * Math.sin -endAngle * RAD
    ["M", cx, cy, "L", x1, y1, "A", r, r, 0, +sweepFlag, 1, x2, y2, "z"]

  barChart: ->
    @data.activity.rows.sort (a, b) -> a[0] - b[0]
    dates = []
    values = []
    for row in @data.activity.rows
      values.push if row[1] then row[1] / 3600.0 else 0.0
      dates.push moment(row[0])
    maxValue = Math.ceil Math.max.apply(null, values)
    heights =
      for val in values
        if maxValue > 0 and val > 0
          Math.ceil val / maxValue * 120
        else
          0

    # Draw barchart grid
    @doc.lineWidth(0.5).strokeColor '#e6e6e6'
    @doc.moveTo(35, 5).lineTo(540, 5).dash(1, space: 1).stroke()
    @doc.moveTo(35, 35).lineTo(540, 35).dash(1, space: 1).stroke()
    @doc.moveTo(35, 65).lineTo(540, 65).dash(1, space: 1).stroke()
    @doc.moveTo(35, 95).lineTo(540, 95).dash(1, space: 1).stroke()
    @doc.moveTo(35, 145).lineTo(540, 145).dash(1, space: 1).stroke()

    yAxisText = (val) ->
      if val > 10
        "#{Math.round(val)} h"
      else
        "#{val.toFixed(2)} h"

    @doc.fontSize(9).fillColor '#6d6d6d'
    if maxValue > 0
      @doc.text yAxisText(maxValue), 550, 0.1, width: 0
      @doc.text yAxisText(maxValue * 0.75), 550, 30, width: 0
      @doc.text yAxisText(maxValue * 0.5), 550, 60, width: 0
      @doc.text yAxisText(maxValue * 0.25), 550, 90, width: 0

    MAX_DAYS = 31
    BAR_PADDING = 4
    PADDING_LEFT = 45
    MIN_BAR_WIDTH = 12
    MAX_BAR_HEIGHT = 125

    barCount = @data.activity.rows.length
    barWidth = MAX_DAYS / barCount * MIN_BAR_WIDTH
    barWidthPad = barWidth + BAR_PADDING
    @doc.font('FontBold').fontSize 8

    # Draw barchart bars
    cx = PADDING_LEFT
    for height, i in values
      if height == 0
        @doc.rect(cx, MAX_BAR_HEIGHT, barWidth, -2).fill '#929292'
      else
        @doc.rect(cx, MAX_BAR_HEIGHT, barWidth, -heights[i]).fill '#2cc1e6'
      # Draw labels above bars
      if barCount <= 16
        @doc.text values[i].toFixed(2), cx, MAX_BAR_HEIGHT - heights[i] - 15, width: barWidth, align: 'center'
      cx += barWidthPad

    # Draw barchart horizontal date labels
    cx = PADDING_LEFT
    zoom = @data.activity.zoom_level
    dateFormat = switch zoom
      when 'day' then 'Do MMM'
      when 'week' then 'DD.MM - DD.MM'
      when 'month' then 'MMM'

    @doc.font('FontRegular').fontSize 7
    @doc.undash().lineWidth(0.5).strokeColor '#6d6d6d'

    modValue = if barCount <= 12 then 1
    else if barCount > 12 and barCount <= 22 then 2
    else if barCount > 22 then 3
    modValue = 2 if zoom == 'week' and barCount > 8

    halfBar = barWidth / 2
    for height, i in values
      if i % modValue == 0
        @doc.moveTo(cx + halfBar, MAX_BAR_HEIGHT + 2).lineTo(cx + halfBar, MAX_BAR_HEIGHT + 5).stroke()
        @doc.fill('#6d6d6d').text dates[i].format(dateFormat), cx - (barWidthPad / 2) - 2, 125 + 5, width: barWidthPad * 2, align: 'center'
      cx += barWidthPad


  subPieChart: ->
    @pieChart 'subgrouping'

  grouping: (groupingType) ->
    @data.params?[groupingType] or @data.env[groupingType]

  pieChart: (part = 'grouping') ->
    title = @capitalize @grouping(part)

    @doc.fontSize(14).fill('#000').text title, 50, 1

    groups = []
    otherTotal = 0
    filterOthers = (time, name, threshold) =>
      if time / @data.total_grand > threshold
        groups.push name: name, time: time
      else
        otherTotal += time

    if part is 'subgrouping'
      subgroups = {}
      for group, i in @data.data
        for item, i in group.items
          subgroups[item.title] = 0 unless subgroups[item.title]?
          subgroups[item.title] += item.time

      filterOthers(time, name, 0.05) for name, time of subgroups
    else
      filterOthers(time, name, 0.06) for {time: time, title: name} in @data.data

    groups.sort (a, b) -> b.time - a.time
    groups.push {name: 'Other', time: otherTotal} if otherTotal > 0

    # Donut chart
    angle = 90
    for group, i in groups
      angleplus = 360 * group.time / @data.total_grand
      path = @sector 150, 130, 100, angle, angle + angleplus
      @doc.path(path.join(', ')).fill COLORS[i]
      angle += angleplus
    @doc.circle(150, 130, 40).fill "#fff"

    # Donut labels
    @doc.fontSize 10
    cy = 255
    for group, i in groups
      @doc.circle(63, cy, 8).fill COLORS[i]
      groupName = if group.name.length > 30
        group.name.substr(0, 25) + '...'
      else
        group.name
      @doc.fillColor('#000000').text groupName, 83, cy - 6, width: 200
      labelWidth = @doc.widthOfString groupName
      @doc.fillColor('#6d6d6d').text @displayDuration(group.time), 93 + labelWidth, cy - 6
      cy = cy + 20

  getTitle = (title) ->
    title or '(no title)'

  reportTable: ->
    @translate 0, 20
    @doc.fontSize(7)
    @doc.font('FontBold').fill '#6f7071'
    @doc.text "#{@capitalize(@grouping 'grouping')} / #{@capitalize(@grouping 'subgrouping')}", 55, 10
    @doc.text 'Duration', 390, 10
    @doc.text 'Amount', 450, 10

    @translate 0, 20
    @doc.fill('#000000')
    for group in @data.data
      @doc.font 'FontBold'
      @doc.text group.title, 55, 10
      @doc.text @displayDuration(group.time), 390, 10
      amounts = for cur in group.total_currencies when cur.amount?
        cur.amount.toFixed(2) + " " + cur.currency
      @doc.text amounts.join(', '), 450, 10
      @translate 0, 20

      @doc.font 'FontRegular'
      for item in group.items
        lineHeight = 90
        title      = getTitle item.title
        lineCount  = title.length / lineHeight
        @doc.text title, 60, 10, width: 330, lineCap: lineCount
        @doc.text @displayDuration(item.time), 390, 10
        @doc.text item.sum.toFixed(2) + " " + item.cur, 450, 10 if item.sum? and item.sum > 0
        @translate 0, 20

        # If the we have multiline description then lets move the lines down
        @translate 0, lineCount * 9 if lineCount > 0

        if @posY > Report.PAGE_HEIGHT - Report.MARGIN_BOTTOM
          @doc.text ++@pageNum
          @addPage()
          @translate 0, 20

module.exports = SummaryReport
