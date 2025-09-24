<img src="readme_img/nickel_banner.png" alt="Logo" width="100%"/>


<h1><a href="https://discord.gg/6apG8dNcJF">Community Discord</a></h1>

# Nickel Moderation Plugin

Introducing Nickel, a lightweight and powerful moderation plugin for BeamMP. This plugin contains a variety of commands for managing your server, including removing and adding staff members, banning and unbanning players, and kicking players.

## Installation

- ### Ubuntu
    Go to the Resources/Server path on your server and run these commands:

    `$ git clone https://github.com/boubouleuh/Nickel-BeamMP-Plugin`

    `$ cd Nickel-BeamMP-Plugin`

    `$ git checkout dev`
    
    Now head to the <a href="#first-setup">First Setup</a> section.
- ### Debian
    Go to the Resources/Server path on your server and run these commands: 

    `$ sudo apt install git wget curl`

    `$ git clone https://github.com/boubouleuh/Nickel-BeamMP-Plugin`

    `$ cd Nickel-BeamMP-Plugin`

    `$ git checkout dev`

    Now head to the <a href="#first-setup">First Setup</a> section.
- ### Windows
    If you really need to run it on Windows, you will need either WSL or Docker or an other solution to have a virtual Linux environment.

    BeamMP use Lua 5.4 for the windows version for now and i cant handle it. 

<h2 id="first-setup">First setup</h2>

- ### Permissions 
    You need to give you Administrator permissions, in order to do that use this command in your running server console :

    `/grantrole administrator yourUsernameHere` Yes, replace "yourUsernameHere" with your username.

    You can also use this command to add Moderators and other roles.


## Commands
 - `help` Show every commands
 - `ban <targetname> <reason>` Ban a player
 - `banip <targetname>` Ban every ips of a player
 - `tempban <targetname> <time(example : 1s,1m,1h,1d)> <reason>` Ban a player for a specific time
 - `unban <targetname>` Unban a player
 - `kick <targetname>` Kick a player
 - `mute <targetname> <reason>` Mute a player
 - `tempmute <targetname> <time(example : 1s,1m,1h,1d)> <reason>` Tempmute a player for a specific time
 - `unmute <targetname>` Unmute a player
 - `dm <targetname> <message>` Send a direct message to someone
 - `createrole <rolename> <permlvl>` Create a role
 - `deleterole <rolename>` Delete a role
 - `grantrole <rolename> <targetname>`  Grant a role to a player
 - `revokerole <rolename> <targetname>` Revoke a role from a player
 - `grantcommand <commandname> <rolename>` Grant the permission of a command to a specific role
 - `revokecommand <commandname> <rolename>` Revoke the permission of a command from a specific role
 - `listactions` List all available actions
 - `listroles` List all roles
 - `grantaction <actionname> <rolename>` Grant an action to a specific role
 - `revokeaction <actionname> <rolename>` Revoke an action from a role
 - `forcenametags` Toggle forced display of player nametags (Interface only)
 - `broadcast <message>` Send a message to all players
 - `whitelist <add/remove> <playername>` Add or remove a player from the whitelist
 - `countdown <duration>` Start a countdown

## Database Configuration

Nickel supports multiple database types for data persistence:

### SQLite (Default)
SQLite is the default database and requires no additional setup:
```toml
[sync]
database_type = "sqlite"
database_file = "database/nickel.sqlite"
```

### MySQL
For larger deployments or multi-server setups, MySQL is supported:
```toml
[sync]
database_type = "mysql"
mysql_host = "localhost"
mysql_port = 3306
mysql_database = "nickel_beammp"
mysql_username = "your_username"
mysql_password = "your_password"
```

**Requirements for MySQL:**
- MySQL server installation
- `luasql-mysql` library (install using `scripts/install_mysql.sh`)

For detailed setup instructions, see `database/DATABASE_CONFIG.md` and `database/MIGRATION_GUIDE.md`.





