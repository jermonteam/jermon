def pbDefaultMap
  return $game_map.map_id if $game_map
  return $data_system.edit_map_id if $data_system
  return 0
end

def pbWarpToMap
  mapid = pbListScreen(_INTL("WARP TO MAP"),MapLister.new(pbDefaultMap))
  if mapid>0
    map = Game_Map.new
    map.setup(mapid)
    success = false
    x = 0
    y = 0
    100.times do
      x = rand(map.width)
      y = rand(map.height)
      next if !map.passableStrict?(x,y,$game_player)
      blocked = false
      for event in map.events.values
        if event.x==x && event.y==y && !event.through
          blocked = true if self!=$game_player || event.character_name!=""
        end
      end
      next if blocked
      success = true
      break
    end
    if !success
      x = rand(map.width)
      y = rand(map.height)
    end
    return [mapid,x,y]
  end
  return nil
end



class SpriteWindow_DebugVariables < Window_DrawableCommand
  attr_reader :mode

  def initialize(viewport)
    super(0,0,Graphics.width,Graphics.height,viewport)
  end

  def itemCount
    return (@mode==0) ? $data_system.switches.size-1 : $data_system.variables.size-1
  end

  def mode=(mode)
    @mode = mode
    refresh
  end

  def shadowtext(x,y,w,h,t,align=0,colors=0)
    width = self.contents.text_size(t).width
    if align==1 # Right aligned
      x += (w-width)
    elsif align==2 # Centre aligned
      x += (w/2)-(width/2)
    end
    base = Color.new(12*8,12*8,12*8)
    if colors==1 # Red
      base = Color.new(168,48,56)
    elsif colors==2 # Green
      base = Color.new(0,144,0)
    end
    pbDrawShadowText(self.contents,x,y,[width,w].max,h,t,base,Color.new(26*8,26*8,25*8))
  end

  def drawItem(index,count,rect)
    pbSetNarrowFont(self.contents)
    colors = 0; codeswitch = false
    if @mode==0
      name = $data_system.switches[index+1]
      codeswitch = (name[/^s\:/])
      val = (codeswitch) ? (eval($~.post_match) rescue nil) : $game_switches[index+1]
      if val==nil; status = "[-]"; colors = 0; codeswitch = true
      elsif val; status = "[ON]"; colors = 2
      else; status = "[OFF]"; colors = 1
      end
    else
      name = $data_system.variables[index+1]
      status = $game_variables[index+1].to_s
      status = "\"__\"" if !status || status==""
    end
    name = '' if name==nil
    id_text = sprintf("%04d:",index+1)
    width = self.contents.text_size(id_text).width
    rect = drawCursor(index,rect)
    totalWidth = rect.width
    idWidth     = totalWidth*15/100
    nameWidth   = totalWidth*65/100
    statusWidth = totalWidth*20/100
    self.shadowtext(rect.x,rect.y,idWidth,rect.height,id_text)
    self.shadowtext(rect.x+idWidth,rect.y,nameWidth,rect.height,name,0,(codeswitch) ? 1 : 0)
    self.shadowtext(rect.x+idWidth+nameWidth,rect.y,statusWidth,rect.height,status,1,colors)
  end
end



def pbDebugSetVariable(id,diff)
  $game_variables[id] = 0 if $game_variables[id]==nil
  if $game_variables[id].is_a?(Numeric)
    pbPlayCursorSE
    $game_variables[id] = [$game_variables[id]+diff,99999999].min
    $game_variables[id] = [$game_variables[id],-99999999].max
  end
end

def pbDebugVariableScreen(id)
  if $game_variables[id].is_a?(Numeric)
    value = $game_variables[id]
    params = ChooseNumberParams.new
    params.setDefaultValue(value)
    params.setMaxDigits(8)
    params.setNegativesAllowed(true)
    value = Kernel.pbMessageChooseNumber(_INTL("Set variable {1}.",id),params)
    $game_variables[id] = [value,99999999].min
    $game_variables[id] = [$game_variables[id],-99999999].max
  elsif $game_variables[id].is_a?(String)
    value = Kernel.pbMessageFreeText(_INTL("Set variable {1}.",id),
       $game_variables[id],false,256,Graphics.width)
    $game_variables[id] = value
  end
