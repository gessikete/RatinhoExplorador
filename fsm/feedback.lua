module(..., package.seeall)

-- -----------------------------------------------------------------------------------
-- Declaração das variáveis
-- -----------------------------------------------------------------------------------
local M = { }

local json = require "json"

local tiled = require "com.ponywolf.ponytiled"

local sceneTransition = require "sceneTransition"

local feedback

local message

local removeListeners

local executeFSM

local function hideFeedback()
  transition.fadeOut( feedback, { time = 700 } )
end

-- -----------------------------------------------------------------------------------
-- Listeners
-- -----------------------------------------------------------------------------------

local function gotoMenu( event )
  removeListeners()
  sceneTransition.gotoMenu()
end

local function goForward( event )
  removeListeners()
  if ( executeFSM ) then 
    hideFeedback()
    timer.performWithDelay( 1500, executeFSM ) 
  end
end

local function repeatLevel( event )
  removeListeners()

  if ( executeFSM ) then 
    executeFSM( _, "repeatLevel" )
    timer.performWithDelay( 400, hideFeedback )
  end
end

local function addListeners( starNumber )
  local menuButton = feedback:findObject( "menu" )
  local forwardButton = feedback:findObject( "forward" )
  local repeatButton = feedback:findObject( "repeat" )

  menuButton:addEventListener( "tap", gotoMenu )
  repeatButton:addEventListener( "tap", repeatLevel )
  if ( starNumber > 0 ) then
    forwardButton:addEventListener( "tap", goForward )
  end 

  removeListeners = function ()
    menuButton:removeEventListener( "tap", gotoMenu )
    repeatButton:removeEventListener( "tap", repeatLevel )
    if ( starNumber > 0 ) then
      forwardButton:removeEventListener( "tap", goForward )
    end 
  end
end

-- -----------------------------------------------------------------------------------
-- Funções referentes ao feedback
-- -----------------------------------------------------------------------------------
local function showFeedback( starNumber, nextStar )
  local star 
  local time = 700

  if (nextStar <= starNumber ) then 
    if ( nextStar == 1 ) then 
      star = feedback:findObject( "star1" )
    elseif ( nextStar == 2 ) then 
      star = feedback:findObject( "star2" )
    elseif ( nextStar == 3 ) then 
      star = feedback:findObject( "star3" )
    end

    local function closure()
      showFeedback( starNumber, nextStar + 1, msg )
    end

    transition.fadeIn( star, { time = time, onComplete = closure } )
  else
    addListeners( starNumber )
    if ( message ) then
      transition.fadeIn( message, { time = time * 3 } )
    end
  end
end

-- Retorna a lista das instruções
function M.showAnimation( miniGame, stars, msg, executeFSM_ )
  local time = 1000
  
  -- Carrega o arquivo tiled
  local feedbackData = json.decodeFile(system.pathForFile("tiled/feedback.json", system.ResourceDirectory))  -- load from json export
  feedback = tiled.new(feedbackData, "tiled")


  executeFSM = executeFSM_
  local miniGameLayer = feedback:findLayer( miniGame )
  for i = 1, miniGameLayer.numChildren do
    if ( ( miniGameLayer[i].stars == stars ) and ( miniGameLayer[i].msg == msg ) ) then
      message = miniGameLayer[i]
    end
  end

  local function showFeedbackClosure()
    showFeedback( stars, 1 )
  end
  
  transition.fadeIn( feedback:findObject( "background" ), { time = time } )
  if ( stars == 0 ) then 
    local repeatButton = feedback:findObject( "repeat" )
    local forwardButton = feedback:findObject( "forward" )
    
    repeatButton.x = forwardButton.x 
    repeatButton.y = forwardButton.y 
    forwardButton.alpha = 0
  end
  timer.performWithDelay( time, showFeedbackClosure )

  return feedback
end 

return M