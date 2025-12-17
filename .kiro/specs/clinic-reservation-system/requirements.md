# クリニック予約システム 要件定義書

## はじめに

骨髄幹細胞培養上清液の購入後に、ユーザーが指定クリニックの施術予約（1時間枠）を希望日時（第1～第3希望）として入力し、管理側で確定する仕組みを実装します。クリニックごとに異なる営業時間・休憩時間・休日に対応した予約システムを構築します。

## 用語集

- **Clinic_System**: クリニック予約システム全体
- **Purchase_User**: 骨髄幹細胞培養上清液を購入済みのユーザー
- **Reservation_Request**: ユーザーが入力する予約希望（第1～第3希望）
- **Confirmed_Reservation**: 管理側で確定された予約
- **Business_Hours**: クリニックの営業時間設定
- **Break_Times**: クリニックの休憩時間設定
- **Holiday_Settings**: クリニックの休日設定
- **Time_Slot**: 1時間単位の予約枠
- **Availability_Service**: 予約可能枠を動的生成するサービス

## 要件

### 要件1

**ユーザーストーリー:** 購入済みユーザーとして、既存のclinic_reservations/new画面で第1～第3希望の予約申し込みを行いたい。そうすることで、希望に沿った日時で施術を受けられる。

#### 受入基準

1. WHEN Purchase_Userがclinic_reservations/new画面にアクセスする THEN Clinic_Systemは購入履歴を確認して予約権限を検証する SHALL
2. WHEN 画面が表示される THEN Clinic_Systemは購入時に選択されたクリニックの予約可能日時を動的に表示する SHALL
3. WHEN ユーザーが日付を選択する THEN Clinic_Systemはその日の予約可能な1時間枠のみを時間帯セレクトに表示する SHALL
4. WHEN ユーザーが第1～第3希望を入力する THEN 既存のpreferred_time_1, preferred_time_2, preferred_time_3フィールドを使用して保存する SHALL
5. WHEN 予約申し込みが完了する THEN Clinic_Systemは既存のcreateアクションで申し込み内容を処理する SHALL

### 要件2

**ユーザーストーリー:** システムとして、購入時に選択されたクリニックの営業時間・休憩時間・休日設定に基づいて予約可能枠を動的生成したい。そうすることで、無効な時間帯での予約を防げる。

#### 受入基準

1. WHEN Availability_Serviceが予約可能枠を生成する THEN 指定日がHoliday_Settingsに該当する場合は空配列を返す SHALL
2. WHEN 営業日の予約枠を生成する THEN Business_Hoursを1時間単位でTime_Slotに分割する SHALL
3. WHEN Time_Slotを生成する THEN Break_Timesと重なるスロットを除外する SHALL
4. WHEN 既存予約との衝突をチェックする THEN Confirmed_Reservationと重複するTime_Slotを除外する SHALL
5. WHEN 予約可能枠APIが呼び出される THEN 残った有効なTime_Slotのみを返却する SHALL

### 要件3

**ユーザーストーリー:** 管理者として、ユーザーの予約希望を確認して最終的な予約日時を確定したい。そうすることで、クリニックの運営に合わせた予約管理ができる。

#### Acceptance Criteria

1. WHEN 管理者が予約管理画面にアクセスする THEN Clinic_Systemは未確定のReservation_Requestを一覧表示する SHALL
2. WHEN 管理者が予約希望を確認する THEN ユーザーの第1～第3希望と各希望の可否状況を表示する SHALL
3. WHEN 管理者が確定日時を選択する THEN 選択された日時がクリニックの営業時間内であることを検証する SHALL
4. WHEN 予約が確定される THEN Confirmed_Reservationとして保存され、該当Time_Slotが予約済みになる SHALL
5. WHEN 予約確定が完了する THEN ユーザーに確定通知が送信される SHALL

### 要件4

**ユーザーストーリー:** システム管理者として、クリニックの営業時間・休憩時間・休日をデータベース設定で管理したい。そうすることで、コード変更なしに運営条件を更新できる。

#### 受入基準

