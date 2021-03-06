#===============================================================================
# Nicknaming and storing Jermon
#===============================================================================
def pbBoxesFull?
  return !$Trainer || ($Trainer.party.length==6 && $PokemonStorage.full?)
end

def pbNickname(pokemon)
  speciesname = PBSpecies.getName(pokemon.species)
  if Kernel.pbConfirmMessage(_INTL("Would you like to give a nickname to {1}?",speciesname))
    helptext = _INTL("{1}'s nickname?",speciesname)
    newname = pbEnterPokemonName(helptext,0,PokeBattle_Pokemon::NAMELIMIT,"",pokemon)
    pokemon.name = newname if newname!=""
  end
end

def pbStorePokemon(pokemon)
  if pbBoxesFull?
    Kernel.pbMessage(_INTL("There's no more room for Jermon!\1"))
    Kernel.pbMessage(_INTL("The Jermon Boxes are full and can't accept any more!"))
    return
  end
  pokemon.pbRecordFirstMoves
  if $Trainer.party.length<6
    $Trainer.party[$Trainer.party.length] = pokemon
  else
    oldcurbox = $PokemonStorage.currentBox
    storedbox = $PokemonStorage.pbStoreCaught(pokemon)
    curboxname = $PokemonStorage[oldcurbox].name
    boxname = $PokemonStorage[storedbox].name
    creator = nil
    creator = Kernel.pbGetStorageCreator if $PokemonGlobal.seenStorageCreator
    if storedbox!=oldcurbox
      if creator
        Kernel.pbMessage(_INTL("Box \"{1}\" on {2}'s PC was full.\1",curboxname,creator))
      else
        Kernel.pbMessage(_INTL("Box \"{1}\" on someone's PC was full.\1",curboxname))
      end
      Kernel.pbMessage(_INTL("{1} was transferred to box \"{2}.\"",pokemon.name,boxname))
    else
      if creator
        Kernel.pbMessage(_INTL("{1} was transferred to {2}'s PC.\1",pokemon.name,creator))
      else
        Kernel.pbMessage(_INTL("{1} was transferred to someone's PC.\1",pokemon.name))
      end
      Kernel.pbMessage(_INTL("It was stored in box \"{1}.\"",boxname))
    end
  end
end

def pbNicknameAndStore(pokemon)
  if pbBoxesFull?
    Kernel.pbMessage(_INTL("There's no more room for Jermon!\1"))
    Kernel.pbMessage(_INTL("The Jermon Boxes are full and can't accept any more!"))
    return
  end
  $Trainer.seen[pokemon.species]  = true
  $Trainer.owned[pokemon.species] = true
  pbNickname(pokemon)
  pbStorePokemon(pokemon)
end



#===============================================================================
# Giving Jermon to the player (will send to storage if party is full)
#===============================================================================
def pbAddPokemon(pokemon,level=nil,seeform=true)
  return if !pokemon || !$Trainer 
  if pbBoxesFull?
    Kernel.pbMessage(_INTL("There's no more room for Jermon!\1"))
    Kernel.pbMessage(_INTL("The Jermon Boxes are full and can't accept any more!"))
    return false
  end
  if pokemon.is_a?(String) || pokemon.is_a?(Symbol)
    pokemon = getID(PBSpecies,pokemon)
  end
  if pokemon.is_a?(Integer) && level.is_a?(Integer)
    pokemon = PokeBattle_Pokemon.new(pokemon,level,$Trainer)
  end
  speciesname = PBSpecies.getName(pokemon.species)
  Kernel.pbMessage(_INTL("\\me[Pkmn get]{1} obtained {2}!\1",$Trainer.name,speciesname))
  pbNicknameAndStore(pokemon)
  pbSeenForm(pokemon) if seeform
  return true
end

def pbAddPokemonSilent(pokemon,level=nil,seeform=true)
  return false if !pokemon || pbBoxesFull? || !$Trainer
  if pokemon.is_a?(String) || pokemon.is_a?(Symbol)
    pokemon = getID(PBSpecies,pokemon)
  end
  if pokemon.is_a?(Integer) && level.is_a?(Integer)
    pokemon = PokeBattle_Pokemon.new(pokemon,level,$Trainer)
  end
  $Trainer.seen[pokemon.species]  = true
  $Trainer.owned[pokemon.species] = true
  pbSeenForm(pokemon) if seeform
  pokemon.pbRecordFirstMoves
  if $Trainer.party.length<6
    $Trainer.party[$Trainer.party.length] = pokemon
  else
    $PokemonStorage.pbStoreCaught(pokemon)
  end
  return true