end

def pbDebugVariables(mode)
  viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
  viewport.z = 99999
  sprites = {}
  sprites["right_window"] = SpriteWindow_DebugVariables.new(viewport)
  right_window = sprites["right_window"]
  right_window.mode     = mode
  right_window.active   = true
  loop do
    Graphics.update
    Input.update
    pbUpdateSpriteHash(sprites)
    if Input.trigger?(Input::B)
      pbPlayCancelSE
      break
    end
    current_id = right_window.index+1
    if mode==0 # Switches
      if Input.trigger?(Input::C)
        pbPlayDecisionSE
        $game_switches[current_id] = !$game_switches[current_id]
        right_window.refresh
      end
    elsif mode==1 # Variables
      if Input.repeat?(Input::LEFT)
        pbDebugSetVariable(current_id,-1)
        right_window.refresh
      elsif Input.repeat?(Input::RIGHT)
        pbDebugSetVariable(current_id,1)
        right_window.refresh
      elsif Input.trigger?(Input::A)
        if $game_variables[current_id]==0
          $game_variables[current_id] = ""
        elsif $game_variables[current_id]==""
          $game_variables[current_id] = 0
        elsif $game_variables[current_id].is_a?(Numeric)
          $game_variables[current_id] = 0
        elsif $game_variables[current_id].is_a?(String)
          $game_variables[current_id] = ""
        end
        right_window.refresh
      elsif Input.trigger?(Input::C)
        pbPlayDecisionSE
        pbDebugVariableScreen(current_id)
        right_window.refresh
      end
    end
  end
  pbDisposeSpriteHash(sprites)
  viewport.dispose
end

