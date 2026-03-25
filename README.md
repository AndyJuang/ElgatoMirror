# ElgatoMirror

將任一螢幕的畫面水平鏡像顯示到另一個螢幕（如 Elgato Prompter 題詞機）的 macOS 選單列工具。

## 功能

- 常駐選單列，零干擾工作流程
- 自由指定**來源螢幕**與**目標螢幕**（支援多螢幕）
- 即時水平翻轉，適用於需要鏡面顯示的場景
- 快速鍵 `⌘M` 切換啟用 / 停用
- 緊急停用快速鍵 `⌘⌥M`（即使鏡像視窗遮住畫面也能觸發）
- 螢幕拔除時自動停用鏡像

## 系統需求

- macOS 13 Ventura 以上
- 需授予**螢幕與系統錄音**許可權（系統設定 > 隱私權與安全性 > 螢幕與系統錄音）

## 安裝

1. 下載最新版 [ElgatoMirror.dmg](../../releases/latest)
2. 開啟 DMG，將 `ElgatoMirror.app` 拖曳至應用程式資料夾
3. 首次啟動時，系統會彈出授權對話框，點選「打開系統設定」並開啟 ElgatoMirror 的許可權

## 使用方式

1. 啟動 ElgatoMirror，選單列右上角會出現圖示
2. 點選圖示，從「來源螢幕」選擇要鏡像的螢幕
3. 從「目標螢幕（題詞機）」選擇 Elgato Prompter
4. 點選「啟用鏡像」（或按 `⌘M`）

## 從原始程式碼建置

需要 [Apple Developer](https://developer.apple.com) 帳號（免費或付費皆可），並在 Keychain 中安裝 Apple Development 憑證。

```bash
git clone https://github.com/AndyJuang/ElgatoMirror.git
cd ElgatoMirror
# 修改 build.sh 中的憑證名稱為你自己的 Apple Development 憑證
./build.sh
open ElgatoMirror.app
```

> **注意**：建置時必須使用正式憑證（非 ad-hoc）簽名，macOS 才能在重建後持續識別螢幕錄影許可權。

## 權限疑難排解

若已在系統設定開啟許可權但仍無法啟用鏡像，可在終端機執行以下指令清除舊的 TCC 快取，再重新啟動 App：

```bash
tccutil reset All com.zhuangzheyun.ElgatoMirror
```

## 授權

MIT License
