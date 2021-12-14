local scene = {}

--variable
local debug = false
local size = 10
local box_size = 32
local gap = 0
local box_width = box_size - gap
local start_at = 0
local board = {}
local bomb_count = 0
local flagged_count = 0
local revealed_count = 0
local playing = false

local screen_width = 0
local screen_height = 0
local left_origin = 0
local top_origin = 100
local playable_width = 300
local playable_height = 600
local center_x_board = 0
local center_y_board = 0
local center_x_playable = 0
local center_y_playable = 0

local start_drag_x = 0
local start_drag_y = 0
local dragged_x = 0
local dragged_y = 0

local last_click = 0

local clicked = false
local dragging = false


-- ui
local board_canvas
local font
local logo
local timer_text
local revealed_count_text
local bomb_count_text
local win_text
local normal_box
local revealed_box
local bomb_box
local flagged_box
local explode_box
local number_box = {}

function disp_time(time)
    local days = math.floor(time/86400)
    local hours = math.floor(math.mod(time, 86400)/3600)
    local minutes = math.floor(math.mod(time,3600)/60)
    local seconds = math.floor(math.mod(time,60))
    return string.format("%d:%02d:%02d:%02d",days,hours,minutes,seconds)
end

function isOutOfBound(x, y)
    return x < 1 or x > size or y < 1 or y > size
end

function isBomb(x, y)
    if isOutOfBound(x, y) then
        return false
    end
    return board[y][x].bomb
end

function getPostition(n)
    y = math.ceil(n / size)
    x = n - (y - 1) * size
    return {
        x = x,
        y = y
    }
end

function getNeighbors(x, y)
    local count = 0
    -- top
    if isBomb(x - 1, y - 1) then
        -- print("topleft is bomb " .. x .. " " .. y)
        count = count + 1
    end
    if isBomb(x, y - 1) then
        count = count + 1
    end
    if isBomb(x + 1, y - 1) then
        count = count + 1
    end
    -- current
    if isBomb(x - 1, y) then
        count = count + 1
    end
    if isBomb(x, y) then
        count = count + 1
    end
    if isBomb(x + 1, y) then
        count = count + 1
    end
    -- below
    if isBomb(x - 1, y + 1) then
        count = count + 1
    end
    if isBomb(x, y + 1) then
        count = count + 1
    end
    if isBomb(x + 1, y + 1) then
        count = count + 1
    end
    return count
end

function reveal(x, y)
    if isOutOfBound(x, y) then
        return
    end
    local box = board[y][x];
    if box.revealed then
        return
    end
    if box.flagged then
        return
    end
    if box.value > 0 then
        board[y][x].revealed = true
        revealed_count = revealed_count + 1
    end
    if box.value == 0 then
        board[y][x].revealed = true
        revealed_count = revealed_count + 1
        -- clear neighbors
        reveal(x - 1, y - 1)
        reveal(x, y - 1)
        reveal(x + 1, y - 1)
        reveal(x - 1, y)
        reveal(x, y)
        reveal(x + 1, y)
        reveal(x - 1, y + 1)
        reveal(x, y + 1)
        reveal(x + 1, y + 1)
    end
end

function revealAll(mx, my)
    for n = 1, size * size do
        local pos = getPostition(n)
        local x = pos.x
        local y = pos.y
        board[pos.y][pos.x].revealed = true
        if y == my and x == mx then
            board[y][x].explode = true
        end
    end
end

function generate_board()
    local y
    local x
    for n = 1, size * size do
        local pos = getPostition(n)
        local x = pos.x
        local y = pos.y
        if board[y] == nil then
            board[y] = {}
        end
        local is_bomb = math.random(1, 5) == 1
        board[y][x] = {
            bomb = is_bomb,
            revealed = false,
            value = 0,
            flagged = false,
            correct = false,
            explode = false,
            x = x,
            y = y,
            pos_x = (x - 1) * box_size,
            pos_y = (y - 1) * box_size,
            text = love.graphics.newText(font, "0")
        }
    end
    for n = 1, size * size do
        local pos = getPostition(n)
        local x = pos.x
        local y = pos.y
        board[y][x].value = getNeighbors(x, y)
        if board[y][x].bomb then
            bomb_count = bomb_count + 1
        end
    end
end

function isWin()
    return (size * size) - bomb_count == revealed_count
end

function start()
    -- 
    start_at = love.timer.getTime()
    playing = true
    generate_board()
end

function stop()
    love = nil
end

function draw_explode()
    
end

function draw_flagged()

end

function draw_box(box)
    local color = { 10/255, 39/255, 64/255, 1 }
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(normal_box, box.pos_x, box.pos_y)
    if not box.flagged then
        if box.explode then
            love.graphics.draw(explode_box, box.pos_x, box.pos_y)
        end
        if box.revealed and not box.explode and not box.bomb then
            if box.value > 0 then
                love.graphics.draw(number_box[box.value], box.pos_x, box.pos_y)
            else
                love.graphics.draw(revealed_box, box.pos_x, box.pos_y)
            end
        end
        if box.bomb and not playing and not box.explode then
            love.graphics.draw(bomb_box, box.pos_x, box.pos_y)
        end
    else
        love.graphics.draw(flagged_box, box.pos_x, box.pos_y)
    end
    if debug then
        love.graphics.setColor(0,0,0,1)
        box.text:set(box.value)
        if box.bomb then
            box.text:set("*")
        end
    else
        box.text:set("")
    end
    love.graphics.draw(box.text, box.pos_x + box_width / 2 - box.text:getWidth() / 2, box.pos_y + box_width / 2 - box.text:getHeight() / 2)
end

