# ElgatoMirror

將任一螢幕的畫面水平鏡像顯示到另一個螢幕（如 Elgato Prompter 題詞機）的 macOS 選單列工具。

## 功能

- 常駐選單列，零干擾工作流程
- 自由指定**來源螢幕**與**目標螢幕**（支援多螢幕）
- 即時水平翻轉，適用於需要鏡面顯示的場景
- 快速鍵 `⌘M` 切換啟用 / 停用

## 系統需求

- macOS 13 Ventura 以上
- 需授予**螢幕錄影**許可權（系統設定 > 隱私權與安全性 > 螢幕錄影）

## 安裝

1. 下載最新版 [ElgatoMirror.dmg](../../releases/latest)
2. 開啟 DMG，將 `ElgatoMirror.app` 拖曳至應用程式資料夾
3. 首次啟動時，前往**系統設定 > 隱私權與安全性 > 螢幕錄影**，開啟 ElgatoMirror 的存取許可權

## 使用方式

1. 啟動 ElgatoMirror，選單列右上角會出現圖示
2. 點選圖示，從「來源螢幕」選擇要鏡像的螢幕
3. 從「目標螢幕（題詞機）」選擇 Elgato Prompter
4. 點選「啟用鏡像」（或按 `⌘M`）

## 從原始程式碼建置

```bash
git clone https://github.com/AndyJuang/ElgatoMirror.git
cd ElgatoMirror
./build.sh
open ElgatoMirror.app
```

## 授權

MIT License
