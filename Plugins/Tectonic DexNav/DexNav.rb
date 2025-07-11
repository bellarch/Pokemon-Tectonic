class NewDexNav
  DEXNAV_LINE_HEIGHT = 60
  DEXNAV_ROW_MAX_SIZE = 6
  DEXNAV_LIST_START_Y = 42
  DEXNAV_MIN_SPRITE_Y = 44

  def initialize
		# Load encounter data for the given route
		encounter_array = getDexNavEncounterDataForMap()
		if !encounter_array || encounter_array.length == 0
			pbMessage(_INTL("There are no encounters on this map."))
			return
		end

		# Set up the two viewports to hold UI elements
		@viewport1 = Viewport.new(0, 0, Graphics.width, Graphics.height)
		@viewport1.z = 99999
		@viewport2 = Viewport.new(0, 0, Graphics.width, Graphics.height)
		@viewport2.z = 99999
		@viewport3 = Viewport.new(0, 0, Graphics.width, Graphics.height)
		@viewport3.z = 999999
		@sprites = {}
	
		# Set up all the sprites
		@sprites["background"] = IconSprite.new(0,0,@viewport1)
		bg_path = "Graphics/Pictures/Pokedex/dexnav"
		bg_path += "_dark" if darkMode?
		@sprites["background"].setBitmap(_INTL(bg_path))
		
		@sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport1)
		pbSetSystemFont(@sprites["overlay"].bitmap)
		@sprites["overlay2"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport2)
		pbSetSystemFont(@sprites["overlay2"].bitmap)
		@sprites["name_overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport1)

    @sprites["nav_arrow"] = AnimatedSprite.new("Graphics/Pictures/rightarrow",8,40,28,2,@viewport3)
    @sprites["nav_arrow"].visible = false
    @sprites["nav_arrow"].play

		@sprites["scroll_arrow_up"] = AnimatedSprite.new("Graphics/Pictures/uparrow",8,28,40,2,@viewport3)
		@sprites["scroll_arrow_up"].x = (Graphics.width - 48)
		@sprites["scroll_arrow_up"].y = 60
		@sprites["scroll_arrow_up"].visible = false
    @sprites["scroll_arrow_up"].play

		@sprites["scroll_arrow_down"] = AnimatedSprite.new("Graphics/Pictures/downarrow",8,28,40,2,@viewport3)
		@sprites["scroll_arrow_down"].x = (Graphics.width - 48)
		@sprites["scroll_arrow_down"].y = 332
		@sprites["scroll_arrow_down"].visible = false
    @sprites["scroll_arrow_down"].play
	
		# Find which encounter sets the player has yet completed
		displaySpecies = []
		@encounterTypesCompletion = {}
		encounter_array.each do |entry|
			encounterType = entry[0]
			next if encounterType == :Special
			@encounterTypesCompletion[encounterType] = true unless @encounterTypesCompletion.has_key?(encounterType)
			@encounterTypesCompletion[encounterType] = false unless $Trainer.owned?(entry[1].species)
		end
		@numEncounterTypesCompleted = 0
		@encounterTypesCompletion.each do |encounter_type,isCompleted|
			@numEncounterTypesCompleted += 1 if isCompleted
			displaySpecies.push([])
		end
		
		# Create the sprites that show the encounters for this area
		owned = 0
		allSeen = true
		allOwned = true
		@totalRows = 0
		@pkmnsprites = []
		@encounterlabels = []

    encounter_array.each do |encounter_data|
			encounterType = encounter_data[0]
			species_data = encounter_data[1]
			species = species_data.species

			groupIndex = @encounterTypesCompletion.keys.index(encounterType)
			iconIndex = displaySpecies[groupIndex].length
			displaySpecies[groupIndex].push(species_data)

			newPokemonIcon = PokemonSpeciesIconSprite.new(species,@viewport2)
			if @pkmnsprites[groupIndex].nil?
				@pkmnsprites[groupIndex] = []
				@encounterlabels.push(getNameForEncounterType(encounterType))
			end
			@pkmnsprites[groupIndex].push(newPokemonIcon)
			@totalRows += 1 if iconIndex % DEXNAV_ROW_MAX_SIZE == 0
			@sprites["pkmn_sprite_#{groupIndex}_#{iconIndex}"] = newPokemonIcon
			
			newPokemonIcon.form = species_data.form if species_data.form != 0
			newPokemonIcon.z = -1
			
			unless $Trainer.pokedex.seen?(species)
				newPokemonIcon.silhouette = true
				allSeen = false
			end
			
			allOwned = false unless $Trainer.pokedex.owned?(species)
    end
	
		# Determine what the status of the completion of this area is
		@status = "Incomplete"
		@status = "All seen!" if allSeen
		@status = "All owned!" if allOwned
		
		@navigationRow = $PokemonTemp.navigationRow || 0
		@navigationColumn = $PokemonTemp.navigationColumn || 0
		@row_heights = []

		drawSprites

		updateNavArrow
	
    pbFadeInAndShow(@sprites)
	
    openMainDexNavScreen(displaySpecies)
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def dispose
    pbFadeOutAndHide(@sprites) {pbUpdate}
    pbDisposeSpriteHash(@sprites)
    @viewport1.dispose
		@viewport2.dispose
    @viewport3.dispose
  end

  def updateNavArrow
		@sprites["nav_arrow"].x = 64 + 64 * @navigationColumn
		@sprites["nav_arrow"].y = DEXNAV_LIST_START_Y + 64 + @row_heights[@navigationRow] + visualHeightOffset
  end
  
  def openMainDexNavScreen(speciesByEncounterGroup)	
		inputActive = speciesByEncounterGroup.length != 0
		@sprites["nav_arrow"].visible = true if inputActive

		displaySpecies = []
		speciesByEncounterGroup.each do |encounterGroupArray|
			displaySpecies.concat(encounterGroupArray.each_slice(DEXNAV_ROW_MAX_SIZE).to_a)
		end
		
		if displaySpecies.length != 0
			# Begin taking input for the main dexnav screen
			highestLeftRepeat = 0
			highestRightRepeat = 0
			highestUpRepeat = 0
			highestDownRepeat = 0
			loop do
				Graphics.update
				Input.update
				pbUpdateSpriteHash(@sprites)
				
				updateNavArrow
				@sprites["scroll_arrow_up"].visible = @navigationRow > 3
				@sprites["scroll_arrow_down"].visible = (displaySpecies.length - @navigationRow) > 1 && displaySpecies.length >= 5

				prevNavCol = @navigationColumn
				prevNavRow = @navigationRow

				thisRowLength = displaySpecies[@navigationRow].length
				
				highlightedSpeciesData = displaySpecies[@navigationRow][@navigationColumn]
				highlightedSpecies = highlightedSpeciesData.species
				if Input.repeat?(Input::DOWN)
					highestUpRepeat = 0
					if @navigationRow < @totalRows - 1
						repeats = 1 + Input.time?(Input::DOWN) / 100000
						if repeats > highestDownRepeat
							highestDownRepeat = repeats
							@navigationRow += 1
							pbPlayCursorSE
						end
					elsif Input.time?(Input::DOWN) < 500
						@navigationRow = 0
						pbPlayCursorSE
					end
				elsif Input.repeat?(Input::UP)
					highestDownRepeat = 0
				if @navigationRow >= 1
					repeats = 1 + Input.time?(Input::UP) / 100000
					if repeats > highestUpRepeat
						highestUpRepeat = repeats
						@navigationRow -= 1
						pbPlayCursorSE
					end
				elsif Input.time?(Input::UP) < 500
					@navigationRow = @totalRows - 1
					pbPlayCursorSE
				end
				elsif Input.repeat?(Input::LEFT) && @navigationColumn > 0
					highestRightRepeat = 0
					repeats = 1 + Input.time?(Input::LEFT) / 100000
					if repeats > highestLeftRepeat
						highestLeftRepeat = repeats
						@navigationColumn -= 1
						pbPlayCursorSE
					end
				elsif Input.repeat?(Input::RIGHT) && @navigationColumn < thisRowLength - 1
					highestLeftRepeat = 0
					repeats = 1 + Input.time?(Input::RIGHT) / 100000
					if repeats > highestRightRepeat
						highestRightRepeat = repeats
						@navigationColumn += 1
						pbPlayCursorSE
					end
				elsif Input.trigger?(Input::USE)
					if debugControl
						pbAddPokemonSilent(highlightedSpeciesData.species,getLevelCap)
						pbMessage(_INTL("Added {1}", highlightedSpeciesData.species))
						next
					end
					unless $Trainer.pokedex.seen?(highlightedSpecies)
						pbPlayBuzzerSE
						next
					end
					cmdStartSearch = -1
					cmdMasterDex = -1
					commands = []
					if $Trainer.pokedex.owned?(highlightedSpecies)
						if $PokemonTemp.currentDexSearch != nil && $PokemonTemp.currentDexSearch.is_a?(Array)
							commands[cmdStartSearch = commands.length] = _INTL("Replace Search")	
						else
							commands[cmdStartSearch = commands.length] = _INTL("Search Nearby")				
						end
					end
					commands[cmdMasterDex = commands.length] = _INTL("MasterDex")
					commands.push(_INTL("Cancel"))
					command = pbMessage(_INTL("Do what with this species?"),commands,commands.length)
					if command == cmdStartSearch && cmdStartSearch > -1
						if $catching_minigame.active?
							pbPlayBuzzerSE
							pbMessage(_INTL("This feature of the DexNav is unavailable during this minigame."))
							next
						end
						searchTime = 15 + rand(40)
						pbMessage(_INTL("Searching\\ts[15]...\\wtnp[{1}]", searchTime))
						pbMessage(_INTL("Oh! A {1} was found nearby!", highlightedSpeciesData.real_name))
						pbFadeOutAndHide(@sprites)
						generateSearch(highlightedSpeciesData)
						$search_overlay.dispose if $search_overlay
						$search_overlay = DexNav_SearchOverlay.new
						break
					elsif command == cmdMasterDex && cmdMasterDex > -1
						@sprites["nav_arrow"].visible = false
						$Trainer.pokedex.set_last_form_seen(highlightedSpeciesData.species, 0, highlightedSpeciesData.form)
						openSingleDexScreen(highlightedSpeciesData.species)
						@sprites["nav_arrow"].visible = true
					end
				elsif Input.trigger?(Input::BACK)
					break
				else
					highestDownRepeat = 0
					highestUpRepeat = 0
					highestLeftRepeat = 0
					highestRightRepeat = 0
				end
				if prevNavRow != @navigationRow
					@navigationColumn = [@navigationColumn,displaySpecies[@navigationRow].length - 1].min
				end
				if prevNavCol != @navigationColumn || prevNavRow != @navigationRow
					speciesFormName =  highlightedSpeciesData.real_name 
					speciesFormName += "(#{highlightedSpeciesData.form_name})" if highlightedSpeciesData.form != 0
					@displayedName = $Trainer.pokedex.seen?(highlightedSpecies) ? speciesFormName : _INTL("Unknown")
					drawSprites
				end
			end
		else
			pbFadeOutAndHide(@sprites)
		end
		$PokemonTemp.navigationRow = @navigationRow
		$PokemonTemp.navigationColumn = @navigationColumn
		dispose
  end

  def visualHeightOffset
		if @navigationRow >= @row_heights.length
			return 0
		end
		return -1 * @row_heights[[@navigationRow-2,0].max]
  end

  def drawSprites
    @sprites["overlay"].bitmap.clear
		@sprites["overlay2"].bitmap.clear

		base = MessageConfig.pbDefaultTextMainColor
		shadow = MessageConfig.pbDefaultTextShadowColor

		encounterGroupLabels = []
		ownedIconImagePositions = []
		encounterGroupCheckboxesImagePositions = []
		horizontalLineImagePositions = []

		lineHeight = 0
		@row_heights.clear
		@pkmnsprites.each_with_index do |groupSpriteArray,groupIndex|
			@row_heights.push(lineHeight)

			horizontalLineImagePositions.push(["Graphics/Pictures/horizontal_line",44,lineHeight]) unless groupIndex == 0

			encounterLabel = @encounterlabels[groupIndex]
			encounterGroupLabels.push([encounterLabel,Graphics.width / 2,lineHeight + 4,2, base, shadow])

			lineHeight += DEXNAV_LINE_HEIGHT * 3/4

			if @encounterTypesCompletion.values[groupIndex]
				checkBoxFileName = "Graphics/Pictures/checkbox_active"
			else
				checkBoxFileName = "Graphics/Pictures/checkbox_inactive"
			end
			checkboxY = lineHeight + 18
			encounterGroupCheckboxesImagePositions.push([checkBoxFileName,40,checkboxY])

			groupSpriteArray.each_with_index do |sprite, iconIndex|
				if iconIndex > 0 && iconIndex % DEXNAV_ROW_MAX_SIZE == 0
					lineHeight += DEXNAV_LINE_HEIGHT
					@row_heights.push(lineHeight)
				end

				sprite.x = 28 + 64 + 64 * (iconIndex % DEXNAV_ROW_MAX_SIZE)
				sprite.y = DEXNAV_LIST_START_Y + lineHeight

				if $Trainer.pokedex.owned?(sprite.species)
					ownedIconX = sprite.x + 8
					ownedIconY = DEXNAV_LIST_START_Y + lineHeight - 32
					ownedIconImagePositions.push(["Graphics/Pictures/Battle/icon_own",ownedIconX,ownedIconY])
				end
			end

			lineHeight += DEXNAV_LINE_HEIGHT + 8
    end
		drawInformation()

		# Draw the text
		textPos = []
		adjustGraphicalArrayForVisualOffset(encounterGroupLabels, textPos)
		pbDrawTextPositions(@sprites["overlay2"].bitmap, textPos)

		# Draw the images
		imagePos = []
		adjustGraphicalArrayForVisualOffset(encounterGroupCheckboxesImagePositions, imagePos)
		adjustGraphicalArrayForVisualOffset(ownedIconImagePositions, imagePos)
		adjustGraphicalArrayForVisualOffset(horizontalLineImagePositions, imagePos)

		# Adjust the pokemon sprites
		@pkmnsprites.each_with_index do |groupSpriteArray,groupIndex|
			groupSpriteArray.each_with_index do |sprite, iconIndex|
				sprite.y += visualHeightOffset
				sprite.visible = sprite.y >= DEXNAV_MIN_SPRITE_Y
			end
		end

		pbDrawImagePositions(@sprites["overlay2"].bitmap, imagePos)
  end

  def adjustGraphicalArrayForVisualOffset(input_array, output_array)
		input_array.each do |input_array_element|
			newY = input_array_element[2] + DEXNAV_LIST_START_Y + visualHeightOffset
			next if newY < DEXNAV_MIN_SPRITE_Y
			input_array_element[2] = newY
			output_array.push(input_array_element)
		end
  end
  
  def drawInformation()
		overlay = @sprites["overlay"].bitmap
		
		base       = MessageConfig.pbDefaultTextMainColor
		faded_base = MessageConfig.pbDefaultFadedTextColor
		shadow     = MessageConfig.pbDefaultTextShadowColor
		
		xLeft = 40
		textpos = [[_INTL("DexNav: {1}", $game_map.name),40,-4,0,Color.new(248, 248, 248),Color.new(0, 0, 0)]]
		
		pbDrawTextPositions(overlay, textpos)
  end

  def generateSearch(species_data)
    if !defined?($PokemonGlobal.dexNavEggMovesUnlocked) || !$PokemonGlobal.dexNavEggMovesUnlocked
        move = nil
    else
        move = getRandomNonLevelMove(species_data.species)
    end
	item = generateWildHeldItem(species_data.species)
	abilityIndex = rand(2)
	$PokemonTemp.currentDexSearch = [species_data,move,abilityIndex,item]
  end
end

def searchActive?()
	return !$PokemonTemp.currentDexSearch.nil? && $PokemonTemp.currentDexSearch.is_a?(Array)
end

class DexNav_SearchOverlay
	OVERLAY_WIDTH = 280
	OVERLAY_HEIGHT_BASE = 32
	OVERLAY_HEIGHT_PER_LINE = 32

	def initialize()
		@sprites = {}
		@viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
		@viewport.z = 999
		searchWindowX = Graphics.width - OVERLAY_WIDTH - 8
		searchWindowY = Graphics.height - OVERLAY_HEIGHT_BASE - 8
		@sprites["search"] = Window_AdvancedTextPokemon.newWithSize("",searchWindowX,searchWindowY,OVERLAY_WIDTH,OVERLAY_HEIGHT_BASE,@viewport)
		@sprites["search"].setSkin("Graphics/Windowskins/frlgtextskin")
		@sprites["search"].opacity = 140
		@sprites["search"].visible = false
	
		@sprites["searchIcon"] = PokemonSpeciesIconSprite.new(nil,@viewport)
		@sprites["searchIcon"].x = Graphics.width - 72
		@sprites["searchIcon"].y = searchWindowY - 8
		@sprites["searchIcon"].z += 100
		@sprites["searchIcon"].visible = false

		drawSearchOverlay()
	end

	def pbUpdate
		pbUpdateSpriteHash(@sprites)
	end
	
	def dispose
		pbDisposeSpriteHash(@sprites)
		@viewport.dispose
	end

	def drawSearchOverlay()
		return if !searchActive?
		species_data = $PokemonTemp.currentDexSearch[0]
		navAbil1 = species_data.abilities
		if navAbil1[1] != nil
		  navAbil = [navAbil1[0],navAbil1[1]]
		else
		  navAbil = [navAbil1[0],navAbil1[0]]
		end
		abilityID = navAbil[$PokemonTemp.currentDexSearch[2]]
		abilityName = GameData::Ability.get(abilityID).name
	
		@sprites["search"].visible = true

		move = getMoveName($PokemonTemp.currentDexSearch[1]) if $PokemonTemp.currentDexSearch[1]
		if $PokemonTemp.currentDexSearch[3]
			item = getItemName($PokemonTemp.currentDexSearch[3])
		else
			item = _INTL("No item")
		end

		searchText = "#{species_data.name}\n#{abilityName}\n#{item}\n"
		searchWindowLines = 3
		if move
			searchText += "#{move}\n"
			searchWindowLines += 1
		end
		@sprites["search"].text = searchText
		@sprites["search"].height = OVERLAY_HEIGHT_BASE + OVERLAY_HEIGHT_PER_LINE * searchWindowLines
		@sprites["search"].y = Graphics.height - @sprites["search"].height - 8
		
		@sprites["searchIcon"].visible = true
		@sprites["searchIcon"].species = species_data.species
		@sprites["searchIcon"].form = species_data.form
		@sprites["searchIcon"].y = @sprites["search"].y - 8
	
		Graphics.update
		pbFadeInAndShow(@sprites) {pbUpdate}
	end
end

def dexNavActive?
	encounters = getDexNavEncounterDataForMap
	return encounters && encounters.length > 0
end

def getDexNavEncounterDataForMap(mapid = -1)
    mapid = $game_map.map_id if mapid == -1
    encounters = GameData::Encounter.get(mapid, $PokemonGlobal.encounter_version)
    return nil if encounters == nil
    encounter_tables = Marshal.load(Marshal.dump(encounters.types))
	
		allEncounters = []
		encounters.types.keys.each do |encounter_type|
			next if encounter_type == :Special
			encounterList = encounter_tables[encounter_type]
			next if !encounterList
			encounterList.each do |encounter|
				speciesSym = encounter[1]
				species_data = GameData::Species.get(speciesSym)
				next if species_data.isLegendary?
				allEncounters.push([encounter_type,species_data])
			end
		end
	  
    allEncounters.uniq!
    allEncounters.compact!
    allEncounters.sort!{ |a,b|
		speciesA = GameData::Species.get(a[1])
		speciesB = GameData::Species.get(b[1])
		baseSpeciesA = GameData::Species.get(speciesA.species)
		baseSpeciesB = GameData::Species.get(speciesB.species)
		if baseSpeciesA.id_number == baseSpeciesB.id_number
			speciesA.form <=> speciesB.form
		else
			baseSpeciesA.id_number <=> baseSpeciesB.id_number
		end
	}
	return allEncounters
end

Events.onMapChanging +=proc {|_sender,e|
    $search_overlay.dispose if $search_overlay
	$PokemonTemp.currentDexSearch = nil
	$PokemonTemp.navigationRow = 0
	$PokemonTemp.navigationColumn = 0
}

Events.onWildPokemonCreate += proc {|sender,e|
    pokemon = e[0]
    # Checks current search value, if it exists, sets the Pokemon to it's qualities
    if $PokemonTemp.currentDexSearch != nil && $PokemonTemp.currentDexSearch.is_a?(Array)
		currentTileEncounterType = $PokemonEncounters.encounter_type
		species_data = $PokemonTemp.currentDexSearch[0]
		species = species_data.species
		# If the generated pokemon can actually be found here
		begin
			encounterable = $PokemonEncounters.speciesEncounterableInType(species,currentTileEncounterType)
		rescue ArgumentError
			encounterable = false
		end
		if encounterable
			echoln("Overwriting the discovered wild pokemon with a #{species}!")
			overwriteWildPokemonSpecies(pokemon,species)
			pokemon.ability_index = $PokemonTemp.currentDexSearch[2]
			pokemon.form = species_data.form
			pokemon.reset_moves
			pokemon.learn_move($PokemonTemp.currentDexSearch[1]) if $PokemonTemp.currentDexSearch[1]
			pokemon.removeItems
			pokemon.setItems($PokemonTemp.currentDexSearch[3]) if $PokemonTemp.currentDexSearch[3]
			# There is a higher chance for shininess
			pokemon.shinyRolls *= 2
			$PokemonTemp.currentDexSearch = nil
			$search_overlay.dispose if $search_overlay
		else
			echoln("Cannot find #{species} in #{currentTileEncounterType}!")
		end
    end
}

def overwriteWildPokemonSpecies(pokemon,species)
    level = pokemon.level
    pokemon.species = species
    pokemon.level = level # Level is reset on species change
    pokemon.name = GameData::Species.get(pokemon.species).name
end

# Gets a random ID of a legal egg move of the given species and returns it as a move object.
def getRandomNonLevelMove(species)
	generatedSpeciesData = GameData::Species.get(species)
	moves = generatedSpeciesData.non_level_moves
	return moves.sample
end

def incrementDexNavCounts(caught)
	$PokemonGlobal.caughtCountsPerMap = {} if !$PokemonGlobal.caughtCountsPerMap
	if caught
		if $PokemonGlobal.caughtCountsPerMap.has_key?($game_map.map_id)
			$PokemonGlobal.caughtCountsPerMap[$game_map.map_id][0] += 1
		else
			$PokemonGlobal.caughtCountsPerMap[$game_map.map_id] = [1,0]
		end
	else
		if $PokemonGlobal.caughtCountsPerMap.has_key?($game_map.map_id)
			$PokemonGlobal.caughtCountsPerMap[$game_map.map_id][1] += 1
		else
			$PokemonGlobal.caughtCountsPerMap[$game_map.map_id] = [0,1]
		end
	end
end