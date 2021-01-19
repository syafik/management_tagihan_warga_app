# frozen_string_literal: true

module Api
  module V1
    class HomeController < Api::V1::BaseController
      def home_page
        render status: 200,  json: { 
          success: true, 
          me: current_user,
          tagihan: current_user.try(:address).try(:tagihan_now), 
          last_payment: current_user.try(:address).try(:last_payment_contribution), 
          blok: current_user.address ? current_user.address.block_address : "-",
          info: AppSetting.first.home_page_text % {user: current_user.name, greeting: Time.greeting_message_time },
          cash_flow: CashFlow.info((Date.current-1.month).month, (Date.current-1.month).year),
          notifications: current_user.user_notifications.includes(:notification).order('created_at DESC').limit(3).as_json(methods: [:notification])
        }
      end

      def user_lists
        users = User.includes(:address).where(kk: true)
        render status: :ok, json: { success: true, 
          users: users.as_json(methods: [:blok_name])
        }
      end

      def cash_flows
        cash_flows = CashFlow.where(year: params[:year]).order('month ASC')
        total_cash_in = cash_flows.sum(&:cash_in)
        total_cash_out = cash_flows.sum(&:cash_out)
        grand_total = cash_flows.sum(&:total)
        render json: { success: true, title: "Cash Flow Tahun #{params[:year]}", total_cash_in: total_cash_in, total_cash_out: total_cash_out, grand_total: grand_total, cash_flows: cash_flows.as_json(:methods => [:month_info]) }, status: :ok
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
          item = {}
          if value.is_a?(Array)
            total = cash_transactions.select { |t| value.include?(t.transaction_group) }.sum(&:total)
            if key.include?('PEMASUKAN')
              item[:type] = 'cash_in'
              debit_total += total
            else
              item[:type] = 'cash_out'
              credit_total += total
            end
            item[:transaction_date] = '-'
            item[:description] = key
            item[:total] = total
            report_items << item
          else
            cash_transactions.select { |t| value == t.transaction_group }.each do |t|
              if key.include?('PEMASUKAN')
                item[:type] = 'cash_in'
                debit_total += t.total
              else
                item[:type] = 'cash_out'
                credit_total += t.total
              end
              item[:transaction_date] = t.transaction_date.strftime('%d %B %Y')
              item[:description] = t.description
              item[:total] = t.total
              report_items << item
            end
          end
        end
        render json: { success: true, title: "Transaksi Kas Per #{UserContribution::MONTHNAMES.invert[params[:month].to_i]} #{params[:year]}", transactions: report_items, debit_total: debit_total, credit_total: credit_total, grand_total: debit_total-credit_total }, status: :ok
      end

      def contributions
        contributions = current_user.address.try(:user_contributions).order('created_at DESC')
        render json: { success: true, title: "Tagihan Anda per #{UserContribution::MONTHNAMES.invert[Date.current.month]} #{Date.current.year}", tagihan: "#{current_user.address.try(:tagihan_now)}",  contributions: contributions.as_json(:methods => [:contribution_desc, :tgl_bayar])}, status: :ok
      end

      def address_info
        address = Address.includes(:users, :user_contributions).where(block_address: params[:block].gsub(/[^0-9A-Za-z]/, '').upcase).first
        if address
          render json: { success: true, address: address, users: address.users, tagihan: address.tagihan_now }, status: :ok
        else
          render status: 404, json: {success: false, message: 'Address not found'}
        end
      end

      def pay_contribution
        address = Address.find(params[:address_id])
        return render status:402, json:{success: true, message: 'pembayaran iuran gagal.', error: 'invalid address_id'} if address.nil?
        uc = UserContribution.new(
            month: Date.current.month,
            year: Date.current.year,
            address_id: address.id,
            contribution: params[:contribution],
            receiver_id: current_user.id,
            pay_at: params[:pay_at],
            payment_type: params[:payment_type],
            blok: params[:blok]
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
          notification = Notification.create(title: "Pembayaran Iuran Bulanan Sukses!", notif: "Terima Kasih atas pembayara iuran bulanan yang telah dilakukan. \n Anda membayar sebanyak #{params[:total_bayar]} kali tagihan sebesar #{(params[:total_bayar].to_i*params[:contribution].to_f)}, dan sudah diterima oleh #{current_user.name} Secara #{params[:payment_type].to_i == 2 ? 'TRANSFER' : 'CASH'} tanggal #{uc.pay_at.strftime('%d %B %Y')}.")
          SendNotificationToUsersJob.perform_later(notification.id, 1, address.users.pluck(:id))
          render json: { success: true, message: 'pembayaran iuran berhasil dilakukan.'}, status: :ok
        else
          render status:402, json:{success: false, message: "Pembayaran iuran gagal. #{uc.errors.full_messages.join(", ")}"}
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
          render json: { success: true, message: 'transaksi berhasil disimpan.' }, status: :ok
        else
          render status:402, json:{success: false, message: 'transaksi gagal disimpan.', error: ct.errors}
        end
      end

      def notifications
        user_notifications =  current_user.user_notifications.includes(:notification).order('created_at DESC').limit(20)
        render json: { success: true, user_notifications: user_notifications.as_json(methods: [:notification]) }, status: :ok
      end

      def notification_show
        notification = Notification.find(params[:id])
        notification.read_by(current_user)
        render json: { success: true, notification: notification }, status: :ok
      end

      def add_notification
        notification = Notification.new(title: params[:title], notif: params[:notif])
        if notification.save
          SendNotificationToUsersJob.perform_later(notification.id, 1, [])
          render json: { success: true, message: 'notifikasi berhasil disimpan dan dikirim.'}, status: :ok
        else
          render status:402, json:{success: false, message: 'notifikasi gagal disimpan.', error: notification.errors}
        end
      end

      def debts
        debts = current_user.debts
        total_pinjam = debts.select{|d| d.debt_type == 1}.sum(&:value)
        total_bayar = debts.select{|d| d.debt_type == 2}.sum(&:value)
        sisa_hutang = total_pinjam - total_bayar
        render status: :ok, json: {success: true, debts: debts, total_pinjam: total_pinjam, total_bayar: total_bayar, sisa_hutang: sisa_hutang}
      end

      def add_debt
          
      end

      def installments
        installments = Installment.includes(:installment_transactions).where('parent_id IS NULL')
        render status: :ok, json: {success: true, installments: installments.as_json(:methods => [:total_paid, :remaining_installment, :paid_off?])}
      end

      def installment_transaction
        installment = Installment.find(params[:id])
        installment_transactions = installment.installment_transactions
        render status: :ok, json: {success: true, installment: installment.as_json(:methods => [:total_paid, :remaining_installment, :paid_off?]), installment_transactions: installment_transactions}
      end

      def add_installment
        
      end

      def pay_installment

      end

    end
  end
end