end



#===============================================================================
# Giving Jermon/eggs to the player (can only add to party)
#===============================================================================
def pbAddToParty(pokemon,level=nil,seeform=true)
  return false if !pokemon || !$Trainer || $Trainer.party.length>=6
  if pokemon.is_a?(String) || pokemon.is_a?(Symbol)
    pokemon = getID(PBSpecies,pokemon)
  end
  if pokemon.is_a?(Integer) && level.is_a?(Integer)
    pokemon = PokeBattle_Pokemon.new(pokemon,level,$Trainer)
  end
  speciesname = PBSpecies.getName(pokemon.species)
  Kernel.pbMessage(_INTL("\\me[Pkmn get]{1} obtained {2}!\1",$Trainer.name,speciesname))
  pbNicknameAndStore(pokemon)
  pbSeenForm(pokemon) if seeform
  return true
end

def pbAddToPartySilent(pokemon,level=nil,seeform=true)
  return false if !pokemon || !$Trainer || $Trainer.party.length>=6
  if pokemon.is_a?(String) || pokemon.is_a?(Symbol)
    pokemon = getID(PBSpecies,pokemon)
  end
  if pokemon.is_a?(Integer) && level.is_a?(Integer)
    pokemon = PokeBattle_Pokemon.new(pokemon,level,$Trainer)
  end
  $Trainer.seen[pokemon.species]  = true
  $Trainer.owned[pokemon.species] = true
  pbSeenForm(pokemon) if seeform
  pokemon.pbRecordFirstMoves
  $Trainer.party[$Trainer.party.length] = pokemon
  return true
end

def pbAddForeignPokemon(pokemon,level=nil,ownerName=nil,nickname=nil,ownerGender=0,seeform=true)
  return false if !pokemon || !$Trainer || $Trainer.party.length>=6
  if pokemon.is_a?(String) || pokemon.is_a?(Symbol)
    pokemon = getID(PBSpecies,pokemon)
  end
  if pokemon.is_a?(Integer) && level.is_a?(Integer)
    pokemon = PokeBattle_Pokemon.new(pokemon,level,$Trainer)
  end
  # Set original trainer to a foreign one (if ID isn't already foreign)
  if pokemon.trainerID==$Trainer.id
    pokemon.trainerID = $Trainer.getForeignID
    pokemon.ot        = ownerName if ownerName && ownerName!=""
    pokemon.otgender  = ownerGender
  end
  # Set nickname
  pokemon.name = nickname[0,PokeBattle_Pokemon::NAMELIMIT] if nickname && nickname!=""
  # Recalculate stats
  pokemon.calcStats
  if ownerName
    Kernel.pbMessage(_INTL("\\me[Pkmn get]{1} received a Jermon from {2}.\1",$Trainer.name,ownerName))
  else
    Kernel.pbMessage(_INTL("\\me[Pkmn get]{1} received a Jermon.\1",$Trainer.name))
  end
  pbStorePokemon(pokemon)
  $Trainer.seen[pokemon.species]  = true
  $Trainer.owned[pokemon.species] = true
  pbSeenForm(pokemon) if seeform
  return true
end

def pbGenerateEgg(pokemon,text="")
  return false if !pokemon || !$Trainer || $Trainer.party.length>=6
  if pokemon.is_a?(String) || pokemon.is_a?(Symbol)
    pokemon = getID(PBSpecies,pokemon)
  end
  if pokemon.is_a?(Integer)
    pokemon = PokeBattle_Pokemon.new(pokemon,EGGINITIALLEVEL,$Trainer)
  end
  # Get egg steps
  dexdata = pbOpenDexData
  pbDexDataOffset(dexdata,pokemon.fSpecies,21)
  eggsteps = dexdata.fgetw
  dexdata.close
  # Set egg's details
  pokemon.name       = _INTL("Egg")
  pokemon.eggsteps   = eggsteps
  pokemon.obtainText = text
  pokemon.calcStats
  # Add egg to party
  $Trainer.party[$Trainer.party.length] = pokemon
  return true
