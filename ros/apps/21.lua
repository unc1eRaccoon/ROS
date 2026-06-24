local monitor = peripheral.find("monitor")
if not monitor then
    print("Error: Please connect an Advanced (gold) monitor!")
    return
end

monitor.setTextScale(1)
local oldTerm = term.redirect(monitor)
local w, h = term.getSize()

-- Card names for display
local cardNames = {"2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King", "Ace"}
local cardValues = {2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10, 11}

-- Function to get a random card
local function getRandomCard()
    local index = math.random(#cardNames)
    return { name = cardNames[index], value = cardValues[index] }
end

-- Score calculation handling Aces (if bust, Ace value drops from 11 to 1)
local function calculateScore(hand)
    local score = 0
    local aces = 0
    for _, card in ipairs(hand) do
        score = score + card.value
        if card.name == "Ace" then aces = aces + 1 end
    end
    while score > 21 and aces > 0 do
        score = score - 10
        aces = aces - 1
    end
    
    return score
end

-- UI Drawing Function
local function drawTable(playerHand, dealerHand, gameState, message)
    term.setBackgroundColor(colors.green) -- Casino green felt background
    term.clear()
    
    -- Scores
    local pScore = calculateScore(playerHand)
    local dScore = calculateScore(dealerHand)
    
    -- Dealer
    term.setCursorPos(2, 2)
    term.setTextColor(colors.white)
    term.write("Dealer's Cards: ")
    for i, card in ipairs(dealerHand) do
        term.write("[" .. card.name .. "] ")
    end
    if gameState == "player_turn" then
        term.write("[?] (Hidden)")
    else
        term.setCursorPos(2, 3)
        term.write("Dealer's Score: " .. dScore)
    end
    
    -- Player
    term.setCursorPos(2, 6)
    term.write("Your Cards: ")
    for _, card in ipairs(playerHand) do
        term.write("[" .. card.name .. "] ")
    end
    term.setCursorPos(2, 7)
    term.write("Your Score: " .. pScore)
    
    -- Message in the center
    if message then
        term.setCursorPos(math.floor(w/2) - string.len(message)/2 + 1, 10)
        term.setTextColor(colors.yellow)
        term.write(message)
    end
    
    -- Control buttons (drawn only during the player's turn)
    if gameState == "player_turn" then
        -- HIT button
        term.setBackgroundColor(colors.blue)
        term.setTextColor(colors.white)
        term.setCursorPos(5, 12)
        term.write("[ HIT ]")
        
        -- STAND button
        term.setBackgroundColor(colors.red)
        term.setCursorPos(w - 13, 12)
        term.write("[ STAND ]")
    else
        -- Play again button
        term.setBackgroundColor(colors.orange)
        term.setTextColor(colors.white)
        term.setCursorPos(math.floor(w/2) - 5, 12)
        term.write("[ PLAY AGAIN ]")
    end
end

-- Main Game Logic
local function playRound()
    local playerHand = { getRandomCard(), getRandomCard() }
    -- Dealer gets one face-up card at the start
    local dealerHand = { getRandomCard() }
    local gameState = "player_turn"
    local message = "Your turn! Hit or stand?"
    
    -- Blackjack from the deal?
    if calculateScore(playerHand) == 21 then
        gameState = "game_over"
        message = "🎉 Blackjack on the deal! You win! 🎉"
    end
    
    while true do
        drawTable(playerHand, dealerHand, gameState, message)
        
        -- Wait for a monitor touch event
        local event, side, x, y = os.pullEvent("monitor_touch")
        
        if gameState == "player_turn" then
            -- Click on "HIT" button (X coordinates approx 5-11, Y=12)
            if x >= 5 and x <= 11 and y == 12 then
                table.insert(playerHand, getRandomCard())
                local score = calculateScore(playerHand)
                if score > 21 then
                    gameState = "game_over"
                    message = "💥 Bust! You lose. 💥"
                elseif score == 21 then
                    x = w - 13 -- Automatically trigger the "Stand" button
                end
            end
            
            -- Click on "STAND" button (X coordinates approx right edge, Y=12)
            if (x >= w - 13 and x <= w - 5 and y == 12) or (calculateScore(playerHand) == 21 and gameState == "player_turn") then
                gameState = "dealer_turn"
                message = "Dealer is revealing cards..."
                drawTable(playerHand, dealerHand, gameState, message)
                os.sleep(1.5)
                
                -- Dealer's logic: hits until reaching 17 or higher
                while calculateScore(dealerHand) < 17 do
                    table.insert(dealerHand, getRandomCard())
                    drawTable(playerHand, dealerHand, gameState, "Dealer takes a card...")
                    os.sleep(1.5)
                end
                
                local pScore = calculateScore(playerHand)
                local dScore = calculateScore(dealerHand)
                
                gameState = "game_over"
                if dScore > 21 then
                    message = "🎉 Dealer bust! You win! 🎉"
                elseif pScore > dScore then
                    message = "🏆 You win by points! 🏆"
                elseif pScore < dScore then
                    message = "🙁 Dealer wins. Better luck next time!"
                else
                    message = "🤝 It's a tie (Push)!"
                end
            end
            
        elseif gameState == "game_over" then
            -- Click on "PLAY AGAIN" button (Centered, Y=12)
            local btnStart = math.floor(w/2) - 5
            if x >= btnStart and x <= btnStart + 13 and y == 12 then
                break -- Exit the inner round loop to start a new one
            end
        end
    end
end

-- Infinite Game Loop
while true do
    playRound()
end

term.redirect(oldTerm)
