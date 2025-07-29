class Admin::InvoiceRecipientsController < Admin::BaseController
  before_action :set_invoice_recipient

  def index
    # 単一の請求先情報を表示・編集する画面
    # indexビューで直接表示するため、特別な処理は不要
  end

  def show
    # indexと同じ処理
    redirect_to admin_invoice_recipients_path
  end

  def new
    # 新規作成フォームを表示（既に存在する場合は編集画面にリダイレクト）
    if @invoice_recipient.persisted?
      redirect_to edit_admin_invoice_recipient_path(@invoice_recipient)
    end
  end

  def create
    # 既存のレコードがある場合は更新、ない場合は新規作成
    if @invoice_recipient.persisted?
      # 既存レコードの更新
      if @invoice_recipient.update(invoice_recipient_params)
        redirect_to admin_invoice_recipient_path, notice: '請求先情報が保存されました。'
      else
        render :index
      end
    else
      # 新規レコードの作成
      @invoice_recipient.assign_attributes(invoice_recipient_params)
      @invoice_recipient.user_id = current_user.id  # 管理者のIDを設定
      if @invoice_recipient.save
        redirect_to admin_invoice_recipient_path, notice: '請求先情報が保存されました。'
      else
        render :index
      end
    end
  end

  def edit
    # 編集フォームを表示
  end

  def update
    if @invoice_recipient.update(invoice_recipient_params)
      redirect_to admin_invoice_recipients_path, notice: '請求先情報が更新されました。'
    else
      render :edit
    end
  end

  def destroy
    # 削除は行わず、データをクリアする
    @invoice_recipient.update(
      name: nil,
      email: nil,
      postal_code: nil,
      address: nil,
      tel: nil,
      department: nil,
      notes: nil
    )
    redirect_to admin_invoice_recipients_path, notice: '請求先情報がクリアされました。'
  end

  private

  def set_invoice_recipient
    # 最初のレコードを取得、存在しない場合は新規作成
    @invoice_recipient = InvoiceRecipient.first || InvoiceRecipient.new
  end

  def invoice_recipient_params
    # user_idは不要（会社全体で1つのため）
    params.require(:invoice_recipient).permit(:name, :representative_name, :email, :postal_code, :address, :tel, :department, :notes)
  end
end