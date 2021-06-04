execute as @a[tag=!joined] run tellraw @s {"text":"Welcome to the Showcase of our own Minecraft Shader!"}
execute as @a[tag=!joined] run tellraw @s [{"text":"Make sure to check out each feature, they are marked by a\n"},{"text":"diamond pillar","color":"aqua"},{"text":"."}]
execute as @a[tag=!joined] run tp @s -92 102 145 -90 0
execute as @a[tag=!joined] run tag @s add joined