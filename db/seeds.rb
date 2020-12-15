# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
require 'csv'

admins = %w[D2 D3]
csv_text = File.read('datawarga.csv')
csv = CSV.parse(csv_text, headers: false)
csv.each do |row|
  address = Address.new(
    block_address: row[1].downcase,
    contribution: row[5].gsub(/[^\d]/, '').to_i,
    arrears: row[6]
  )
  address.save
  user = User.new(
    email: "#{row[1].downcase}@puriayana.com",
    name: row[0],
    password: 'password123',
    address_id: address.id,
    phone_number: '08019203901923'
  )
  user.role = 2 if admins.include?(address.block_address.upcase)
  user.save
end

# add user sekurity

yudi = User.create(
  email: 'yudi@puriayana.com', phone_number: '08019203901923',
  name: 'Yudi', password: 'password123', role: 3
)

yadi = User.create(
  email: 'yadi@puriayana.com',
  name: 'Yadi', password: 'password123', phone_number: '08019203901923', role: 3
)

slamet = User.create(
  email: 'slamet@puriayana.com',
  name: 'slamet', password: 'password123', phone_number: '08019203901923', role: 3
)

idan = User.create(
  email: 'wildan@puriayana.com',
  name: 'wildan', password: 'password123', phone_number: '08019203901923',
  role: 3
)

blocks = {
  'A' => idan.id,
  'B' => yudi.id,
  'C' => yudi.id,
  'D' => yadi.id,
  'F' => slamet.id
}

csv_text = File.read('iuran_warga.csv')
csv = CSV.parse(csv_text, headers: false)
csv.each do |row|
  address = Address.where(block_address: row[1].strip).first
  next unless address

  1.upto(4 - row[6].to_i) do |i|
    blok = row[1].strip[0]
    receiver = blocks[blok]
    UserContribution.create(address_id: user.id, month: i, year: 2020, contribution: row[5],
                            pay_at: "2020-#{i}-2 10:00:00", payment_type: 1, receiver_id: receiver)
  end
end