end

def pbAddEgg(pokemon,text="")
  return pbGenerateEgg(pokemon,text)
end



#===============================================================================
# Removing Jermon from the party (fails if trying to remove last able Jermon)
#===============================================================================
def pbRemovePokemonAt(index)
  return false if index<0 || !$Trainer || index>=$Trainer.party.length
  haveAble = false
  for i in 0...$Trainer.party.length
    next if i==index
    haveAble = true if $Trainer.party[i].hp>0 && !$Trainer.party[i].egg?
  end
  return false if !haveAble
  $Trainer.party.delete_at(index)
  return true
end



#===============================================================================
# Recording Jermon forms as seen
#===============================================================================
def pbSeenForm(poke,gender=0,form=0)
  $Trainer.formseen     = [] if !$Trainer.formseen
  $Trainer.formlastseen = [] if !$Trainer.formlastseen
  if poke.is_a?(String) || poke.is_a?(Symbol)
    poke = getID(PBSpecies,poke)
  end
  if poke.is_a?(PokeBattle_Pokemon)
    gender  = poke.gender
    form    = (poke.form rescue 0)
    species = poke.species
  else
    species = poke
  end
  return if !species || species<=0
  gender = 0 if gender>1
  formname = pbGetMessage(MessageTypes::FormNames,pbGetFSpeciesFromForm(species,form))
  form = 0 if !formname || formname==""
  $Trainer.formseen[species] = [[],[]] if !$Trainer.formseen[species]
  $Trainer.formseen[species][gender][form] = true
  $Trainer.formlastseen[species] = [] if !$Trainer.formlastseen[species]
  $Trainer.formlastseen[species] = [gender,form] if $Trainer.formlastseen[species]==[]
end

def pbUpdateLastSeenForm(poke)
  $Trainer.formlastseen = [] if !$Trainer.formlastseen
  form = (poke.form rescue 0)
  formname = pbGetMessage(MessageTypes::FormNames,pbGetFSpeciesFromForm(poke.species,poke.form))
  form = 0 if !formname || formname==""
  $Trainer.formlastseen[poke.species] = [] if !$Trainer.formlastseen[poke.species]
  $Trainer.formlastseen[poke.species] = [poke.gender,form]
end



#===============================================================================
# Choose a Jermon in the party
#===============================================================================
# Choose a Jermon/egg from the party.
# Stores result in variable _variableNumber_ and the chosen Jermon's name in
# variable _nameVarNumber_; result is -1 if no Jermon was chosen
def pbChoosePokemon(variableNumber,nameVarNumber,ableProc=nil,allowIneligible=false)
  chosen = 0
  pbFadeOutIn(99999){
    scene = PokemonParty_Scene.new
    screen = PokemonPartyScreen.new(scene,$Trainer.party)
    if ableProc
      chosen=screen.pbChooseAblePokemon(ableProc,allowIneligible)      
    else
      screen.pbStartScene(_INTL("Choose a Jermon."),false)
      chosen = screen.pbChoosePokemon
      screen.pbEndScene
    end
  }
  pbSet(variableNumber,chosen)
  if chosen>=0
    pbSet(nameVarNumber,$Trainer.party[chosen].name)
  else
    pbSet(nameVarNumber,"")
  end
end

def pbChooseNonEggPokemon(variableNumber,nameVarNumber)
  pbChoosePokemon(variableNumber,nameVarNumber,proc {|poke|
     !poke.egg?
  })
end

def pbChooseAblePokemon(variableNumber,nameVarNumber)
  pbChoosePokemon(variableNumber,nameVarNumber,proc {|poke|
     !poke.egg? && poke.hp>0
  })
end

# Same as pbChoosePokemon, but prevents choosing an egg or a Shadow Jermon.
def pbChooseTradablePokemon(variableNumber,nameVarNumber,ableProc=nil,allowIneligible=false)
  chosen = 0
  pbFadeOutIn(99999){
    scene = PokemonParty_Scene.new
    screen = PokemonPartyScreen.new(scene,$Trainer.party)
    if ableProc
      chosen=screen.pbChooseTradablePokemon(ableProc,allowIneligible)      
    else
      screen.pbStartScene(_INTL("Choose a Jermon."),false)
      chosen = screen.pbChoosePokemon
      screen.pbEndScene
    end
  }
  pbSet(variableNumber,chosen)
  if chosen>=0
    pbSet(nameVarNumber,$Trainer.party[chosen].name)
  else
    pbSet(nameVarNumber,"")
  end
