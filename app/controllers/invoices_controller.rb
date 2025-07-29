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
    @invoice_recipients = current_user.invoice_recipients
    
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
    
    if @invoice.save
      redirect_to invoices_path, notice: '請求書が作成されました。'
    else
      @invoice_recipients = current_user.invoice_recipients
      render :issue
    end
  end

  def edit
    @invoice = current_user.invoices.find(params[:id])
    @invoice_recipients = current_user.invoice_recipients
  end

  def update
    @invoice = current_user.invoices.find(params[:id])
    
    if @invoice.update(invoice_params)
      redirect_to invoice_path(@invoice), notice: '請求書が更新されました。'
    else
      @invoice_recipients = current_user.invoice_recipients
      render :edit
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
    params.require(:invoice_base).permit(:company_name, :postal_code, :address, :department, :email, :notes)
  end
end