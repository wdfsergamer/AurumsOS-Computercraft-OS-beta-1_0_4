-- Graphs Integration Module for AurumOS 1.0.5
-- Provides charting and visualization capabilities

local graphs = {}

function graphs.createBarChart(data, title, width, height)
    local chart = {
        type = "bar",
        data = data,
        title = title,
        width = width or 40,
        height = height or 10
    }
    return chart
end

function graphs.createLineChart(data, title, width, height)
    local chart = {
        type = "line",
        data = data,
        title = title,
        width = width or 40,
        height = height or 10
    }
    return chart
end

function graphs.draw(chart, x, y)
    x = x or 1
    y = y or 1
    
    if chart.type == "bar" then
        return graphs.drawBar(chart, x, y)
    elseif chart.type == "line" then
        return graphs.drawLine(chart, x, y)
    end
end

function graphs.drawBar(chart, x, y)
    local W, H = term.getSize()
    
    -- Draw title
    term.setCursorPos(x, y)
    term.setTextColor(colors.white)
    term.write(chart.title or "Chart")
    
    -- Find max value
    local maxValue = 0
    for _, value in ipairs(chart.data) do
        if type(value) == "number" and value > maxValue then
            maxValue = value
        end
    end
    
    if maxValue == 0 then maxValue = 1 end
    
    -- Draw bars
    local barWidth = math.floor(chart.width / #chart.data)
    for i, value in ipairs(chart.data) do
        if type(value) == "number" then
            local barHeight = math.floor((value / maxValue) * (chart.height - 2))
            local barX = x + (i - 1) * barWidth
            
            for barY = 1, barHeight do
                term.setCursorPos(barX, y + chart.height - barY)
                term.setTextColor(colors.blue)
                term.write(string.rep(" ", barWidth))
            end
        end
    end
end

function graphs.drawLine(chart, x, y)
    local maxValue = 0
    for _, value in ipairs(chart.data) do
        if type(value) == "number" and value > maxValue then
            maxValue = value
        end
    end
    
    if maxValue == 0 then maxValue = 1 end
    
    -- Draw grid and line
    for i = 1, #chart.data - 1 do
        local x1 = x + i - 1
        local x2 = x + i
        local y1 = y + chart.height - math.floor((chart.data[i] / maxValue) * chart.height)
        local y2 = y + chart.height - math.floor((chart.data[i + 1] / maxValue) * chart.height)
        
        if y1 >= y and y1 <= y + chart.height then
            term.setCursorPos(x1, y1)
            term.setTextColor(colors.cyan)
            term.write("/")
        end
    end
end

return graphs
