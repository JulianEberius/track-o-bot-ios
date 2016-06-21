# track-o-bot-ios
Simple companion iOS app for Track-o-Bot

Universal iOS app that allows the user to manually upload games to Track-o-Bot.
Can be used, for example, when playing Hearthstone on an iPad.

To reuse your existing Track-o-Bot account, after installing this app, export your account data from your Desktop client ("Settings"->"Account"->"Export"), and then open the resulting file on your iOS device. This can be accomplished, for example, by sending the account data file via email to yourself, and opening the attachment on the iOS device. Another way would be using Dropbox or similar services.

This project is nearing beta, so it's not complete. However, some features are already in place:

- Import account data file (Track-o-Bot profile credentials)
- Add games with information about heroes, decks, coin, mode, rank and game results
- Basic History view
- Basic win rate graphs for classes and decks
- Open web profile

That's it ;-) Obviously, it comes with no warranties, use at your own risk. However, if it uploads wrong game data, you can always delete games on your Track-o-Bot profile.

## License

This project is released under the GNU General Public License (LGPL) Version 2.

See [LICENSE](LICENSE)

This project further includes a copy of Daniel Cohen Gindi & Philipp Jahoda's project "Charts" (previously "iOS-Charts") from [https://github.com/danielgindi/Charts](https://github.com/danielgindi/Charts), which is released under the Apache License 2.0 (see [Charts](Charts)).