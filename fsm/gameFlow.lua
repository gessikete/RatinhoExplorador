local fsm = require "com.fsm.src.fsm"

local M = { }

function M.new( miniGameFSM, listeners , miniGame ) 
  function M.updateFSM( event, alternativeEvent )
    if ( miniGameFSM ) then 
      local nextEvent

      if ( alternativeEvent ) then nextEvent = alternativeEvent else nextEvent = miniGameFSM.nextEvent end
      if ( nextEvent == "showAnimation" ) then 
        miniGameFSM.showAnimation()

      elseif ( nextEvent == "showMessage" ) then 
        miniGameFSM.showMessage()

      elseif ( nextEvent == "showObligatoryMessage" ) then 
        miniGameFSM.showObligatoryMessage()
      
      elseif ( nextEvent == "showMessageAndAnimation" ) then 
        miniGameFSM.showMessageAndAnimation()
      
      elseif ( nextEvent == "transitionEvent" ) then 
        miniGameFSM.transitionEvent()

      elseif ( nextEvent == "saveGame" ) then
        miniGameFSM.saveGame()

      elseif ( nextEvent == "showFeedback" ) then
        miniGameFSM.showFeedback()

      elseif ( nextEvent == "nextTutorial" ) then
        miniGameFSM.nextTutorial()

      elseif ( nextEvent == "endTutorial" ) then
        miniGameFSM.endTutorial()

      elseif ( nextEvent == "repeatLevel" ) then 
        miniGameFSM.repeatLevel()
        
      elseif ( nextEvent == "enableListeners" ) then 
        miniGameFSM.enableListeners()

      elseif ( nextEvent == "showGamePanel" ) then 
        miniGameFSM.showGamePanel()

      elseif ( nextEvent == "checkFeedbackWait" ) then
        miniGameFSM.checkFeedbackWait()

      elseif ( nextEvent == "finishLevel" ) then
        miniGameFSM.finishLevel()

      elseif ( nextEvent == "checkProgress" ) then
        miniGameFSM.checkProgress()
        
      elseif ( nextEvent == "nextRecipe" ) then
        miniGameFSM.nextRecipe()
         
      end

    end
  end

  local function showSubText( event )
    messageBubble = event.target
    miniGameFSM.messageBubble = messageBubble

    if ( messageBubble.message[messageBubble.shownText] ) then 
      messageBubble.text:removeSelf()
      messageBubble.options.text = messageBubble.message[messageBubble.shownText]

      local newText = display.newText( messageBubble.options ) 
      newText.x = newText.x + newText.width/2
      newText.y = newText.y + newText.height/2
      if ( messageBubble.options.color ) then 
        newText:setFillColor( messageBubble.options.color[1], messageBubble.options.color[2], messageBubble.options.color[3] )
      end

      messageBubble.text = newText
      messageBubble.shownText = messageBubble.shownText + 1

      if ( not messageBubble.message[ messageBubble.shownText ] ) then
          if ( messageBubble.blinkingDart ) then 
            transition.cancel( messageBubble.blinkingDart )
            messageBubble.blinkingDart.alpha = 0
            messageBubble.blinkingDart = nil
          end
      end

    else
      if ( miniGameFSM.event == "showObligatoryMessage" ) then
        transition.fadeOut( messageBubble.text, { time = 400 } )
        transition.fadeOut( messageBubble, { time = 400, onComplete = M.updateFSM } )
        messageBubble.text:removeSelf()
        messageBubble.text = nil
        messageBubble.listener = false
        listeners:remove( messageBubble, "tap", showSubText )
      else
        if ( messageBubble.text ) then
          transition.fadeOut( messageBubble.text, { time = 400 } )
          transition.fadeOut( messageBubble, { time = 400 } )
          messageBubble.text:removeSelf()
          messageBubble.text = nil
          messageBubble.listener = false
          listeners:remove( messageBubble, "tap", showSubText )
        end
      end
    end

    return true
  end

  local function showMessageAgain( event )
    local target = event.target

    if ( ( messageBubble ) and ( messageBubble.myName == target.bubble ) and ( not target.animation ) ) then 
      M.showText( messageBubble, messageBubble.message, target )
    end
  end

  function M.showText( bubble, message, bubbleChar ) 
    local options = {
        text = " ",
        x = bubble.contentBounds.xMin + 15, 
        y = bubble.contentBounds.yMin + 10,
        fontSize = 12.5,
        width = bubble.width - 27,
        height = 0,
        align = "left" 
    }
    options.text = message[1]

    if ( bubble.myName == "cookBubble" ) then 
      options.color = { 0.2, 0.2, 0 }
    end

    if ( bubble.text ) then  
      bubble.text:removeSelf()
      bubble.text = nil
    end 

    if ( bubble.alpha == 0 ) then
      transition.fadeIn( bubble, { time = 400 } )
    end

    if ( ( not bubble.listener ) or ( ( bubble.listener ) and ( bubble.listener == false ) ) ) then
      bubble.listener = true
      listeners:add( bubble, "tap", showSubText )
      listeners:add( bubbleChar, "tap", showMessageAgain )
    end 

    local newText = display.newText( options ) 
    newText.x = newText.x + newText.width/2
    newText.y = newText.y + newText.height/2

    bubble.message = message 
    bubble.text = newText
    bubble.shownText = 1
    bubble.options = options

    if ( bubble.options.color ) then 
      newText:setFillColor( bubble.options.color[1], bubble.options.color[2], bubble.options.color[3] )
    end

    local time  
    if ( not bubble.blinkingDart ) then 
      if ( miniGameFSM.event == "showObligatoryMessage" ) then 
        time = 500
        bubble.blinkingDart = miniGame:findObject( "obligatoryBlinkingDart" ) 
      else
        time = 2000
        if ( bubble == miniGame:findObject( "momBubble" ) ) then 
          bubble.blinkingDart = miniGame:findObject( "momBlinkingDart" ) 
        elseif ( bubble == miniGame:findObject( "teacherBubble" ) ) then
          bubble.blinkingDart = miniGame:findObject( "teacherBlinkingDart" ) 
        elseif ( bubble == miniGame:findObject( "cookBubble" ) ) then
          bubble.blinkingDart = miniGame:findObject( "cookBlinkingDart" )
        end
      end
      bubble.blinkingDart.x = bubble.x + 33
      bubble.blinkingDart.y = bubble.y + 12

      bubble.blinkingDart.alpha = 1
      transition.blink( bubble.blinkingDart, { time = time } )
    end

    if ( ( messageBubble ) and ( messageBubble ~= bubble ) ) then
      messageBubble.listener = false 
      messageBubble.showSubText = showSubText

      if ( messageBubble.listener == true ) then
        listeners:remove( messageBubble, "tap", showSubText )
      end

      messageBubble = bubble
      miniGameFSM.messageBubble = messageBubble
    elseif ( not messageBubble ) then 
      messageBubble = bubble
      miniGameFSM.messageBubble = messageBubble
    end
  end
end

return M 