function draw_board()
    love.graphics.setCanvas(board_canvas)
    -- love.graphics.setColor(1, 1, 1, 1)
    -- love.graphics.clear()
    -- love.graphics.setColor(1, 0, 0)
    -- love.graphics.rectangle("fill", 0, 0, 10, 10)
    for n = 1, size * size do
        local pos = getPostition(n)
        local x = pos.x
        local y = pos.y
        local box = board[y][x]
        draw_box(box)
    end
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(board_canvas, left_origin, top_origin)
end

function draw_win()
    win_text:set("WIN!!!")
    love.graphics.draw(win_text, center_x_screen - win_text:getWidth() / 2, center_y_screen - win_text:getHeight() / 2)
end

function draw_lose()
    win_text:set("LOSE!!!")
    love.graphics.draw(win_text, center_x_screen - win_text:getWidth() / 2, center_y_screen - win_text:getHeight() / 2)
end

function load_assets()
    normal_box = love.graphics.newImage("assets/normal_box.png")
    revealed_box = love.graphics.newImage("assets/revealed_box.png")
    explode_box = love.graphics.newImage("assets/explode_box.png")
    bomb_box = love.graphics.newImage("assets/bomb_box.png")
    flagged_box = love.graphics.newImage("assets/flagged_box.png")
    for i = 1, 8 do
        number_box[i] = love.graphics.newImage("assets/" .. i .. "_box.png")
    end
end

function setup_screen()
    --
    width, height, flags = love.window.getMode()
    screen_width = width
    screen_height = height
    playable_width = 0.9 * screen_width
    playable_height = 0.9 * screen_height

    box_size = playable_width / size
    box_width = box_size - gap

    print(playable_width .. " box_size " .. box_size .. " box_width " .. box_width)
end

function setup_board()
    board_canvas = love.graphics.newCanvas(box_size * size, box_size * size)
end

function scene.load()
    font_logo = love.graphics.newFont("assets/fonts/Helveglitch.otf", 40)
    font = love.graphics.newFont()
    logo = love.graphics.newText(font_logo, "Sugasweeper")
    timer_text = love.graphics.newText(font, "time: 0")
    bomb_count_text = love.graphics.newText(font, "bombs: 0")
    revealed_count_text = love.graphics.newText(font, "revealed: 0")
    win_text = love.graphics.newText(font, "")
    start_at = love.timer.getTime()
    load_assets()
    setup_screen()
    setup_board()
    start()
end

function scenedraw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.clear()
    -- draw logo
    love.graphics.draw(logo, center_x_screen - logo:getWidth() / 2, 20)
    -- draw timer
    love.graphics.draw(timer_text, left_origin, top_origin - 20)

    love.graphics.draw(bomb_count_text, left_origin + board_canvas:getWidth() - bomb_count_text:getWidth() , top_origin - 20)
    -- draw board
    draw_board()
    if not playing then
        if win then
            draw_win()
        else
            draw_lose()
        end
    end
end

function scene.draw()
    scenedraw()
end

function click_box(x, y)
    if not isOutOfBound(x, y) then
        if board[y][x].revealed then
            return
        end
        -- check if bomb
        if board[y][x].bomb then
        --     board[y][x].correct = false
            revealAll(x, y)
            win = false
            playing = false
        else
            reveal(x, y)
            if isWin() then
                win = true
                playing = false
            end
        end
    end
end

function scene.update()
    center_x_screen = screen_width / 2
    center_x_board = playable_width / 2
    center_y_screen = screen_height / 2
    center_y_board = playable_height / 2
    left_origin = center_x_screen - center_x_board
    top_origin = top_origin

    -- update button
    local now_at = love.timer.getTime()
    time = now_at - start_at
    timer_text:set("time: " .. disp_time(time))
    revealed_count_text:set("revealed: " .. revealed_count)
    bomb_count_text:set("bombs: " .. bomb_count - flagged_count)

    function love.keypressed(key)
        if key == "escape" then
            love.event.quit()
        end
        if key == "f" then
            debug = not debug
        end
    end

    function love.mousepressed(x, y, button)
        last_click = love.timer.getTime()
        start_drag_x = x
        start_drag_y = y
        clicked = true
    end

    function love.mousemoved(x, y)
        if clicked then
            dragging = true
            dragged_x = start_drag_x - x
            dragged_y = start_drag_y - y
        else
            dragging = false
            dragged_x = 0
            dragged_y = 0
        end
    end

    function love.mousereleased(mx, my, button, istouch)
        dragging = false
        clicked = false
        dragged_x = 0
        dragged_y = 0
        if button == 1 then
            local x = math.floor((mx - left_origin) / box_size) + 1
            local y = math.floor((my - top_origin) / box_size) + 1
            if love.timer.getTime() - last_click > 1 then
                print('flag')
                if not isOutOfBound(x, y) then
                    if board[y][x].flagged then
                        board[y][x].flagged = false
                        flagged_count = flagged_count - 1
                    else
                        board[y][x].flagged = true
                        flagged_count = flagged_count + 1
                    end
                end
            else
                print('click')
                click_box(x, y)
            end
        end
    end

    function love.touchpressed()
        last_click = love.timer.getTime()
    end

    function love.touchmoved()
        dragging = true
    end

    function love.touchreleased(mx, my, button, istouch)
        if button == 1 then
            local x = math.floor((mx - left_origin) / box_size) + 1
            local y = math.floor((my - top_origin) / box_size) + 1
            if love.timer.getTime() - last_click > 1 then
                print('flag')
                if not isOutOfBound(x, y) then
                    if board[y][x].flagged then
                        board[y][x].flagged = false
                        flagged_count = flagged_count - 1
                    else
                        board[y][x].flagged = true
                        flagged_count = flagged_count + 1
                    end
                end
            else
                print('click')
                click_box(x, y)
            end
        end
    end
end

return scene