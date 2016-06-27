# track-o-bot-ios
Simple companion iOS app for Track-o-Bot

Universal iOS app that allows the user to manually upload games to Track-o-Bot.
Can be used, for example, when playing Hearthstone on an iPad.

To reuse your existing Track-o-Bot account, after installing this app, export your account data from your Desktop client ("Settings"->"Account"->"Export"), and then open the resulting file on your iOS device. This can be accomplished, for example, by sending the account data file via email to yourself, and opening the attachment on the iOS device. Another way would be using Dropbox or similar services.

This project is nearing beta, so it's not complete. However, some features are already in place:

- Import account data file (Track-o-Bot profile credentials)
- Add games with information about heroes, decks, coin, mode, rank and game results
- Basic History view, allows to delete games
- Basic win rate graphs for classes and decks
- Open the trackobot.com web profile, export the profile credentials

That's it ;-) Obviously, it comes with no warranties, use at your own risk. However, if it uploads wrong game data, you can always delete games on your Track-o-Bot profile.

## License

This project is released under the GNU General Public License (LGPL) Version 2.

See [LICENSE](LICENSE)

This project further includes the source code of the Charts (previously "iOS-Charts") library by Daniel Cohen Gindi & Philipp Jahoda, which was acquired under the Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0) from https://github.com/danielgindi/Charts.

The icons used in the app’s tab bar are part of the Themify Icon set, which was acquired under the OFL license (http://scripts.sil.org/OFL) from http://themify.me/themify-icons.