# frozen_string_literal: true

module Api
  module V1
    class HomeController < Api::V1::BaseController
      def home_page
        render status: 200,  json: { 
          status: true, 
          me: current_user,
          tagihan: current_user.try(:address).try(:tagihan_now), 
          last_payment: current_user.try(:address).try(:last_payment_contribution), 
          blok: current_user.address ? current_user.address.block_address : "-",
          info: AppSetting.first.home_page_text % {user: current_user.name, greeting: Time.greeting_message_time },
          cash_flow: CashFlow.info((Date.current-1.month).month, (Date.current-1.month).year),
          information: Notification.last
        }
      end

      def cash_flows
        cash_flows = CashFlow.where(year: params[:year])
        render json: { status: true, title: "Cash Flow Tahun #{params[:year]}", cash_flows: cash_flows }, status: :ok
      end

      def cash_transactions
        report_items = []
        debit_total = 0
        credit_total = 0
        year_selected = params[:year] || Date.current.year
        month_selected = params[:month] || Date.current.month
        selected_date = Date.parse("#{year_selected}-#{month_selected}-10") 
        cash_transactions = CashTransaction.where(transaction_date: selected_date.beginning_of_month..selected_date.end_of_month).order('transaction_date ASC')
        CashTransaction::REPORT_WARGA.each do |key, value|
          if value.is_a?(Array)
            total = cash_transactions.select { |t| value.include?(t.transaction_group) }.sum(&:total)
            if key.include?('PEMASUKAN')
              report_items << ['cash_in', '', key, total]
              debit_total += total
            else
              report_items << ['cash_out', '', key, total]
              credit_total += total
            end
          else
            cash_transactions.select { |t| value == t.transaction_group }.each do |t|
              if key.include?('PEMASUKAN')
                report_items << ['cash_in', t.transaction_date.strftime('%d %B %Y'), t.description, t.total]
                debit_total += t.total
              else
                report_items << ['cash_out', t.transaction_date.strftime('%d %B %Y'), t.description, t.total]
                credit_total += t.total
              end
            end
          end
        end
        render json: { status: true, title: "Transaksi Kas Per #{UserContribution::MONTHNAMES.invert[params[:month].to_i]} #{params[:year]}", transactions: report_items }, status: :ok
      end

      def contributions
        render json: { status: true, contributions: current_user.address.try(:user_contributions) }, status: :ok
      end

      def address_info
        address = Address.includes(:users, :user_contributions).where(block_address: params[:block].gsub(/[^0-9A-Za-z]/, '').upcase).first
        if address
          render json: { status: true, address: address, users: address.users, tagihan: address.tagihan_now }, status: :ok
        else
          render status: 404, json: {status: false, message: 'Address not found'}
        end
      end

      def pay_contribution
        address = Address.find(params[:address_id])
        return render status:402, json:{status: true, message: 'pembayaran iuran gagal.', error: 'invalid address_id'} if address.nil?
        uc = UserContribution.new(
            month: Date.current.month,
            year: Date.current.year,
            address_id: address.id,
            contribution: params[:contribution],
            receiver_id: current_user.id,
            pay_at: params[:pay_at],
            payment_type: params[:payment_type]
        )
        if uc.save
          1.upto(params[:total_bayar].to_i-1) do |_i|
            ucd = uc.dup
            ucd.save
          end unless params[:total_bayar].to_i > 1
          CashTransaction.create(
            month: Date.current.month,
            year: Date.current.month,
            transaction_date: params[:pay_at],
            transaction_type: CashTransaction::TYPE['DEBIT'],
            transaction_group: CashTransaction::GROUP['IURAN WARGA'],
            description: params[:total_bayar].to_i > 1 ? "#{params[:total_bayar].to_i} kali Iuran Warga Blok #{address.block_address}" : "Iuran Warga Blok #{address.block_address}" ,
            total: (params[:total_bayar].to_i*params[:contribution].to_f),
            pic_id: current_user.id
          )
          render json: { status: true, message: 'pembayaran iuran berhasil dilakukan.'}, status: :ok
        else
          render status:402, json:{status: false, message: 'pembayaran iuran gagal.', error: uc.errors}
        end
      end

      def add_transaction
        ct = CashTransaction.new(
          month: Date.current.month,
          year: Date.current.month,
          transaction_date: params[:transaction_date],
          transaction_type: params[:transaction_type],
          transaction_group: params[:transaction_group] ,
          description: params[:description] ,
          total: params[:total],
          pic_id: current_user.id
        )
        if ct.save
          render json: { status: true, message: 'transaksi berhasil disimpan.', address: address, users: address.users, tagihan: address.tagihan_now }, status: :ok
        else
          render status:402, json:{status: false, message: 'transaksi gagal disimpan.', error: ct.errors}
        end
      end
    end
  end
end
