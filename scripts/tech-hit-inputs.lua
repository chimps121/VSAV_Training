---@author VMP_MBD (MBDesu)

-- consts
local P1_INPUT_ADDR = 0xff8522
local P1_TECH_HIT_INPUT_COUNT_ADDR = 0xff8570
local TECH_HIT_SUCCESS_CHECK_ADDR = 0x2762a
local INPUT_REPRESENTATIONS = { 'LP', 'MP', 'HP', '', 'LK', 'MK', 'HK' }

-- local state
local last_num_inputs = 0
local tech_hit_input_history = {}

local btst = function(bit_pos, value)
  return bit.band(bit.lshift(1, bit_pos), value) > 0
end

---Converts a raw button input value from memory into
---a text representation of all pressed buttons
---@param raw_input number
---@return string
local parse_input = function(raw_input)
  local pressed_buttons = {}

  for i, representation in pairs(INPUT_REPRESENTATIONS) do
    if btst(i - 1, raw_input) then
      pressed_buttons[#pressed_buttons + 1] = representation
    end
  end
  return table.concat(pressed_buttons, '+')
end

local function get_count()
  return memory.readbyte(P1_TECH_HIT_INPUT_COUNT_ADDR)
end

local function update_tech_hit_input_history(did_tech_hit)
  local current_num_inputs = get_count()
  if last_num_inputs > current_num_inputs then
    tech_hit_input_history = {}
  end
  if last_num_inputs ~= current_num_inputs then
    last_num_inputs = current_num_inputs
    local history_entry =
          {current_num_inputs, parse_input(memory.readbyte(P1_INPUT_ADDR))}
    if did_tech_hit == true then
      history_entry[3] = 'TECH HIT'
    end
    tech_hit_input_history[#tech_hit_input_history + 1] = history_entry
  end
end

memory.registerexec(TECH_HIT_SUCCESS_CHECK_ADDR, function()
  -- Z flag will contain indication of success; second bit of SR register
  -- additionally, we only reach 0x2762a on successful tech hit input
  local did_tech_hit = not btst(2, memory.getregister('m68000.sr'))
  update_tech_hit_input_history(did_tech_hit)
end)

local guiRegister = function()
  for i, entry in pairs(tech_hit_input_history) do
    if #entry < 3 then
      gui.text(5, emu.screenheight() - 160 + 10 * i, entry[1] .. ': ' .. entry[2])
    else
      gui.text(5, emu.screenheight() - 160 + 10 * i, entry[1] .. ': ' .. entry[2] .. '     ' .. entry[3])
    end
  end
end

return guiRegister