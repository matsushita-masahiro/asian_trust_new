class InvoicesController < ApplicationController
  before_action :authenticate_user!

  def index
    # 請求書管理のメインページ
  end

  def history
    # 請求書履歴
    @invoices = current_user.invoices.includes(:invoice_recipient).order(created_at: :desc)
  end

  def issue
    # 請求書発行
    @invoice = current_user.invoices.build
    @invoice_recipients = InvoiceRecipient.all
    
    # 該当月の設定（パラメータから取得、なければ今月）
    @selected_month = params[:month].presence || Date.current.strftime("%Y-%m")
    @selected_month_start = Date.strptime(@selected_month, "%Y-%m").beginning_of_month
    @selected_month_end = Date.strptime(@selected_month, "%Y-%m").end_of_month
    
    # 該当月のボーナス合計額を計算
    @total_bonus = current_user.bonus_in_month(@selected_month)
    @invoice.total_amount = @total_bonus.to_i
    
    # ボーナス内訳を取得
    @bonus_details = get_bonus_details(@selected_month_start, @selected_month_end)
    
    # 既存のInvoiceBaseから振込先情報を取得
    @existing_invoice_base = current_user.invoice_base
    if @existing_invoice_base
      # 既存データがある場合は初期値として設定
      @invoice.bank_name = @existing_invoice_base.bank_name
      @invoice.bank_branch_name = @existing_invoice_base.bank_branch_name
      @invoice.bank_account_type = @existing_invoice_base.bank_account_type
      @invoice.bank_account_number = @existing_invoice_base.bank_account_number
      @invoice.bank_account_name = @existing_invoice_base.bank_account_name
    end
    
    # 請求先が設定されていない場合の警告
    if @invoice_recipients.empty?
      flash.now[:warning] = "請求先情報が設定されていません。先に請求書情報設定で請求先を登録してください。"
    end
  end

  def settings
    if request.post?
      # 請求元情報（invoice_base）を作成または更新
      @invoice_base = current_user.invoice_base || current_user.build_invoice_base
      
      if @invoice_base.update(invoice_base_params)
        redirect_to settings_invoices_path, notice: '請求元情報が保存されました。'
        return
      else
        flash.now[:error] = '請求元情報の保存に失敗しました。'
      end
    else
      @invoice_base = current_user.invoice_base || current_user.build_invoice_base
    end
  end

  def show
    @invoice = current_user.invoices.includes(:invoice_recipient).find(params[:id])
  end

  def new
    @invoice = current_user.invoices.build
    @invoice_recipients = current_user.invoice_recipients
  end

  def create
    @invoice = current_user.invoices.build(invoice_params)
    @invoice.status = Invoice::DRAFT  # 作成時は下書き状態
    
    if @invoice.save
      redirect_to invoice_path(@invoice), notice: '請求書が作成されました。内容を確認してください。'
    else
      @invoice_recipients = InvoiceRecipient.all
      # エラー時に必要な変数を再設定
      @selected_month = params[:month].presence || Date.current.strftime("%Y-%m")
      @selected_month_start = Date.strptime(@selected_month, "%Y-%m").beginning_of_month
      @selected_month_end = Date.strptime(@selected_month, "%Y-%m").end_of_month
      @total_bonus = current_user.bonus_in_month(@selected_month)
      @bonus_details = get_bonus_details(@selected_month_start, @selected_month_end)
      render :issue
    end
  end

  def edit
    @invoice = current_user.invoices.find(params[:id])
    @invoice_recipients = InvoiceRecipient.all
    
    # 請求書の発行日から対象月を推定
    @selected_month = @invoice.invoice_date&.strftime("%Y-%m") || Date.current.strftime("%Y-%m")
    @selected_month_start = Date.strptime(@selected_month, "%Y-%m").beginning_of_month
    @selected_month_end = Date.strptime(@selected_month, "%Y-%m").end_of_month
    
    # ボーナス内訳を取得
    @bonus_details = get_bonus_details(@selected_month_start, @selected_month_end)
    @total_bonus = current_user.bonus_in_month(@selected_month)
  end

  def update
    @invoice = current_user.invoices.find(params[:id])
    
    if @invoice.update(invoice_params)
      redirect_to invoice_path(@invoice), notice: '請求書が更新されました。'
    else
      @invoice_recipients = InvoiceRecipient.all
      render :edit
    end
  end

  def send_invoice
    @invoice = current_user.invoices.find(params[:id])
    
    # 送付処理（実際のメール送信などはここで実装）
    @invoice.update!(sent_at: Time.current, status: Invoice::SENT)
    
    redirect_to invoice_path(@invoice), notice: '請求書を送付しました。'
  end

  def receipt
    @invoice = current_user.invoices.find(params[:id])
    
    # 確認済みステータスのみ領収書発行可能
    unless @invoice.confirmed?
      redirect_to history_invoices_path, alert: '確認済みの請求書のみ領収書を発行できます。'
      return
    end
  end

  def send_receipt
    @invoice = current_user.invoices.find(params[:id])
    
    # 確認済みステータスのみ領収書発行可能
    unless @invoice.confirmed?
      redirect_to history_invoices_path, alert: '確認済みの請求書のみ領収書を発行できます。'
      return
    end

    # 領収書PDF生成とメール送信
    begin
      ReceiptMailer.send_receipt(@invoice).deliver_now
      @invoice.update!(receipt_sent_at: Time.current)
      redirect_to history_invoices_path, notice: '領収書を送付しました。'
    rescue => e
      Rails.logger.error "領収書送付エラー: #{e.message}"
      redirect_to receipt_invoice_path(@invoice), alert: '領収書の送付に失敗しました。'
    end
  end

  private

  def invoice_params
    params.require(:invoice).permit(:invoice_date, :due_date, :total_amount, :bank_name, :bank_branch_name, :bank_account_type, :bank_account_number, :bank_account_name, :notes, :sent_at, :invoice_recipient_id)
  end

  def invoice_recipient_params
    params.require(:invoice_recipient).permit(:name, :email, :postal_code, :address, :tel, :department, :notes)
  end

  def invoice_base_params
    params.require(:invoice_base).permit(:company_name, :postal_code, :address, :department, :email, :notes, :bank_name, :bank_branch_name, :bank_account_type, :bank_account_number, :bank_account_name)
  end

  def get_bonus_details(start_date, end_date)
    details = []
    
    # 自分の販売に対するボーナス
    self_purchases = current_user.purchases.where(purchased_at: start_date..end_date)
    self_purchases.each do |purchase|
      product = purchase.product
      base_price = product.base_price
      my_price = product.product_prices.find_by(level_id: current_user.level_id)&.price || 0
      bonus = (base_price - my_price) * purchase.quantity
      
      if bonus > 0
        details << {
          type: '自己販売',
          user_name: current_user.name || current_user.email,
          product_name: product.name,
          quantity: purchase.quantity,
          unit_bonus: bonus / purchase.quantity,
          total_bonus: bonus,
          purchased_at: purchase.purchased_at
        }
      end
    end
    
    # 子孫の販売に対するボーナス
    descendant_purchases = Purchase.includes(:product, :user)
                                   .where(user_id: current_user.descendant_ids)
                                   .where(purchased_at: start_date..end_date)
    
    descendant_purchases.each do |purchase|
      bonus = current_user.bonus_for_purchase(purchase)
      
      if bonus > 0
        details << {
          type: '下位販売',
          user_name: purchase.user.name || purchase.user.email,
          product_name: purchase.product.name,
          quantity: purchase.quantity,
          unit_bonus: bonus / purchase.quantity,
          total_bonus: bonus,
          purchased_at: purchase.purchased_at
        }
      end
    end
    
    # 日付順でソート
    details.sort_by { |d| d[:purchased_at] }
  end
end