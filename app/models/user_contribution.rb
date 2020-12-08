class UserContribution < ApplicationRecord
  
  belongs_to :address
  belongs_to :receiver, class_name: "User"

  MONTHNAMES = 
   {
    "Januari" => 1,
    "Februari" => 2,
    "Maret" => 3,
    "April" => 4,
    "Mei" => 5,
    "Juni" => 6,
    "Juli" => 7,
    "Agustus" => 8,
    "September" => 9,
    "Oktober" => 10,
    "November" => 11,
    "Desember" => 12
}

  def self.import_existing_data(execute_month)
    session = GoogleDrive::Session.from_service_account_key("config/gdrive_project.json")
    Address::BLOK_NAME.each do |key, value|
      receiver = User.where("pic_blok LIKE '%#{key}%'").first
      ws = session.spreadsheet_by_key("1hiDj-EOxQ_vFtUMx9Wvp-gvq8J7QgElcrix6JN4VZtk").worksheets[value]
      (1..ws.num_rows).each do |row|
        block_address = ws[row, 2].strip
        contribution = ws[row, 3].strip
        tagihan = ws[row, 4].strip
        if row >= 3
          address = Address.where(block_address: block_address).first
          if address
            1.upto(execute_month-tagihan.to_i) do |i|
              UserContribution.create(
                year: 2020,
                address_id: address.id, 
                contribution: contribution.gsub(/[^\d]/, '').to_f,
                receiver_id: receiver.try(:id),
                blok: key
              )
            end
          end
        end
      end
    end
  end

  def contribution_long_desc
    desc = "LUNAS DAN DI TERIMA OLEH #{self.try(:receiver).try(:name).try(:upcase)}"
    desc += " TANGGAL #{self.pay_at.strftime('%d %B %Y')}" unless self.pay_at.blank?
    desc += " SECARA #{self.payment_type== 2 ? "TRANSFER" : "CASH"}"
    desc
  end

end