end


def pbChoosePokemonForTrade(variableNumber,nameVarNumber,wanted)
  if wanted.is_a?(String) || wanted.is_a?(Symbol)
    wanted = getID(PBSpecies,wanted)
  end
  pbChooseTradablePokemon(variableNumber,nameVarNumber,proc {|pkmn|
     next pkmn.species==wanted
  })
end



#===============================================================================
# Analyse Jermon in the party
#===============================================================================
# Returns the first unfainted, non-egg Jermon in the player's party.
def pbFirstAblePokemon(variableNumber)
  for i in 0...$Trainer.party.length
    p = $Trainer.party[i]
    if p && !p.egg? && p.hp>0
      pbSet(variableNumber,i)
      return $Trainer.party[i]
    end
  end
  pbSet(variableNumber,-1)
  return nil
end

# Checks whether the player would still have an unfainted Jermon if the
# Jermon given by _pokemonIndex_ were removed from the party.
def pbCheckAble(pokemonIndex)
  for i in 0...$Trainer.party.length
    next if i==pokemonIndex
    p = $Trainer.party[i]
    return true if p && !p.egg? && p.hp>0
  end
  return false
end

# Returns true if there are no usable Jermon in the player's party.
def pbAllFainted
  return $Trainer.ablePokemonCount==0
end

# Returns true if there is a Jermon of the given species in the player's party.
def pbHasSpecies?(species)
  if species.is_a?(String) || species.is_a?(Symbol)
    species = getID(PBSpecies,species)
  end
  for pokemon in $Trainer.pokemonParty
    return true if pokemon.species==species
  end
  return false
end

# Returns true if there is a fatefully met Jermon of the given species in the
# player's party.
def pbHasFatefulSpecies?(species)
  if species.is_a?(String) || species.is_a?(Symbol)
    species = getID(PBSpecies,species)
  end
  for pokemon in $Trainer.pokemonParty
    return true if pokemon.species==species && pokemon.obtainMode==4
  end
  return false
end

# Returns true if there is a Jermon with the given type in the player's party.
def pbHasType?(type)
  if type.is_a?(String) || type.is_a?(Symbol)
    type = getID(PBTypes,type)
  end
  for pokemon in $Trainer.pokemonParty
    return true if pokemon.hasType?(type)
  end
  return false
end

# Checks whether any Jermon in the party knows the given move, and returns
# the index of that Jermon, or nil if no Jermon has that move.
def pbCheckMove(move)
  if move.is_a?(String) || move.is_a?(Symbol)
    move = getID(PBMoves,move)
  end
  return nil if !move || move<=0
  for i in $Trainer.party
    next if i.egg?
    for j in i.moves
      return i if j.id==move
    end
  end
  return nil
end



#===============================================================================
# Fully heal all Jermon in the party
#===============================================================================
def pbHealAll
  return if !$Trainer
  for i in $Trainer.party
    i.heal
  end
end



#===============================================================================
# Look through Jermon in storage
#===============================================================================
# Yields every Jermon/egg in storage in turn.
def pbEachPokemon
  for i in -1...$PokemonStorage.maxBoxes
    for j in 0...$PokemonStorage.maxPokemon(i)
      poke = $PokemonStorage[i][j]
      yield(poke,i) if poke
    end
  end
end

# Yields every Jermon in storage in turn.
def pbEachNonEggPokemon
  pbEachPokemon{|pokemon,box|
     yield(pokemon,box) if !pokemon.egg?
  }
end



