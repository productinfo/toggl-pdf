Prepayment = require '../app/prepayment'
fs = require 'fs'

prepayment = new Prepayment
  id: 142250
  workspace_id: 1
  users_in_workspace: 5
  amount_in_usd: 50
  contact_person: 'Jaan Jalgratas'
  company_name: 'Toggl OU'
  company_address: 'Rävala 8'
  country_id :61
  vat_number: 'EE12345678'
  vat_percentage: 20
  vat_valid: true
  vat_validated_at: '2015-01-01T00:00:00Z'
  created_at: '2015-01-01T00:00:00Z'
  deleted_at: null
  cancelled_at: null
  paid_at: null
  creator_id: 1

prepayment.output(fs.createWriteStream('prepayment.pdf'))