def pbDebugDayCare
  commands = [_INTL("Withdraw Jermon 1"),
              _INTL("Withdraw Jermon 2"),
              _INTL("Deposit Jermon"),
              _INTL("Generate egg"),
              _INTL("Collect egg")]
  viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
  viewport.z = 99999
  sprites = {}
  addBackgroundPlane(sprites,"background","hatchbg",viewport)
  sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,viewport)
  pbSetSystemFont(sprites["overlay"].bitmap)
  sprites["cmdwindow"] = Window_CommandPokemonEx.new(commands)
  cmdwindow = sprites["cmdwindow"]
  cmdwindow.x        = 0
  cmdwindow.y        = Graphics.height-128
  cmdwindow.width    = Graphics.width
  cmdwindow.height   = 128
  cmdwindow.viewport = viewport
  cmdwindow.columns = 2
  base   = Color.new(248,248,248)
  shadow = Color.new(104,104,104)
  refresh = true
  loop do
    if refresh
      if pbEggGenerated?
        commands[3] = _INTL("Discard egg")
      else
        commands[3] = _INTL("Generate egg")
      end
      cmdwindow.commands = commands
      sprites["overlay"].bitmap.clear
      textpos = []
      for i in 0...2
        textpos.push([_INTL("Jermon {1}",i+1),Graphics.width/4+i*Graphics.width/2,8,2,base,shadow])
      end
      for i in 0...pbDayCareDeposited
        next if !$PokemonGlobal.daycare[i][0]
        y = 40
        pkmn      = $PokemonGlobal.daycare[i][0]
        initlevel = $PokemonGlobal.daycare[i][1]
        leveldiff = pkmn.level-initlevel
        textpos.push([pkmn.name+" ("+PBSpecies.getName(pkmn.species)+")",8+i*Graphics.width/2,y,0,base,shadow])
        y += 32
        if pkmn.isMale?
          textpos.push([_INTL("Male ♂"),8+i*Graphics.width/2,y,0,Color.new(128,192,248),shadow])
        elsif pkmn.isFemale?
          textpos.push([_INTL("Female ♀"),8+i*Graphics.width/2,y,0,Color.new(248,96,96),shadow])
        else
          textpos.push([_INTL("Genderless"),8+i*Graphics.width/2,y,0,base,shadow])
        end
        y += 32
        if initlevel>=PBExperience::MAXLEVEL
          textpos.push(["Lv. #{initlevel} (max)",8+i*Graphics.width/2,y,0,base,shadow])
        elsif leveldiff>0
          textpos.push(["Lv. #{initlevel} -> #{pkmn.level} (+#{leveldiff})",
             8+i*Graphics.width/2,y,0,base,shadow])
        else
          textpos.push(["Lv. #{initlevel} (no change)",8+i*Graphics.width/2,y,0,base,shadow])
        end
        y += 32
        if pkmn.level<PBExperience::MAXLEVEL
          endexp   = PBExperience.pbGetStartExperience(pkmn.level+1,pkmn.growthrate)
          textpos.push(["To next Lv.: #{endexp-pkmn.exp}",8+i*Graphics.width/2,y,0,base,shadow])
          y += 32
        end
        textpos.push(["Cost: $#{pbDayCareCost(i)}",8+i*Graphics.width/2,y,0,base,shadow])
      end
      if pbEggGenerated?
        textpos.push(["Egg waiting for collection",Graphics.width/2,216,2,Color.new(248,248,0),shadow])
      elsif pbDayCareDeposited==2
        if pbDayCareGetCompat==0
          textpos.push(["Jermon cannot breed",Graphics.width/2,216,2,Color.new(248,96,96),shadow])
        else
          textpos.push(["Jermon can breed",Graphics.width/2,216,2,Color.new(64,248,64),shadow])
        end
      end
      pbDrawTextPositions(sprites["overlay"].bitmap,textpos)
      refresh = false
    end
    pbUpdateSpriteHash(sprites)
    Graphics.update
    Input.update
    if Input.trigger?(Input::B)
      break
    elsif Input.trigger?(Input::C)
      ret = cmdwindow.index
      case cmdwindow.index
      when 0 # Withdraw Jermon 1
        if !$PokemonGlobal.daycare[0][0]
          pbPlayBuzzerSE
        elsif $Trainer.party.length>=6
          pbPlayBuzzerSE
          Kernel.pbMessage(_INTL("Party is full, can't withdraw Jermon."))
        else
          pbPlayDecisionSE
          pbDayCareGetDeposited(0,3,4)
          pbDayCareWithdraw(0)
          refresh = true
        end
      when 1 # Withdraw Jermon 2
        if !$PokemonGlobal.daycare[1][0]
          pbPlayBuzzerSE
        elsif $Trainer.party.length>=6
          pbPlayBuzzerSE
          Kernel.pbMessage(_INTL("Party is full, can't withdraw Jermon."))
        else
          pbPlayDecisionSE
          pbDayCareGetDeposited(1,3,4)
          pbDayCareWithdraw(1)
          refresh = true
        end
      when 2 # Deposit Jermon
        if pbDayCareDeposited==2
          pbPlayBuzzerSE
        elsif $Trainer.party.length==0
          pbPlayBuzzerSE
          Kernel.pbMessage(_INTL("Party is empty, can't deposit Jermon."))
        else
          pbPlayDecisionSE
          pbChooseNonEggPokemon(1,3)
          if pbGet(1)>=0
            pbDayCareDeposit(pbGet(1))
            refresh = true
          end
        end
      when 3 # Generate/discard egg
        if pbEggGenerated?
          pbPlayDecisionSE
          $PokemonGlobal.daycareEgg      = 0
          $PokemonGlobal.daycareEggSteps = 0
          refresh = true
        else
          if pbDayCareDeposited!=2 || pbDayCareGetCompat==0
            pbPlayBuzzerSE
          else
            pbPlayDecisionSE
            $PokemonGlobal.daycareEgg = 1
            refresh = true
          end
        end
      when 4 # Collect egg
        if $PokemonGlobal.daycareEgg!=1
          pbPlayBuzzerSE
        elsif $Trainer.party.length>=6
          pbPlayBuzzerSE
          Kernel.pbMessage(_INTL("Party is full, can't collect the egg."))
        else
          pbPlayDecisionSE
          pbDayCareGenerateEgg
          $PokemonGlobal.daycareEgg      = 0
          $PokemonGlobal.daycareEggSteps = 0
          Kernel.pbMessage(_INTL("Collected the {1} egg.",
             PBSpecies.getName($Trainer.lastParty.species)))
          refresh = true
        end
      end
    end
  end
  pbDisposeSpriteHash(sprites)
  viewport.dispose
