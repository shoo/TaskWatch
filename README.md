TaskWatch
=========

Repository for development of a stopwatch used for a task measurement.

タスク計測に用いるためのストップウォッチの開発用リポジトリです。

Resource File Compile
---------------------
    rcc res\resources.rc -ores\resources.res


Build
-----
ビルド方法は以下。

    dmd -run build.d -g

Make Document
-------------
ドキュメント(開発用)の生成方法は以下。

    dmd -run build.d -D


Require
-------
このアプリケーションのコンパイルには以下の環境及びライブラリが必要です。
- [dmd](https://github.com/D-Programming-Language)
- [DFL](https://github.com/Rayerd/dfl)
- [voile](https://github.com/shoo/voile)