#!/usr/bin/env ruby
# PDFレポート生成スクリプト
# 使用方法: ruby scripts/generate_pdf.rb

require 'prawn'
require 'prawn/table'

class BonusVerificationDesignPDF
  def initialize
    @pdf = Prawn::Document.new(
      page_size: 'A4',
      margin: [50, 50, 50, 50]
    )
    
    # 日本語フォント設定（システムにある場合）
    begin
      @pdf.font_families.update(
        'NotoSans' => {
          normal: '/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc',
          bold: '/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc'
        }
      )
      @pdf.font 'NotoSans'
    rescue
      # フォントが見つからない場合はデフォルトを使用
      puts "日本語フォントが見つかりません。デフォルトフォントを使用します。"
    end
  end

  def generate
    add_cover_page
    add_table_of_contents
    add_overview_section
    add_verification_targets
    add_system_design
    add_verification_details
    add_implementation_specs
    add_test_cases
    add_operation_methods
    add_appendix
    
    save_pdf
  end

  private

  def add_cover_page
    @pdf.move_down 100
    
    @pdf.text "ボーナス検証プログラム", size: 28, style: :bold, align: :center
    @pdf.text "設計書", size: 24, style: :bold, align: :center
    
    @pdf.move_down 50
    
    @pdf.text "アジアビジネストラスト", size: 18, align: :center
    @pdf.text "ボーナス計算システム", size: 18, align: :center
    
    @pdf.move_down 100
    
    info_table = [
      ["プロジェクト名", "アジアビジネストラスト ボーナス計算システム"],
      ["文書バージョン", "1.0"],
      ["作成日", "2025年7月23日"],
      ["作成者", "システム開発チーム"]
    ]
    
    @pdf.table(info_table, 
      header: false,
      width: 400,
      position: :center,
      cell_style: { 
        borders: [:top, :bottom, :left, :right],
        padding: [8, 12, 8, 12]
      }
    )
    
    @pdf.start_new_page
  end

  def add_table_of_contents
    @pdf.text "目次", size: 20, style: :bold
    @pdf.move_down 20
    
    contents = [
      "1. 概要 ......................................................... 3",
      "2. 検証対象 ..................................................... 4", 
      "3. システム設計 ................................................. 5",
      "4. 検証項目詳細 ................................................. 7",
      "5. 実装仕様 .................................................... 10",
      "6. テストケース ................................................ 13",
      "7. 運用方法 .................................................... 16",
      "8. 付録 ........................................................ 18"
    ]
    
    contents.each do |item|
      @pdf.text item, size: 12
      @pdf.move_down 5
    end
    
    @pdf.start_new_page
  end

  def add_overview_section
    @pdf.text "1. 概要", size: 18, style: :bold
    @pdf.move_down 15
    
    @pdf.text "1.1 目的", size: 14, style: :bold
    @pdf.move_down 10
    
    purpose_text = <<~TEXT
      アジアビジネストラストのボーナス計算システムにおいて、複雑な階層構造と
      多様な販売パターンに対するボーナス計算の正確性を検証するプログラムを
      設計・実装する。
    TEXT
    
    @pdf.text purpose_text, size: 11, leading: 3
    @pdf.move_down 15
    
    @pdf.text "1.2 背景", size: 14, style: :bold
    @pdf.move_down 10
    
    background_items = [
      "• 6層の階層構造: アジアビジネストラスト → 特約代理店 → 代理店 → アドバイザー → サロン・病院",
      "• 特殊な紹介関係: アドバイザー→アドバイザー、特約代理店→サロン、代理店→病院", 
      "• ステータス管理: アクティブ、停止処分、退会",
      "• 階層差額ボーナス: 各レベル間の価格差によるボーナス計算",
      "• 無資格者ボーナス: サロン・病院の販売による上位ボーナス"
    ]
    
    background_items.each do |item|
      @pdf.text item, size: 11, leading: 3
      @pdf.move_down 5
    end
    
    @pdf.move_down 15
    
    @pdf.text "1.3 検証の必要性", size: 14, style: :bold
    @pdf.move_down 10
    
    necessity_items = [
      "• 計算精度の保証: 複雑なロジックでの計算ミス防止",
      "• データ整合性: 階層構造とボーナス配分の整合性確認",
      "• パフォーマンス: 大量データでの処理性能確認", 
      "• 回帰テスト: システム変更時の影響確認"
    ]
    
    necessity_items.each do |item|
      @pdf.text item, size: 11, leading: 3
      @pdf.move_down 5
    end
    
    @pdf.start_new_page
  end

  def add_verification_targets
    @pdf.text "2. 検証対象", size: 18, style: :bold
    @pdf.move_down 15
    
    @pdf.text "2.1 ボーナス計算ロジック", size: 14, style: :bold
    @pdf.move_down 10
    
    # 計算式を表で表示
    calculation_table = [
      ["種類", "計算式"],
      ["直接販売ボーナス", "ボーナス = (基本価格 - 自分の価格) × 数量"],
      ["階層差額ボーナス", "各階層間で: 下位価格 - 上位価格 = ボーナス"],
      ["無資格者上位ボーナス", "無資格者の販売 → 直近の有資格者がボーナス獲得"]
    ]
    
    @pdf.table(calculation_table,
      header: true,
      width: @pdf.bounds.width,
      cell_style: { 
        borders: [:top, :bottom, :left, :right],
        padding: [6, 8, 6, 8],
        size: 10
      }
    )
    
    @pdf.move_down 20
    
    @pdf.text "2.2 対象データ", size: 14, style: :bold
    @pdf.move_down 10
    
    target_data = [
      "• ユーザー: 全階層のユーザー（約60名のテストデータ）",
      "• 購入データ: 様々なパターンの購入履歴（20件）",
      "• 期間: 月次集計（今月・先月の比較）",
      "• 商品: 骨髄幹細胞培養上清液（基本価格: ¥50,000）"
    ]
    
    target_data.each do |item|
      @pdf.text item, size: 11, leading: 3
      @pdf.move_down 5
    end
    
    @pdf.start_new_page
  end

  def add_system_design
    @pdf.text "3. システム設計", size: 18, style: :bold
    @pdf.move_down 15
    
    @pdf.text "3.1 アーキテクチャ概要", size: 14, style: :bold
    @pdf.move_down 10
    
    # アーキテクチャ図をテキストで表現
    architecture_text = <<~TEXT
      ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
      │   検証エンジン    │    │   レポート生成   │    │   管理画面UI    │
      │                 │    │                 │    │                 │
      │ - 計算検証       │───▶│ - 詳細レポート   │───▶│ - 実行ボタン     │
      │ - データ検証     │    │ - エラー一覧     │    │ - 結果表示       │
      │ - 整合性チェック │    │ - 統計情報       │    │ - ダウンロード   │
      └─────────────────┘    └─────────────────┘    └─────────────────┘
               │                        │                        │
               ▼                        ▼                        ▼
      ┌─────────────────────────────────────────────────────────────────┐
      │                        データベース                              │
      │  Users | Purchases | Products | Levels | ProductPrices         │
      └─────────────────────────────────────────────────────────────────┘
    TEXT
    
    @pdf.font "Courier", size: 8 do
      @pdf.text architecture_text
    end
    
    @pdf.move_down 20
    
    @pdf.text "3.2 主要コンポーネント", size: 14, style: :bold
    @pdf.move_down 10
    
    components = [
      ["コンポーネント", "説明", "主要メソッド"],
      ["BonusVerificationService", "メイン検証エンジン", "verify_all, verify_individual_purchases"],
      ["BonusCalculationValidator", "独立した計算ロジック", "calculate_expected_bonus, validate_tier_difference"],
      ["VerificationReporter", "レポート生成", "generate_summary_report, generate_detailed_report"]
    ]
    
    @pdf.table(components,
      header: true,
      width: @pdf.bounds.width,
      cell_style: { 
        borders: [:top, :bottom, :left, :right],
        padding: [6, 8, 6, 8],
        size: 9
      }
    )
    
    @pdf.start_new_page
  end

  def add_verification_details
    @pdf.text "4. 検証項目詳細", size: 18, style: :bold
    @pdf.move_down 15
    
    @pdf.text "4.1 個別購入ボーナス検証", size: 14, style: :bold
    @pdf.move_down 10
    
    # テストケース例
    test_cases = [
      ["販売者", "数量", "期待ボーナス", "計算式"],
      ["アジアビジネストラスト", "50個", "2,500,000円", "(50,000 - 0) × 50"],
      ["特約代理店", "40個", "400,000円", "(50,000 - 40,000) × 40"],
      ["代理店", "30個", "150,000円", "(50,000 - 45,000) × 30"],
      ["アドバイザー", "20個", "60,000円", "(50,000 - 47,000) × 20"]
    ]
    
    @pdf.table(test_cases,
      header: true,
      width: @pdf.bounds.width,
      cell_style: { 
        borders: [:top, :bottom, :left, :right],
        padding: [6, 8, 6, 8],
        size: 9
      }
    )
    
    @pdf.move_down 20
    
    @pdf.text "4.2 階層差額ボーナス検証", size: 14, style: :bold
    @pdf.move_down 10
    
    hierarchy_text = <<~TEXT
      検証内容: 下位の販売による上位へのボーナス

      計算ロジック:
      1. 購入者から上位への階層を特定
      2. 各階層の価格を取得
      3. 隣接階層間の差額を計算
      4. ボーナス対象者に配分

      例: 病院(ID:35)の販売 → アドバイザー(ID:11)へのボーナス
      病院価格: 50,000円（基本価格）
      アドバイザー価格: 47,000円
      ボーナス: (50,000 - 47,000) × 数量 = 3,000円 × 数量
    TEXT
    
    @pdf.text hierarchy_text, size: 11, leading: 3
    
    @pdf.start_new_page
  end

  def add_implementation_specs
    @pdf.text "5. 実装仕様", size: 18, style: :bold
    @pdf.move_down 15
    
    @pdf.text "5.1 クラス設計", size: 14, style: :bold
    @pdf.move_down 10
    
    class_design_text = <<~TEXT
      BonusVerificationService
      ├─ verify_all(): メイン検証メソッド
      ├─ verify_individual_purchases(): 個別購入検証
      ├─ verify_monthly_totals(): 月次集計検証
      ├─ verify_hierarchy_consistency(): 階層整合性検証
      └─ verify_status_exclusions(): ステータス除外検証

      BonusCalculationValidator
      ├─ calculate_all_bonuses(): 全ボーナス計算
      ├─ calculate_direct_sales_bonus(): 直接販売ボーナス
      ├─ calculate_hierarchy_bonuses(): 階層差額ボーナス
      └─ calculate_unqualified_bonus(): 無資格者ボーナス

      VerificationReporter
      ├─ generate_summary_report(): サマリーレポート
      ├─ generate_detailed_report(): 詳細レポート
      └─ generate_error_report(): エラーレポート
    TEXT
    
    @pdf.font "Courier", size: 10 do
      @pdf.text class_design_text
    end
    
    @pdf.move_down 20
    
    @pdf.text "5.2 データベース設計", size: 14, style: :bold
    @pdf.move_down 10
    
    db_tables = [
      ["テーブル名", "用途", "主要カラム"],
      ["bonus_verification_results", "検証結果", "verification_date, target_month, status"],
      ["bonus_verification_errors", "検証エラー", "error_type, severity, expected_value, actual_value"]
    ]
    
    @pdf.table(db_tables,
      header: true,
      width: @pdf.bounds.width,
      cell_style: { 
        borders: [:top, :bottom, :left, :right],
        padding: [6, 8, 6, 8],
        size: 10
      }
    )
    
    @pdf.start_new_page
  end

  def add_test_cases
    @pdf.text "6. テストケース", size: 18, style: :bold
    @pdf.move_down 15
    
    @pdf.text "6.1 基本機能テスト", size: 14, style: :bold
    @pdf.move_down 10
    
    basic_tests = [
      ["テスト項目", "検証内容", "期待結果"],
      ["直接販売ボーナス", "各レベルの販売ボーナス計算", "計算式通りの結果"],
      ["階層差額ボーナス", "上位へのボーナス配分", "階層に応じた正確な配分"],
      ["無資格者ボーナス", "サロン・病院販売の上位ボーナス", "直近有資格者への配分"],
      ["月次集計", "期間内ボーナス合計", "個別ボーナスの正確な合計"]
    ]
    
    @pdf.table(basic_tests,
      header: true,
      width: @pdf.bounds.width,
      cell_style: { 
        borders: [:top, :bottom, :left, :right],
        padding: [6, 8, 6, 8],
        size: 10
      }
    )
    
    @pdf.move_down 20
    
    @pdf.text "6.2 特殊ケーステスト", size: 14, style: :bold
    @pdf.move_down 10
    
    special_tests = [
      ["テスト項目", "検証内容", "期待結果"],
      ["アドバイザー→アドバイザー", "同レベル間紹介", "適切なボーナス計算"],
      ["特約代理店→サロン", "レベル飛び越し紹介", "正常な処理"],
      ["停止処分ユーザー", "ステータス除外", "ボーナス = 0"],
      ["退会ユーザー", "ステータス除外", "ボーナス = 0"]
    ]
    
    @pdf.table(special_tests,
      header: true,
      width: @pdf.bounds.width,
      cell_style: { 
        borders: [:top, :bottom, :left, :right],
        padding: [6, 8, 6, 8],
        size: 10
      }
    )
    
    @pdf.start_new_page
  end

  def add_operation_methods
    @pdf.text "7. 運用方法", size: 18, style: :bold
    @pdf.move_down 15
    
    @pdf.text "7.1 実行方法", size: 14, style: :bold
    @pdf.move_down 10
    
    execution_text = <<~TEXT
      手動実行:
      • 管理画面から実行: /admin/bonus_verification
      • コマンドラインから実行: rails bonus:verify
      • 特定月の検証: rails bonus:verify MONTH=2025-01

      自動実行:
      • 毎月1日に前月分を自動検証
      • config/schedule.rb (whenever gem) で設定
      • BonusVerificationJob で非同期実行
    TEXT
    
    @pdf.text execution_text, size: 11, leading: 3
    @pdf.move_down 20
    
    @pdf.text "7.2 監視・アラート", size: 14, style: :bold
    @pdf.move_down 10
    
    monitoring_items = [
      "• エラー発生時のSlack通知",
      "• 管理者へのメール通知",
      "• ダッシュボードでの結果表示",
      "• 月次統計の自動生成"
    ]
    
    monitoring_items.each do |item|
      @pdf.text item, size: 11, leading: 3
      @pdf.move_down 5
    end
    
    @pdf.move_down 15
    
    @pdf.text "7.3 レポート出力", size: 14, style: :bold
    @pdf.move_down 10
    
    report_formats = [
      ["形式", "用途", "内容"],
      ["PDF", "詳細レポート", "サマリー、エラー詳細、統計情報"],
      ["CSV", "データ分析", "エラー一覧、数値データ"],
      ["JSON", "API連携", "構造化データ、システム間連携"]
    ]
    
    @pdf.table(report_formats,
      header: true,
      width: @pdf.bounds.width,
      cell_style: { 
        borders: [:top, :bottom, :left, :right],
        padding: [6, 8, 6, 8],
        size: 10
      }
    )
    
    @pdf.start_new_page
  end

  def add_appendix
    @pdf.text "8. 付録", size: 18, style: :bold
    @pdf.move_down 15
    
    @pdf.text "8.1 エラーコード一覧", size: 14, style: :bold
    @pdf.move_down 10
    
    error_codes = [
      ["コード", "エラータイプ", "説明"],
      ["BV001", "calculation_mismatch", "ボーナス計算値の不一致"],
      ["BV002", "hierarchy_invalid", "階層構造の不整合"],
      ["BV003", "status_exclusion_failed", "ステータス除外処理の失敗"],
      ["BV004", "price_configuration_error", "価格設定の不整合"],
      ["BV005", "circular_reference", "循環参照の検出"],
      ["BV006", "data_integrity_error", "データ整合性エラー"],
      ["BV007", "performance_warning", "パフォーマンス警告"]
    ]
    
    @pdf.table(error_codes,
      header: true,
      width: @pdf.bounds.width,
      cell_style: { 
        borders: [:top, :bottom, :left, :right],
        padding: [6, 8, 6, 8],
        size: 9
      }
    )
    
    @pdf.move_down 20
    
    @pdf.text "8.2 パフォーマンス指標", size: 14, style: :bold
    @pdf.move_down 10
    
    performance_metrics = [
      ["指標", "目標値", "警告値", "エラー値"],
      ["実行時間", "< 2分", "< 5分", "> 10分"],
      ["メモリ使用量", "< 100MB", "< 200MB", "> 500MB"],
      ["DBクエリ数", "< 100", "< 200", "> 500"],
      ["エラー率", "0%", "< 1%", "> 5%"]
    ]
    
    @pdf.table(performance_metrics,
      header: true,
      width: @pdf.bounds.width,
      cell_style: { 
        borders: [:top, :bottom, :left, :right],
        padding: [6, 8, 6, 8],
        size: 10
      }
    )
    
    @pdf.move_down 30
    
    @pdf.text "文書終了", size: 14, style: :bold, align: :center
    @pdf.move_down 20
    
    footer_text = <<~TEXT
      この設計書は、アジアビジネストラストのボーナス計算システムの検証プログラム
      開発のための技術仕様書です。実装時は、この設計書を基に段階的な開発を行い、
      各フェーズでのテストと検証を実施してください。
    TEXT
    
    @pdf.text footer_text, size: 10, style: :italic, align: :center
  end

  def save_pdf
    filename = "docs/bonus_verification_design_#{Date.current.strftime('%Y%m%d')}.pdf"
    @pdf.render_file(filename)
    puts "PDF生成完了: #{filename}"
    filename
  end
end

# 実行
if __FILE__ == $0
  begin
    generator = BonusVerificationDesignPDF.new
    filename = generator.generate
    puts "✅ ボーナス検証プログラム設計書PDFを生成しました: #{filename}"
  rescue => e
    puts "❌ PDF生成エラー: #{e.message}"
    puts "Prawn gemがインストールされていない可能性があります。"
    puts "インストール: gem install prawn prawn-table"
  end
end