end



class SpriteWindow_DebugRoamers < Window_DrawableCommand
  def initialize(viewport)
    super(0,0,Graphics.width,Graphics.height,viewport)
  end

  def roamerCount
    return RoamingSpecies.length
  end

  def itemCount
    return self.roamerCount+2
  end

  def shadowtext(t,x,y,w,h,align=0,colors=0)
    width = self.contents.text_size(t).width
    if align==1 # Right aligned
      x += (w-width)
    elsif align==2 # Centre aligned
      x += (w/2)-(width/2)
    end
    base = Color.new(12*8,12*8,12*8)
    if colors==1 # Red
      base = Color.new(168,48,56)
    elsif colors==2 # Green
      base = Color.new(0,144,0)
    end
    pbDrawShadowText(self.contents,x,y,[width,w].max,h,t,base,Color.new(26*8,26*8,25*8))
  end

  def drawItem(index,count,rect)
    pbSetNarrowFont(self.contents)
    rect = drawCursor(index,rect)
    nameWidth   = rect.width*50/100
    statusWidth = rect.width*50/100
    if index==self.itemCount-2
      # Advance roaming
      self.shadowtext(_INTL("[All roam to new locations]"),rect.x,rect.y,nameWidth,rect.height)
    elsif index==self.itemCount-1
      # Advance roaming
      self.shadowtext(_INTL("[Clear all current roamer locations]"),rect.x,rect.y,nameWidth,rect.height)
    else
      pkmn = RoamingSpecies[index]
      name = PBSpecies.getName(getID(PBSpecies,pkmn[0]))+" (Lv. #{pkmn[1]})"
      status = ""
      statuscolor = 0
      if $game_switches[pkmn[2]]
        status = $PokemonGlobal.roamPokemon[index]
        if status==true
          if $PokemonGlobal.roamPokemonCaught[index]
            status = "[CAUGHT]"
          else
            status = "[DEFEATED]"
          end
          statuscolor = 1
        else
          # roaming
          curmap = $PokemonGlobal.roamPosition[index]
          if curmap
            mapinfos = ($RPGVX) ? load_data("Data/MapInfos.rvdata") : load_data("Data/MapInfos.rxdata")
            status = "[ROAMING][#{curmap}: #{mapinfos[curmap].name}]"
          else
            status = "[ROAMING][map not set]"
          end
          statuscolor = 2
        end
      else
        status = "[NOT ROAMING][Switch #{pkmn[2]} is off]"
      end
      self.shadowtext(name,rect.x,rect.y,nameWidth,rect.height)
      self.shadowtext(status,rect.x+nameWidth,rect.y,statusWidth,rect.height,1,statuscolor)
    end
  end
end



