# RXPAL
A data-powered abstraction layer for creating RestedXP guides.

Enables you to write steps like this:
```
accept "your place in the world"
```

Instead of this:
```
step
    .goto Durotar,43.29,68.53
    .target Kaltunk
    >>|Tinterface/worldmap/chatbubble_64grey.blp:20|tTalk to |cRXP_FRIENDLY_Kaltunk|r
    .accept 4641 --Your Place In The World
```


<br />

# Example projects
- https://github.com/jmaxor/hunter-1-20-guide
- https://github.com/jmaxor/warlock-1-20-guide


<br />

# Requirements

Just a LUA interpreter (5.4 or higher). On windows, [luaforwindows](https://github.com/rjpcomputing/luaforwindows) is the easiest to install. If you have a unix OS, you can usually install it with a package manager (`brew install lua`, `apt install lua5.4`, etc).


<br />

# Installation

If you have git, you can install RXPAL in your project's directory with one command: `git clone https://github.com/jmaxor/rxpal.git`. Otherwise, you can download the [latest RXPAL release](https://github.com/jmaxor/rxpal/releases) and extract it into a folder in your project's directory. If you use the latter, make sure the extracted folder is simply named `rxpal`.

If you want to install RXPAL globally on your computer, you can run this command and place the `rxpal` folder at the path printed (you might need to create some directories to build the full path):

```
lua -e "print(package.path:match('([^;]*)[\\\\/]%?[/\\\\]init%.lua'))"
```


<br />

# Usage

1. Require rxpal in your lua project: `require("rxpal")` or `require("rxpal.main")`
2. Create your guide (see examples and documentation)
3. Run your program and pipe the output to a file (ex. `lua warlock_guide.lua > "C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns\warlock_1_20\MyGuide.lua"`)


<br />

# Documentation

https://github.com/jmaxor/rxpal/blob/main/documentation.md
