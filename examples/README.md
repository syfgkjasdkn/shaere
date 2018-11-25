These two projects illustrate the main idea behind `:shaere` (easy Æ sharing) and also serve as examples for integrating `:shaere` into your own projects if you decide to do so.

---

### shaerebot

[@shaerebot](https://t.me/shaerebot) is a basic telegram bot and a [web endpoint](https://shaere.from.network) which stores the user ids in an ets table (TODO use sqlite). The way it works is, it creates an account for each telegram user that interacts with it, either via a public room where users can `/shaere` æternity by replying to each other's messages or in a private room with the bot, where it's possible to ask the bot about the generated private key, address, and balance.

bot: [@shaerebot](https://t.me/shaerebot)
website: [shaere.from.network](https://shaere.from.network)

### shaeritch

[shaeritch](https://shaeritch.from.network) is a twitch emulator which shows how your existing users can send and receive (aka shaere) Æ without hassle.