def pbDebugRoamers
  viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
  viewport.z = 99999
  sprites = {}
  sprites["cmdwindow"] = SpriteWindow_DebugRoamers.new(viewport)
  cmdwindow = sprites["cmdwindow"]
  cmdwindow.active   = true
  loop do
    Graphics.update
    Input.update
    pbUpdateSpriteHash(sprites)
    if Input.trigger?(Input::A) && cmdwindow.index<cmdwindow.roamerCount &&
       $game_switches[pkmn[2]] && $PokemonGlobal.roamPokemon[cmdwindow.index]!=true
      pbPlayDecisionSE
      if Input.press?(Input::CTRL)
        if $PokemonGlobal.roamPosition[cmdwindow.index]==pbDefaultMap
          $PokemonGlobal.roamPosition[cmdwindow.index] = nil
        else
          $PokemonGlobal.roamPosition[cmdwindow.index] = pbDefaultMap
        end
        cmdwindow.refresh
      else
        oldmap = $PokemonGlobal.roamPosition[cmdwindow.index]
        pbRoamPokemonOne(cmdwindow.index,true)
        if $PokemonGlobal.roamPosition[cmdwindow.index] == oldmap
          $PokemonGlobal.roamPosition[cmdwindow.index] = nil
          pbRoamPokemonOne(cmdwindow.index,true)
        end
        $PokemonGlobal.roamedAlready = false
        cmdwindow.refresh
      end
    elsif Input.trigger?(Input::B)
      pbPlayCancelSE
      break
    elsif Input.trigger?(Input::C)
      if cmdwindow.index<cmdwindow.roamerCount
        pbPlayDecisionSE
        # Toggle through roaming, not roaming, defeated
        pkmn = RoamingSpecies[cmdwindow.index]
        if !$game_switches[pkmn[2]]
          # not roaming -> roaming
          $game_switches[pkmn[2]] = true
        elsif $PokemonGlobal.roamPokemon[cmdwindow.index]!=true
          # roaming -> defeated
          $PokemonGlobal.roamPokemon[cmdwindow.index] = true
          $PokemonGlobal.roamPokemonCaught[cmdwindow.index] = false
        elsif $PokemonGlobal.roamPokemon[cmdwindow.index] == true &&
           !$PokemonGlobal.roamPokemonCaught[cmdwindow.index]
          # defeated -> caught
          $PokemonGlobal.roamPokemonCaught[cmdwindow.index] = true
        else
          # caught -> not roaming
          $game_switches[pkmn[2]] = false
          $PokemonGlobal.roamPokemon[cmdwindow.index] = nil
          $PokemonGlobal.roamPokemonCaught[cmdwindow.index] = false
        end
        cmdwindow.refresh
      elsif cmdwindow.index==cmdwindow.itemCount-2
        if RoamingSpecies.length==0
          pbPlayBuzzerSE
        else
          pbPlayDecisionSE
          pbRoamPokemon(true)
          $PokemonGlobal.roamedAlready = false
          cmdwindow.refresh
        end
      else
        if RoamingSpecies.length==0
          pbPlayBuzzerSE
        else
          pbPlayDecisionSE
          for i in 0...RoamingSpecies.length
            $PokemonGlobal.roamPosition[i] = nil
          end
          $PokemonGlobal.roamedAlready = false
          cmdwindow.refresh
        end
      end
    end
  end
  pbDisposeSpriteHash(sprites)
  viewport.dispose
end



# For demonstration purposes only, not to be used in a real game.
def pbCreatePokemon
  party = []
  species = [:PIKACHU,:PIDGEOTTO,:KADABRA,:GYARADOS,:DIGLETT,:CHANSEY]
  for id in species
    party.push(getConst(PBSpecies,id)) if hasConst?(PBSpecies,id)
  end
  # Species IDs of the Jermon to be created
  for i in 0...party.length
    species = party[i]
    # Generate Jermon with species and level 20
    $Trainer.party[i] = PokeBattle_Pokemon.new(species,20,$Trainer)
    $Trainer.seen[species]  = true # Set this species to seen and owned
    $Trainer.owned[species] = true
    pbSeenForm($Trainer.party[i])
  end
  $Trainer.party[1].pbLearnMove(:FLY)
  $Trainer.party[2].pbLearnMove(:FLASH)
  $Trainer.party[2].pbLearnMove(:TELEPORT)
  $Trainer.party[3].pbLearnMove(:SURF)
  $Trainer.party[3].pbLearnMove(:DIVE)
  $Trainer.party[3].pbLearnMove(:WATERFALL)
  $Trainer.party[4].pbLearnMove(:DIG)
  $Trainer.party[4].pbLearnMove(:CUT)
  $Trainer.party[4].pbLearnMove(:HEADBUTT)
  $Trainer.party[4].pbLearnMove(:ROCKSMASH)
  $Trainer.party[5].pbLearnMove(:SOFTBOILED)
  $Trainer.party[5].pbLearnMove(:STRENGTH)
  $Trainer.party[5].pbLearnMove(:SWEETSCENT)
  for i in 0...party.length
    $Trainer.party[i].pbRecordFirstMoves
  end
end




