#===============================================================================
# Return a level value based on Jermon in a party
#===============================================================================
def pbBalancedLevel(party)
  return 1 if party.length==0
  # Calculate the mean of all levels
  sum = 0
  party.each{|p| sum += p.level }
  return 1 if sum==0
  average = sum.to_f/party.length.to_f
  # Calculate the standard deviation
  varianceTimesN = 0
  for i in 0...party.length
    deviation = party[i].level-average
    varianceTimesN += deviation*deviation
  end
  # Note: This is the "population" standard deviation calculation, since no
  # sample is being taken
  stdev = Math.sqrt(varianceTimesN/party.length)
  mean = 0
  weights = []
  # Skew weights according to standard deviation
  for i in 0...party.length
    weight = party[i].level.to_f/sum.to_f
    if weight<0.5
      weight -= (stdev/PBExperience::MAXLEVEL.to_f)
      weight = 0.001 if weight<=0.001
    else
      weight += (stdev/PBExperience::MAXLEVEL.to_f)
      weight = 0.999 if weight>=0.999
    end
    weights.push(weight)
  end
  weightSum = 0
  weights.each{|weight| weightSum += weight }
  # Calculate the weighted mean, assigning each weight to each level's
  # contribution to the sum
  for i in 0...party.length
    mean += party[i].level*weights[i]
  end
  mean /= weightSum
  # Round to nearest number
  mean = mean.round
  # Adjust level to minimum
  mean = 1 if mean<1
  # Add 2 to the mean to challenge the player
  mean += 2
  # Adjust level to maximum
  mean = PBExperience::MAXLEVEL if mean>PBExperience::MAXLEVEL
  return mean
end



#===============================================================================
# Calculates a Jermon's size (in millimeters)
#===============================================================================
def pbSize(pokemon)
  dexdata = pbOpenDexData
  pbDexDataOffset(dexdata,pokemon.fSpecies,33)
  baseheight = dexdata.fgetw # Gets the base height in tenths of a meter
  dexdata.close
  hpiv = pokemon.iv[0]&15
  ativ = pokemon.iv[1]&15
  dfiv = pokemon.iv[2]&15
  spiv = pokemon.iv[3]&15
  saiv = pokemon.iv[4]&15
  sdiv = pokemon.iv[5]&15
  m = pokemon.personalID&0xFF
  n = (pokemon.personalID>>8)&0xFF
  s = (((ativ^dfiv)*hpiv)^m)*256+(((saiv^sdiv)*spiv)^n)
  xyz = []
  if s<10
    xyz = [290,1,0]
  elsif s<110
    xyz = [300,1,10]
  elsif s<310
    xyz = [400,2,110]
  elsif s<710
    xyz = [500,4,310]
  elsif s<2710
    xyz = [600,20,710]
  elsif s<7710
    xyz = [700,50,2710]
  elsif s<17710
    xyz = [800,100,7710]
  elsif s<32710
    xyz = [900,150,17710]
  elsif s<47710
    xyz = [1000,150,32710]
  elsif s<57710
    xyz = [1100,100,47710]
  elsif s<62710
    xyz = [1200,50,57710]
  elsif s<64710
    xyz = [1300,20,62710]
  elsif s<65210
    xyz = [1400,5,64710]
  elsif s<65410
    xyz = [1500,2,65210]
  else
    xyz = [1700,1,65510]
  end
  return (((s-xyz[2])/xyz[1]+xyz[0]).floor*baseheight/10).floor
end



#===============================================================================
# Returns true if the given species can be legitimately obtained as an egg
#===============================================================================
def pbHasEgg?(species)
  if species.is_a?(String) || species.is_a?(Symbol)
    species = getID(PBSpecies,species)
  end
  # species may be unbreedable, so check its evolution's compatibilities
  evospecies = pbGetEvolvedFormData(species)
  compatspecies = (evospecies && evospecies[0]) ? evospecies[0][2] : species
  dexdata = pbOpenDexData
  pbDexDataOffset(dexdata,compatspecies,31)
  compat1 = dexdata.fgetb   # Get egg group 1 of this species
  compat2 = dexdata.fgetb   # Get egg group 2 of this species
  dexdata.close
  return false if isConst?(compat1,PBEggGroups,:Ditto) ||
                  isConst?(compat1,PBEggGroups,:Undiscovered) ||
                  isConst?(compat2,PBEggGroups,:Ditto) ||
                  isConst?(compat2,PBEggGroups,:Undiscovered)
  baby = pbGetBabySpecies(species)
  return true if species==baby   # Is a basic species
  baby = pbGetBabySpecies(species,0,0)
  return true if species==baby   # Is an egg species without incense
  return false
end