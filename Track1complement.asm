; MBR 只佔 first track 18 sectors 的第一個，其他 17 個 sectors 補零，用本程式來產生。

          times 17*512 db 0

