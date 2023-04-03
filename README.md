# Introduction
Introducing Nickel, a lightweight and powerful moderation plugin for BeamMP. This plugin contains a variety of commands for managing your server, including removing and adding staff members, banning and unbanning players, and kicking players. Additionally, the plugin includes a command to retrieve the IP of users on the server.

# Commands
- ;setrole - set the role of a player
- ;ban - bans a player from the server
- ;unban - unban a player from the server
- ;banip - bans a player's IP from the server
- ;mute - mute a player
- ;unmute - unmute a player
- ;tempmute - tempmute a player
- ;kick - kicks a player from the server
- ;ip - retrieves the IP of a player on the server
- ;noguest - choose if guests players can join
- ;countdown - user command useful for racing
- ;votekick - user can votekick an other user to kick him
- ;dm - send a private message to another player
- ;say - broadcast a message to all players
- ;help - show all commands
- ;whitelist - add or remove a player from the whitelist

# Configuration
The plugin includes a configuration file that allows you to modify certain messages sent by the plugin and also change values to enable or disable features.

# Auto update 
The plugin includes an auto-update feature that can be enabled or disabled.

# Installation
To install the plugin, you can download the latest version from the link below:

[Download Nickel on Github](https://github.com/boubouleuh/Nickel-BeamMP-Plugin)

Simply add the .lua file to your "BeamServer/Resources/Server/Nickel" directory (it's an example). After doing so, you can utilize the ";help" command in the server console. However, in order to access the command in-game, with the default permissions.json you must first grant yourself administrator permissions by using the following command: ";setrole Yourusername administrator". If you have a problem come in the discord : [Nickel discord](https://discord.gg/h5P84FFw7B)


# Manage permissions
you can modify the permission levels in the permissions.json file. The "name" field in this file will be used in conjunction with the ";setrole" command to assign a new moderator, for example. Each permission level's command can be customized to suit your needs. It is important to note that higher levels of permission will automatically include the commands of lower levels. Therefore, it is essential that you do not include any command twice in the JSON file.

# Discord
WE NOW HAVE A DISCORD ! GO CHECK IT OUT :
[Nickel discord](https://discord.gg/h5P84FFw7B)

# Conclusion
Nickel is a powerful and easy-to-use moderation plugin that is perfect for managing your BeamMP server. Try it out today and see how it can improve your server management experience!

# Thanks
Thanks to the BeamMP France team -> https://discord.gg/6tC6ZpJdux
This plugin is tested on their server.