1. WHEN 新しいクリニックを追加する THEN Business_Hoursテーブルで曜日別の営業時間を設定できる SHALL
2. WHEN クリニックに休憩時間がある THEN Break_Timesテーブルで曜日別の休憩時間を設定できる SHALL
3. WHEN 臨時休診や定休日を設定する THEN Holiday_Settingsテーブルで日付指定または曜日指定の休日を設定できる SHALL
4. WHEN 営業時間設定を変更する THEN 変更後の設定が即座に予約可能枠生成に反映される SHALL
5. WHEN 設定に不整合がある THEN Clinic_Systemは適切なバリデーションエラーを表示する SHALL

### 要件5

**ユーザーストーリー:** ユーザーとして、clinic_reservations/new画面で予約可能な時間帯のみが選択肢として表示されるインターフェースを使いたい。そうすることで、無効な予約申し込みを避けられる。

#### 受入基準

1. WHEN 画面が読み込まれる THEN 購入時に選択されたクリニックに基づいて日付選択フィールドが有効になる SHALL
2. WHEN ユーザーが日付を選択する THEN JavaScriptでAPIを呼び出し、当日の予約可能枠を取得して時間帯セレクトに反映する SHALL
3. WHEN 予約可能枠APIが応答する THEN 既存のpreferred_time_1, preferred_time_2, preferred_time_3セレクトに利用可能な時間帯のみを表示する SHALL
4. WHEN 予約不可能な日付を選択する THEN 「予約可能な時間帯がありません」というメッセージを表示する SHALL
5. WHEN 第1希望を選択後 THEN 第2・第3希望では同じ日時を選択できないよう既存のJavaScriptを拡張して制御する SHALL

### 要件6

**ユーザーストーリー:** システムとして、既存のclinic_reservationsテーブルとclinic_reservations/new画面を拡張しながら新機能を実装したい。そうすることで、既存データと機能を保持しながら改善できる。

#### 受入基準

1. WHEN 新しい予約システムを導入する THEN 既存のclinic_reservationsテーブル構造を維持しながら機能を拡張する SHALL
2. WHEN 既存のpreferred_date, preferred_time_1, preferred_time_2, preferred_time_3フィールドを使用する THEN 新しい動的時間選択機能と互換性を保つ SHALL
3. WHEN 確定予約を管理する THEN 既存のconfirmed_date, confirmed_timeフィールドを活用する SHALL
4. WHEN 新しいクリニック管理機能を追加する THEN 既存のclinic_reservationsモデルとの関連を維持する SHALL
5. WHEN 既存のclinic_reservations_controller機能を維持する THEN 現在のnew, create, show, editアクションが正常に動作し続ける SHALL

### 要件7

**ユーザーストーリー:** 開発者として、予約可能枠の判定ロジックを再利用可能な形で実装したい。そうすることで、API・管理画面・バッチ処理などから同一のロジックを使用できる。

#### 受入基準

1. WHEN Availability_Serviceを実装する THEN Service Objectパターンで再利用可能な形にする SHALL
2. WHEN 予約可能枠を取得する THEN available_slots(clinic, date)メソッドでTime配列を返す SHALL
3. WHEN 休日判定を行う THEN holiday?(clinic, date)メソッドでboolean値を返す SHALL
4. WHEN 営業時間を取得する THEN business_hours_for(clinic, weekday)メソッドで時間範囲を返す SHALL
5. WHEN 既存予約を確認する THEN reserved_slots_for(clinic, date)メソッドで予約済み時間を返す SHALL

### 要件8

**ユーザーストーリー:** システムとして、将来的な機能拡張に対応できる柔軟な設計にしたい。そうすることで、スタッフ別予約・枠数制限・通知機能などを容易に追加できる。

#### 受入基準

1. WHEN データモデルを設計する THEN スタッフ別・部屋別の同時予約枠（capacity）を追加しやすい構造にする SHALL
2. WHEN 休日管理を実装する THEN 祝日マスタ連携や臨時休診設定を拡張しやすい構造にする SHALL
3. WHEN UI設計を行う THEN カレンダーUI（FullCalendar等）への置換を容易にする構造にする SHALL
4. WHEN 通知機能を考慮する THEN 確定・変更・キャンセル通知を追加しやすい構造にする SHALL
5. WHEN 管理機能を設計する THEN 営業時間・休日のメンテナンス画面を追加しやすい構造にする SHALL