真无聊，朋友想要某站的全部种子，让我帮忙，好吧。花了些时间写个脚本吧。

- caoliu.pl 搜寻rmdown链接, 数据库保存到 /run/shm/caoliu.db (sqlite格式)
- rmdown.pl 根据hash自动下载，保存为 hash.torrent
- download_all.sh 读取caoliu.db，调用rmdown.pl下载种子

集合shell脚本或者其他图形界面程序，你可以很快的把种子全弄下来