class PokemonDataCopy
  attr_accessor :dataOldHash
  attr_accessor :dataNewHash
  attr_accessor :dataTime
  attr_accessor :data

  def crc32(x)
    return Zlib::crc32(x)
  end

  def readfile(filename)
    File.open(filename, "rb"){|f|
      f.read
    }
  end

  def writefile(str,filename)
    File.open(filename, "wb"){|f|
      f.write(str)
    }
  end

  def filetime(filename)
    File.open(filename, "r"){|f|
      f.mtime
    }
  end

  def initialize(data,datasave)
    @datafile = data
    @datasave = datasave
    @data = readfile(@datafile)
    @dataOldHash = crc32(@data)
    @dataTime = filetime(@datafile)
  end

  def changed?
    ts     = readfile(@datafile)
    tsDate = filetime(@datafile)
    tsHash = crc32(ts)
    return (tsHash!=@dataNewHash && tsHash!=@dataOldHash && tsDate>@dataTime)
  end

  def save(newtilesets)
    newdata = Marshal.dump(newtilesets)
    if !changed?
      @data = newdata
      @dataNewHash = crc32(newdata)
      writefile(newdata,@datafile)
    else
      @dataOldHash = crc32(@data)
      @dataNewHash = crc32(newdata)
      @dataTime = filetime(@datafile)
      @data = newdata
      writefile(newdata,@datafile)
    end
    save_data(self,@datasave)
  end
end



class PokemonDataWrapper
  attr_reader :data

  def initialize(file,savefile,prompt)
    @savefile = savefile
    @file     = file
    if pbRgssExists?(@savefile)
      @ts = load_data(@savefile)
      if !@ts.changed? || prompt.call==true
        @data = Marshal.load(StringInput.new(@ts.data))
      else
        @ts = PokemonDataCopy.new(@file,@savefile)
        @data = load_data(@file)
      end
    else
      @ts = PokemonDataCopy.new(@file,@savefile)
      @data = load_data(@file)
    end
  end

  def save
    @ts.save(@data)
  end
end



def pbExtractText
  msgwindow = Kernel.pbCreateMessageWindow
  if safeExists?("intl.txt") &&
     !Kernel.pbConfirmMessageSerious(_INTL("intl.txt already exists. Overwrite it?"))
    Kernel.pbDisposeMessageWindow(msgwindow)
    return
  end
  Kernel.pbMessageDisplay(msgwindow,_INTL("Please wait.\\wtnp[0]"))
  MessageTypes.extract("intl.txt")
  Kernel.pbMessageDisplay(msgwindow,_INTL("All text in the game was extracted and saved to intl.txt.\1"))
  Kernel.pbMessageDisplay(msgwindow,_INTL("To localize the text for a particular language, translate every second line in the file.\1"))
  Kernel.pbMessageDisplay(msgwindow,_INTL("After translating, choose \"Compile Text.\""))
  Kernel.pbDisposeMessageWindow(msgwindow)
end

def pbCompileTextUI
  msgwindow=Kernel.pbCreateMessageWindow
  Kernel.pbMessageDisplay(msgwindow,_INTL("Please wait.\\wtnp[0]"))
  begin
    pbCompileText
    Kernel.pbMessageDisplay(msgwindow,_INTL("Successfully compiled text and saved it to intl.dat.\1"))
    Kernel.pbMessageDisplay(msgwindow,_INTL("To use the file in a game, place the file in the Data folder under a different name, and edit the LANGUAGES array in the Settings script."))
  rescue RuntimeError
    Kernel.pbMessageDisplay(msgwindow,_INTL("Failed to compile text:  {1}",$!.message))
  end
  Kernel.pbDisposeMessageWindow(msgwindow)
end

