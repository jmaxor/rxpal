# RXPAL
A data-powered abstraction layer for creating RestedXP guides.

Allows you to write this:
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
And much more!


<br />

# Example projects
- https://github.com/jmaxor/hunter-1-20-guide
- https://github.com/jmaxor/warlock-1-20-guide


<br />

# Requirements

Just a LUA interpreter (5.1 or higher). I recommend luarocks, which comes packaged with one: https://github.com/luarocks/luarocks/wiki/Download


<br />

# Installation

If you have luarocks, you can install RXPAL globally on your computer with one command: `luarocks install rxpal`. Otherwise, you can clone the source with git: `git clone https://github.com/jmaxor/rxpal.git` or download it manually with github's web interface.


<br />

# Usage

1. Require rxpal in your lua project: `require("rxpal")`
2. Create your guide (see examples and documentation)
3. Run your program and pipe the output to a file (ex. `lua warlock_guide.lua > "C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns\warlock_1_20\MyGuide.lua"`)


<br />

# Documentation

https://github.com/jmaxor/rxpal/blob/main/documentation.md