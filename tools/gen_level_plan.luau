--[[
	Generates docs/LEVEL_PLAN.md from src/shared/LevelPlan.luau.
	    lune run tools/gen_level_plan.luau
]]

local fs = require("@lune/fs")
local Loader = require("../tests/loader")

local LevelPlan = Loader.get("ReplicatedStorage", "Shared", "LevelPlan")
local Zones = Loader.get("ReplicatedStorage", "Shared", "Zones")
local Config = Loader.get("ReplicatedStorage", "Shared", "Config")

local lines = {
	"# Plan des 200 niveaux",
	"",
	"> Fichier généré par `lune run tools/gen_level_plan.luau` depuis `src/shared/LevelPlan.luau` (source de vérité). Ne pas éditer à la main.",
	"",
	"Colonnes : **Diff.** = note de difficulté 1.00–10.99 (zone + courbe interne) · **Temps** = estimation d'un premier passage réussi (hors morts) · **CP** = checkpoint au début du niveau · **Final** = Final Stage.",
	"",
	"Courbe dans chaque zone : X1 introduction · X2–X5 apprentissage · X6–X10 développement · X11–X15 difficulté · X16–X18 maîtrise · X19 pré-finale · X20 Final Stage (pas de checkpoint entre X19 et X20).",
	"",
}

for zoneId = 1, Config.ZONE_COUNT do
	local zone = Zones[zoneId]
	local first = (zoneId - 1) * Config.LEVELS_PER_ZONE + 1
	table.insert(lines, ("## Zone %d — %s — %s (%d–%d) · %s"):format(zoneId, zone.Name, zone.Theme, first, first + 19, zone.Difficulty))
	table.insert(lines, "")
	table.insert(lines, ("*%s* — %s"):format(zone.Tagline, zone.Mechanic))
	table.insert(lines, "")
	table.insert(lines, "| Lvl | Nom | Diff. | Mécanique principale | Secondaire | Longueur | Temps | Défi principal | CP | Final |")
	table.insert(lines, "|---:|---|---:|---|---|---|---:|---|:-:|:-:|")
	for level = first, first + 19 do
		local info = LevelPlan.get(level)
		local name = if info.FinalStage then ("**%s**"):format(info.Name) else info.Name
		table.insert(lines, ("| %d | %s | %.2f | %s | %s | %s | %ds | %s | %s | %s |"):format(
			level,
			name,
			info.Difficulty,
			info.Main,
			info.Secondary,
			info.Length,
			info.EstimatedSeconds,
			info.Challenge,
			if info.Checkpoint then "✔" else "✘",
			if info.FinalStage then "★" else ""
		))
	end
	table.insert(lines, "")
end

fs.writeFile("docs/LEVEL_PLAN.md", table.concat(lines, "\n"))
print("docs/LEVEL_PLAN.md written")