def pbExportAllAnimations
  begin
    Dir.mkdir("Animations") rescue nil
    animations = tryLoadData("Data/PkmnAnimations.rxdata")
    if animations
      msgwindow = Kernel.pbCreateMessageWindow
      for anim in animations
        next if !anim || anim.length==0 || anim.name==""
        Kernel.pbMessageDisplay(msgwindow,anim.name,false)
        Graphics.update
        safename = anim.name.gsub(/\W/,"_")
        Dir.mkdir("Animations/#{safename}") rescue nil
        File.open("Animations/#{safename}/#{safename}.anm","wb"){|f|
          f.write(dumpBase64Anim(anim))
        }
        if anim.graphic && anim.graphic!=""
          graphicname = RTP.getImagePath("Graphics/Animations/"+anim.graphic)
          pbSafeCopyFile(graphicname,"Animations/#{safename}/"+File.basename(graphicname))
        end
        for timing in anim.timing
          if !timing.timingType || timing.timingType==0
            if timing.name && timing.name!=""
              audioName = RTP.getAudioPath("Audio/SE/Anim/"+timing.name)
              pbSafeCopyFile(audioName,"Animations/#{safename}/"+File.basename(audioName))
            end
          elsif timing.timingType==1 || timing.timingType==3
            if timing.name && timing.name!=""
              graphicname = RTP.getImagePath("Graphics/Animations/"+timing.name)
              pbSafeCopyFile(graphicname,"Animations/#{safename}/"+File.basename(graphicname))
            end
          end
        end
      end
      Kernel.pbDisposeMessageWindow(msgwindow)
      Kernel.pbMessage(_INTL("All animations were extracted and saved to the Animations folder."))
    else
      Kernel.pbMessage(_INTL("There are no animations to export."))
    end
  rescue
    p $!.message,$!.backtrace
    Kernel.pbMessage(_INTL("The export failed."))
  end
end

def pbImportAllAnimations
  animationFolders = []
  if safeIsDirectory?("Animations")
    Dir.foreach("Animations"){|fb|
      f = "Animations/"+fb
      if safeIsDirectory?(f) && fb!="." && fb!=".."
        animationFolders.push(f)
      end
    }
  end
  if animationFolders.length==0
    Kernel.pbMessage(_INTL("There are no animations to import. Put each animation in a folder within the Animations folder."))
  else
    msgwindow = Kernel.pbCreateMessageWindow
    animations = tryLoadData("Data/PkmnAnimations.rxdata")
    animations = PBAnimations.new if !animations
    for folder in animationFolders
      Kernel.pbMessageDisplay(msgwindow,folder,false)
      Graphics.update
      audios = []
      files = Dir.glob(folder+"/*.*")
      %w( wav ogg mid wma mp3 ).each{|ext|
        upext = ext.upcase
        audios.concat(files.find_all{|f| f[f.length-3,3]==ext})
        audios.concat(files.find_all{|f| f[f.length-3,3]==upext})
      }
      for audio in audios
        pbSafeCopyFile(audio,RTP.getAudioPath("Audio/SE/Anim/"+File.basename(audio)),"Audio/SE/Anim/"+File.basename(audio))
      end
      images = []
      %w( png jpg bmp gif ).each{|ext|
        upext = ext.upcase
        images.concat(files.find_all{|f| f[f.length-3,3]==ext})
        images.concat(files.find_all{|f| f[f.length-3,3]==upext})
      }
      for image in images
        pbSafeCopyFile(image,RTP.getImagePath("Graphics/Animations/"+File.basename(image)),"Graphics/Animations/"+File.basename(image))
      end
      Dir.glob(folder+"/*.anm"){|f|
        textdata = loadBase64Anim(IO.read(f)) rescue nil
        if textdata && textdata.is_a?(PBAnimation)
          index = pbAllocateAnimation(animations,textdata.name)
          missingFiles = []
          textdata.name = File.basename(folder) if textdata.name==""
          textdata.id = -1 # this is not an RPG Maker XP animation
          pbConvertAnimToNewFormat(textdata)
          if textdata.graphic && textdata.graphic!=""
            if !safeExists?(folder+"/"+textdata.graphic) &&
               !FileTest.image_exist?("Graphics/Animations/"+textdata.graphic)
              textdata.graphic = ""
              missingFiles.push(textdata.graphic)
            end
          end
          for timing in textdata.timing
            if timing.name && timing.name!=""
              if !safeExists?(folder+"/"+timing.name) &&
                 !FileTest.audio_exist?("Audio/SE/Anim/"+timing.name)
                timing.name = ""
                missingFiles.push(timing.name)
              end
            end
          end
          animations[index] = textdata
        end
      }
    end
    animations.resize(index)
    save_data(animations,"Data/PkmnAnimations.rxdata")
    Kernel.pbDisposeMessageWindow(msgwindow)
    Kernel.pbMessage(_INTL("All animations were imported."))
  end
end