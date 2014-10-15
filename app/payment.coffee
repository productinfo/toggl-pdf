PDFDocument = require 'pdfkit'
moment = require 'moment'

class Payment
  @PAGE_WIDTH = 595
  constructor: (@data) ->
    @doc = new PDFDocument size: 'A4'
    @initFonts()
    @LEFT = 35

  initFonts: ->
    @doc.registerFont('FontRegular', __dirname + '/fonts/OpenSans-Regular.ttf', 'Open Sans')
    @doc.registerFont('FontBold', __dirname + '/fonts/OpenSans-Bold.ttf', 'Open Sans Bold')
    @doc.font('FontRegular').fontSize(7)

  write: (filename) ->
    @finalize()
    @doc.write filename

  output: (cb) ->
    @finalize()
    @doc.output (result) => cb result

  fileName: ->
    "toggl-payment"

  finalize: ->
    @doc.translate 0, 35
    @drawHeader()

    @doc.translate 0, 55
    @invoiceNumber()

    @doc.translate 0, 30
    @userDetails()

    @doc.translate 0, 50
    @tableHeader()

    @doc.translate 0, 30
    @tableContent()

    @doc.translate 0, 175
    @tableFooter()

    @doc.translate 0, 60
    @pageFooter()

  drawHeader: ->
    @doc.image __dirname + '/images/toggl.png', 35, 5, fit: [98, 40]
    @doc.text 'Invoice from Toggl LLC', 135, 10
    @doc.text 'Ravala 8 10143 Tallinn, Estonia', 135, 20
    @doc.text 'VAT: EE101124102', 135, 30
    @doc.text 'www.toggl.com', 470, 15, align: 'right', width: 75
    @doc.text 'support@toggl.com', 470, 25, align: 'right', width: 75
    @doc.rect(@LEFT, 1, 595-70, 45).lineWidth(0.5).dash(2, space: 2).stroke()

  invoiceNumber: ->
    headerWidth = 350
    @doc.font('FontBold').fontSize 18
    @doc.text "Payment receipt #N#{@data.id}", 595/2 - headerWidth/2, 10, align: 'center', width: headerWidth
  
  userDetails: ->
    createdAt = moment @data.created_at
    @doc.font('FontBold').fontSize 10
    @doc.text @data.company_name, @LEFT, 5
    @doc.font('FontRegular').fontSize 7
    @doc.text "#{@data.company_address} #{(if @data.country? then @data.country else '')}", @LEFT, 18
    @doc.text @data.contact_person, @LEFT, 28
    @doc.text @data.vat_number, @LEFT, 38

    @doc.font('FontRegular').fontSize 7
    @doc.text createdAt.format('MMMM D, YYYY'), 458, 20, align: 'right', width: 100
    @doc.text @status(), 458, 30, align: 'right', width: 100

  tableHeader: ->
    @doc.rect(@LEFT, 1, 595-70, 250).lineWidth(0.5).dash(2, space: 2).stroke()
    @doc.rect(@LEFT + 1, 2, 595-70-2, 20).fill('#eaebea')
    @doc.font('FontBold').fill('#000').fontSize 8
    @doc.text 'Description', 40, 5
    @doc.text 'Amount', 505, 5, width: 0

  tableContent: ->
    @doc.text 'Toggl subscription', 40, 1
    @doc.font('FontRegular').fontSize 8
    @doc.text " #{@data.amount_in_usd} USD", 503, 1, width: 0

  tableFooter: ->
    alignOpts = align: 'right', width: 60
    @doc.text 'Amount', 440, 1
    @doc.text "#{@priceWithoutVAT().toFixed(2)} USD", 490, 1, alignOpts

    @doc.text "VAT #{@data.vat_percentage}%", 440, 15
    @doc.text "#{@vatAmount().toFixed(2)} USD", 490, 15, alignOpts

    @doc.font('FontBold').text "Total paid", 440, 30
    @doc.text "#{@data.amount_in_usd.toFixed(2)} USD", 490, 30, alignOpts

  pageFooter: ->
    @doc.font('FontRegular')
    @doc.text 'Thank you!', 510, 1, width: 0

  # Helpers
  status: ->
    if @data.cancelled_at?
      cancelledAt = moment @data.cancelled_at
      if cancelledAt?
        "Cancelled at: #{cancelledAt.format('MMMM D, YYYY')}"
      else
        "Cancelled at: #{@data.cancelled_at}"
    else if @data.captured_at?
      capturedAt = moment @data.captured_at
      if capturedAt?
        "Paid at: #{capturedAt.format('MMMM D, YYYY')}"
      else
        "Paid at: #{@data.captured_at}"
    else
      "Not paid"

  priceWithoutVAT: ->
    amount = @data.amount_in_usd
    if @data.vat_percentage > 0
      amount / (100.0 + @data.vat_percentage) * 100.0
    else
      amount

  vatAmount: ->
    @data.amount_in_usd - @priceWithoutVAT()

module.exports = Payment
