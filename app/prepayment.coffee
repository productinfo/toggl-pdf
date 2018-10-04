PDFDocument = require 'pdfkit'
moment      = require 'moment'
util        = require 'util'

class Prepayment
  @PAGE_WIDTH = 595
  constructor: (@data) ->
    @doc = new PDFDocument size: 'A4'
    @initFonts()
    @LEFT = 35

  initFonts: ->
    @doc.registerFont('FontRegular', __dirname + '/fonts/NotoSans-Regular.ttf', 'Noto Sans')
    @doc.registerFont('FontBold', __dirname + '/fonts/NotoSans-Bold.ttf', 'Noto Sans Bold')
    @doc.font('FontRegular').fontSize(7)

  output: (stream) ->
    @doc.pipe stream
    @finalize()
    @doc.end()

  fileName: ->
    'toggl-purchase-order'

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
    @doc.text 'Prepayment invoice from Toggl LLC', 135, 10
    @doc.text 'Ravala 8 10143 Tallinn, Estonia', 135, 20
    @doc.text 'VAT: EE101124102', 135, 30
    @doc.text 'www.toggl.com', 470, 15, align: 'right', width: 75
    @doc.text 'support@toggl.com', 470, 25, align: 'right', width: 75
    @doc.rect(@LEFT, 1, 595-70, 45).lineWidth(0.5).dash(2, space: 2).stroke()

  invoiceNumber: ->
    headerWidth = 400
    @doc.font('FontBold').fontSize 20
    @doc.text "Prepayment invoice #N#{@data.id}", 595/2 - headerWidth/2, 10, align: 'center', width: headerWidth

  userDetails: ->
    createdAt = moment @data.created_at
    @doc.font('FontBold').fontSize 10
    @doc.text @data.company_name, @LEFT, 5
    @doc.font('FontRegular').fontSize 7
    @doc.text "#{@data.company_address} #{(if @data.country_name? then @data.country_name else '')}", @LEFT, 18
    @doc.text((if @data.contact_person? then @data.contact_person else ''), @LEFT, 28)
    @doc.text((if @data.vat_valid then @data.vat_number else ''), @LEFT, 38)
    @doc.font('FontRegular').fontSize 7
    @doc.text createdAt.format('MMMM D, YYYY'), 458, 20, align: 'right', width: 100
    @doc.text @status(), 458, 30, align: 'right', width: 100

  tableHeader: ->
    @doc.rect(@LEFT, 1, 595-70, 250).lineWidth(0.5).dash(2, space: 2).stroke()
    @doc.rect(@LEFT + 1, 2, 595-70-2, 20).fill('#eaebea')
    @doc.font('FontBold').fill('#000').fontSize 8
    @doc.text 'Description', 40, 5
    @doc.text 'Users', 300, 5
    @doc.text 'Amount', 505, 5, width: 0

  tableContent: ->
    @doc.text 'Toggl subscription', 40, 1
    @doc.font('FontRegular').fontSize 8
    @doc.text @data.users_in_workspace, 300, 1
    @doc.text " #{@data.amount_in_usd / 100} USD", 503, 1, width: 0

  tableFooter: ->
    alignOpts = align: 'right', width: 60
    @doc.text 'Amount', 440, 1
    @doc.text "$ #{@price().toFixed(2)} USD", 490, 1, alignOpts

    @doc.text "VAT #{@vatPercentage()}%", 440, 15
    @doc.text "$ #{@vatAmount().toFixed(2)} USD", 490, 15, alignOpts

    @doc.font('FontBold').text "Total", 440, 30
    @doc.text "$ #{@totalPrice().toFixed(2)} USD", 490, 30, alignOpts

  pageFooter: ->
    @doc.font('FontRegular')
    @doc.text 'All bank fees must be paid by a sender.', 405, 1, width: 0
    @doc.text 'Thank you!', 510, 15, width: 0

    @doc.font('FontBold').text 'Bank details:', @LEFT, 1, align: 'left', width: 0
    @doc.font('FontRegular').fontSize(8)
    @doc.text 'account/IBAN: EE561010220067136017', @LEFT + 60, 0, align: 'left', width: 0
    @doc.text 'beneficiarys bank: SEB Pank AS',     @LEFT + 60, 10, align: 'left', width: 0
    @doc.text 'Tornimäe 2, Tallinn Estonia',        @LEFT + 60, 20, align: 'left', width: 0
    @doc.text 'SWIFT/BIC: EEUHEE2X',                @LEFT + 60, 30, align: 'left', width: 0

  # Helpers
  status: ->
    if @data.cancelled_at?
      cancelledAt = moment @data.cancelled_at
      "Cancelled at: #{cancelledAt.format('MMMM D, YYYY')}"
    else if @data.paid_at?
      paidAt = moment @data.paid_at
      "Paid at: #{paidAt.format('MMMM D, YYYY')}"
    else
      "Not paid"

  price: ->
    amount = @data.amount_in_usd / 100.0
    if @data.discount_percentage > 0
      amount - (amount * @data.discount_percentage / 100.0)
    else
      amount

  vatPercentage: ->
    @data.vat_percentage

  vatAmount: ->
    if @vatPercentage() > 0
      @price() * @vatPercentage() / 100.0
    else
      0

  totalPrice: ->
    @price() + @vatAmount()

module.exports = Prepayment
