Payment = require '../app/payment'
payment = new Payment
  id: 4813834924847959
  description: 'Description'
  amount_in_usd: 135
  subscription_from: '04/11/2012'
  subscription_to: '05/10/2012'
  users_in_workspace: 5
  captured_at: '04/11/2012'
  profile: 13
  cancelled_at: null
  created_at: 'October 10, 2013'
  discount_percentage: 0
  vat_percentage: 20
  company_name: 'Toggl OU'
  company_address: 'Rävala 8'
  contact_person: 'Toggl employee'
  vat_number: 'EE12345678'

payment.write('payment.pdf')
