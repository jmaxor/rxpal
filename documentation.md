# RXPAL Reference

When required into your project, RXPAL will create a number of functions (listed below) which serve as commands to create RestedXP steps.

A few basic things to know:
1. Auto-generated coordinates are created by averaging the x and y spawn locations of things (npcs, mobs, objects) that will satisfy a given step. This way of generating coordinates works well when those things spawn in a small concentrated area and do not patrol very far. But for things that have spawn locations all over the place or have a large patrol, you should consider adding your own coordinates using the `step` function.
2. Calling subsequent RXPAL functions which create dialogue steps for the same NPC (or object) will be combined into one step automatically. For example, the following will create a single step to talk to `Gornek` and do both quest actions:

    ```
    turnin "your place in the world"
    accept "cutting teeth"
    ```


<br />

# init(settings)

This function must be called before calling any of the other RXPAL functions, and allows you to provide some basic settings. It accepts one argument, which is a LUA table containing the settings.

### Settings:
- `faction` (string): either `"horde"` or `"alliance"`. This will be used to apply faction-specific database fixes


<br />

# register(group, guideName, nextGuide, customHeaders, file)

Builds the `RXPGuides.RegisterGuide` call. All steps inserted between this function and the next `register` or `finish` call will be included in this guide.

### Arguments:
- `group` (string): this will be passed as the first argument to the `RXPGuides.RegisterGuide`  call. This is the group that RestedXP will put this guide in
- `guideName` (string): name for this guide. Adds a `#name` tag at the top of the guide
- `nextGuide` (string, optional): the name of the guide that RestedXP will load after this one is completed. Adds a `#next` tag at the top of the guide
- `customHeaders` (string, optional): text for any other guide headers you want to give to RestedXP for this guide. Can be used to restrict the guide to only loading for certain classes/races (ex `"<< Orc Warlock"`)
- `file` (string, optional): lua file that will be called at the end of the `register` call


<br />

# finish()

This function ties everything together and outputs the generated guides - should be called at the end of your program.


<br />

# step(...)

This function takes any number of arguments, and combines them into a step that is inserted into the the latest registered guide. It serves two purposes:
1. Allows you to add custom text directly to a RestedXP step, so you still have complete control for things that RXPAL cannot generate steps for
2. Allows you to group multiple commands into a single step

Arguments can either be:
1. Strings, which will be sent to RestedXP directly
2. Any function which inserts a step into the guide (`accept`, `complete`, etc.)
3. Any function which returns a step (`autonpc` and `autoobject`)


<br />

# accept(quest)

Builds a step to accept a quest, and inserts that step into the latest registered guide.

If the quest is accepted from an npc or object, the step will include auto-generated coordinates, targeting, and some flavor text. If the quest is accepted from an item, it will include RestedXP commands to collect and use that item.

If you provide a quest name and there are multiple matches, RXPAL will do its best to find the correct quest based on prereqs for each match and which quests you've already called the `turnin` function for.

### Arguments:
- `quest` (string or number): name or ID of the quest to accept


<br />

# turnin(quest, reward)

Builds a step to turn in a quest, and inserts that step into the latest registered guide. The quest to turn in must have previously been picked up with the `accept` function.

The step generated will include auto-generated coordinates, targeting, and some flavor text.

### Arguments:
- `quest` (string or number): name or ID of the quest to turn in
- `reward` (number, optional): which reward to auto-select when tuning in, typically 1-5

### Aliases:

A number of aliases are provided for ease of use and are in the format `turnin[1-5]`. For example, if you want to turnin `cutting teeth` and auto-select the second reward, you can call the function as `turnin("cutting teeth", 2)` or use the alias `turnin2 "cutting teeth"`. 


<br />

# complete(quest, objective, withCoords)

Builds a step to complete an objective for a quest, and inserts that step into the latest registered guide.

### Arguments:
- `quest` (string or number): name or ID of the quest to complete an objective for
- `objective` (number, default 1): Which objective to complete, typically 1-5
- `withCoords` (boolean, default `false`): Whether to generate coordinates for this objective.

### Aliases:

A number of aliases are provided for ease of use in the format `complete[1-5][wc]`. For example, if you want to complete the 2nd objective of `encroachment` with coordinates, you can call the function as `complete("encroachment", 2, true)` or use the alias `complete2wc "encroachment"`. 


<br />

# buy(num, item, from)

Builds a step to auto-buy any number of an item from a specific vendor, and inserts that step into the latest registered guide.

The step generated will include auto-generated coordinates, targeting, and some flavor text.

### Arguments:
- `num` (number): quantity of the item to buy
- `item` (string or number): name or ID of the item to buy
- `from` (string or number): name or ID of the vendor to buy from


<br />

# collect(num, item)

Builds a step to collect any number of an item, and inserts that step into the latest registered guide.

### Arguments:
- `num` (number): quantity of the item to collect
- `item` (string or number): name or ID of the item to collect


<br />

# train(skill, from, rank)

Builds a step to train a skill from a trainer, and inserts that step into the latest registered guide.

The step generated will include auto-generated coordinates, targeting, and some flavor text.

### Arguments:
- `skill` (string or number): name or ID of the skill to train
- `from` (string or number): name or ID of the trainer to train from
- `rank` (string or number, optional): rank of the skill to train


<br />

# autonpc(npc)

Builds the flavor text, auto-generated coordinates, and targeting portion of an npc dialogue step. Instead of inserting that step automatically, this function returns the step, so won't have much use unless you're using it as an argument for the `step` function.

### Arguments:
- `npc` (string or number): name or ID of the npc


<br />

# autoobject(object)

Builds the flavor text and auto-generated coordinates of an object dialogue step. Instead of inserting that step automatically, this function returns the step, so won't have much use unless you're using it as an argument for the `step` function.

### Arguments:
- `object` (string or number): name or ID of the object

