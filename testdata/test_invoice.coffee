Invoice = require '../app/invoice'
invoice = new Invoice
  id: 142250
  description: 'Description'
  amount_in_usd: 135
  subscription_from: new Date
  subscription_to: new Date
  users_in_workspace: 5
  paid_at: null
  profile: 13
  cancelled_at: null
  created_at: 'October 10, 2013'
  discount_percentage: 0
  vat_percentage: 20
  company_name: 'Toggl OU'
  company_address: 'Rävala 8'
  contact_person: 'Toggl employee'
  vat_number: 'EE12345678'

invoice.write('invoice.pdf')
