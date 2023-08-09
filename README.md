# Introduction
Introducing Nickel, a lightweight and powerful moderation plugin for BeamMP. This plugin contains a variety of commands for managing your server, including removing and adding staff members, banning and unbanning players, and kicking players. Additionally, the plugin includes a command to retrieve the IP of users on the server.

# Commands
``;setrole <name> <role>``: Assign a role to a player on the server. Example: ;setrole player1 moderator

``;tempban <name> <time> <reason>``: Temporarily ban a player from the server for a given reason. Time must be specified in seconds (s), minutes (m), hours (h), or days (d).

``;ban <name> <reason>``: Ban a player from the server for a given reason.

``;unban <name>``: Unban a player from the server.

``;banip <name> <reason>``: Ban the player and the IP from the server for a given reason.

``;mute <name> <reason>``: Mute a player on the server.

``;unmute <name>``: Unmute a player on the server.

``;tempmute <name> <time> <reason>``: Temporarily mute a player on the server for a given reason. Time must be specified in seconds (s), minutes (m), hours (h), or days (d).

``;kick <name>``: Kick a player from the server.

``;ip <name>``: Retrieve the IP address of a player on the server.

``;countdown``: Start a countdown for races.

``;votekick <name>``: Initiate a vote to kick a player.

``;dm <name> <message>``: Send a private message to a player on the server.

``;say <message>``: Broadcast a message to all players on the server.

``;help``: Show a list of all available commands on the server.

``;reloadconf``: Reload the configurations file

``;whitelist <add/remove> <name>``: Add or remove a player from the server's whitelist.

``;interface``: Show or hide Nickel interface if installed.

# Configuration
The plugin includes a configuration file that allows you to modify certain messages sent by the plugin and also change values to enable or disable features.

# Auto update 
The plugin includes an auto-update feature that can be enabled or disabled.

# Auto moderation (WIP)

- #### Ping kick 
    automatically kicks a player when their ping (latency) exceeds a certain threshold for a given time. This helps maintain a smooth gaming experience for all players by limiting the presence of players with unstable connections.

- #### Anti vehicle afk
    The Anti Vehicle AFK feature automatically removes a vehicle from the game when it remains inactive for a certain period of time. This helps keep the game world tidy and ensures active players have a smoother gaming experience.

# Installation
To install the plugin, you can download the latest version from the link below:

[Download Nickel on Github](https://github.com/boubouleuh/Nickel-BeamMP-Plugin)

Simply add the .lua file to your "BeamServer/Resources/Server/Nickel" directory (it's an example). After doing so, you can utilize the ";help" command in the server console. However, in order to access the command in-game, with the default permissions.json you must first grant yourself administrator permissions by using the following command: ";setrole Yourusername administrator". If you have a problem come in the discord : [Nickel discord](https://discord.gg/h5P84FFw7B)

- ## Nickel interface is coming
    We are excited to announce that the development of the Nickel Interface has officially begun! With this new interface, moderating your BeamMP server will be easier than ever before. Say goodbye to using complex commands; instead, you'll have user-friendly buttons at your fingertips to manage your server effortlessly!

    ### Early Development Stage:
    Please note that the Nickel Interface is still in its early development stage. While we can't wait for you to try it out, it's essential to keep in mind that this version may have limited features and could encounter bugs or crashes. Rest assured, as the sole developer, I am hard at work, and future updates will bring more stability and functionalities.

    ### Get the Interface:
    You can already access the Nickel Interface on GitHub via the link below:
    [Nickel Interface Github](https://github.com/boubouleuh/Nickel-Interface)

    ### Installation Guide:
    To install the interface, simply create a zip file and drag and drop the two folders into it. Once installed, you'll be able to enjoy the early experience of our user-friendly moderating solution.

    ### No Readme Yet:
    As the interface is still in its early stages, there is no readme available at the moment. But don't worry, I will provide detailed documentation as the project progresses.

# Manage permissions
you can modify the permission levels in the permissions.json file. The "name" field in this file will be used in conjunction with the ";setrole" command to assign a new moderator, for example. Each permission level's command can be customized to suit your needs. It is important to note that higher levels of permission will automatically include the commands of lower levels. Therefore, it is essential that you do not include any command or permission level's twice in the JSON file.


# Discord
WE NOW HAVE A DISCORD ! GO CHECK IT OUT :
[Nickel discord](https://discord.gg/h5P84FFw7B)

# Conclusion
Nickel is a powerful and easy-to-use moderation plugin that is perfect for managing your BeamMP server. Try it out today and see how it can improve your server management experience!

