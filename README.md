# YGOeditor

遊戯王のコンボを表記/管理
![displayimg](docs/editor.png)

マークの説明  
一番左は、スワラルスライムの効果を発動し、スワラルスライム/ネクロスライムを手札から墓地に送り、テムジンをフィールドに召喚する処理を表している
- ●
  - 効果を受けるもの。効果によって墓地や除外ゾーンに行ったりフィールドに召喚されるもの
- ★
  - 効果の主体。効果の発動やシンクロ召喚の主体となるモンスターなど
- 黒線
  - 手札
- 青線
  - 墓地
- 赤線
  - フィールド
- 紫線
  - 除外
- 灰線
  - デッキ
- ATK
  - フィールドにいるモンスターの攻撃力の合計（裏表や守備/攻撃表示問わず）


## quick start
1. generate index.js from index.nim
    ```
    nim js index
    ```
2. open index.html on browser

## 編集
1. index.nimの↓を編集
![source](docs/combosource.png)
     - カード編集
        ```
        cards.add newCard("<カード名>", <初期位置>)
        ```
     - 処理編集
        ```
        operations.add newOperation(
                          "<カード名>",
                          newEffect("<カード名>", <位置>),
                          newEffect("<カード名>", <位置>),
                          ...)
        ```


## Goals
実装予定
- A: 着手中
  - コンボを編集
  - jsonファイルにエクスポート
- B: 設計中
  - 手札から展開可能なコンボを表示
- C: 構想中
  - デッキをインポート
  - インポートしたデッキからコンボ生成