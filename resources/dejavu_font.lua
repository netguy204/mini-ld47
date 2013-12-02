
local function _font(scale)
   scale = scale or 1
   local characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.!?,\'"\\/'
   local font = game:create_object('Font')
   font:load(game:atlas('resources/default'), '', characters)
   font:scale(scale)
   font:line_separation(37)
    
   font:set_char_xadvance('a', 12)
   font:set_char_yadvance('a', 0)
   font:set_char_xlead('a', 1)
   font:set_char_ylead('a', 0)

   font:set_char_xadvance('b', 13)
   font:set_char_yadvance('b', 0)
   font:set_char_xlead('b', 1)
   font:set_char_ylead('b', 0)

   font:set_char_xadvance('c', 11)
   font:set_char_yadvance('c', 0)
   font:set_char_xlead('c', 1)
   font:set_char_ylead('c', 0)

   font:set_char_xadvance('d', 13)
   font:set_char_yadvance('d', 0)
   font:set_char_xlead('d', 1)
   font:set_char_ylead('d', 0)

   font:set_char_xadvance('e', 12)
   font:set_char_yadvance('e', 0)
   font:set_char_xlead('e', 1)
   font:set_char_ylead('e', 0)

   font:set_char_xadvance('f', 8)
   font:set_char_yadvance('f', 0)
   font:set_char_xlead('f', 1)
   font:set_char_ylead('f', 0)

   font:set_char_xadvance('g', 13)
   font:set_char_yadvance('g', 0)
   font:set_char_xlead('g', 1)
   font:set_char_ylead('g', -4)

   font:set_char_xadvance('h', 13)
   font:set_char_yadvance('h', 0)
   font:set_char_xlead('h', 1)
   font:set_char_ylead('h', 0)

   font:set_char_xadvance('i', 7)
   font:set_char_yadvance('i', 0)
   font:set_char_xlead('i', 1)
   font:set_char_ylead('i', 0)

   font:set_char_xadvance('j', 7)
   font:set_char_yadvance('j', 0)
   font:set_char_xlead('j', -1)
   font:set_char_ylead('j', -4)

   font:set_char_xadvance('k', 12)
   font:set_char_yadvance('k', 0)
   font:set_char_xlead('k', 1)
   font:set_char_ylead('k', 0)

   font:set_char_xadvance('l', 7)
   font:set_char_yadvance('l', 0)
   font:set_char_xlead('l', 1)
   font:set_char_ylead('l', 0)

   font:set_char_xadvance('m', 19)
   font:set_char_yadvance('m', 0)
   font:set_char_xlead('m', 1)
   font:set_char_ylead('m', 0)

   font:set_char_xadvance('n', 13)
   font:set_char_yadvance('n', 0)
   font:set_char_xlead('n', 1)
   font:set_char_ylead('n', 0)

   font:set_char_xadvance('o', 12)
   font:set_char_yadvance('o', 0)
   font:set_char_xlead('o', 1)
   font:set_char_ylead('o', 0)

   font:set_char_xadvance('p', 13)
   font:set_char_yadvance('p', 0)
   font:set_char_xlead('p', 1)
   font:set_char_ylead('p', -4)

   font:set_char_xadvance('q', 13)
   font:set_char_yadvance('q', 0)
   font:set_char_xlead('q', 1)
   font:set_char_ylead('q', -4)

   font:set_char_xadvance('r', 9)
   font:set_char_yadvance('r', 0)
   font:set_char_xlead('r', 1)
   font:set_char_ylead('r', 0)

   font:set_kerning('r', '.', -1)

   font:set_kerning('r', ',', -1)

   font:set_char_xadvance('s', 11)
   font:set_char_yadvance('s', 0)
   font:set_char_xlead('s', 0)
   font:set_char_ylead('s', 0)

   font:set_char_xadvance('t', 8)
   font:set_char_yadvance('t', 0)
   font:set_char_xlead('t', 1)
   font:set_char_ylead('t', 0)

   font:set_char_xadvance('u', 13)
   font:set_char_yadvance('u', 0)
   font:set_char_xlead('u', 1)
   font:set_char_ylead('u', 0)

   font:set_char_xadvance('v', 10)
   font:set_char_yadvance('v', 0)
   font:set_char_xlead('v', 0)
   font:set_char_ylead('v', 0)

   font:set_kerning('v', '.', -1)

   font:set_kerning('v', ',', -1)

   font:set_char_xadvance('w', 16)
   font:set_char_yadvance('w', 0)
   font:set_char_xlead('w', 0)
   font:set_char_ylead('w', 0)

   font:set_kerning('w', '.', -1)

   font:set_kerning('w', ',', -1)

   font:set_char_xadvance('x', 11)
   font:set_char_yadvance('x', 0)
   font:set_char_xlead('x', 0)
   font:set_char_ylead('x', 0)

   font:set_char_xadvance('y', 10)
   font:set_char_yadvance('y', 0)
   font:set_char_xlead('y', 0)
   font:set_char_ylead('y', -4)

   font:set_kerning('y', '.', -1)

   font:set_kerning('y', ',', -1)

   font:set_char_xadvance('z', 10)
   font:set_char_yadvance('z', 0)
   font:set_char_xlead('z', 1)
   font:set_char_ylead('z', 0)

   font:set_char_xadvance('A', 14)
   font:set_char_yadvance('A', 0)
   font:set_char_xlead('A', 0)
   font:set_char_ylead('A', 0)

   font:set_kerning('A', 'v', -1)

   font:set_kerning('A', 'w', -1)

   font:set_kerning('A', 'y', -1)

   font:set_kerning('A', 'T', -1)

   font:set_kerning('A', 'V', -1)

   font:set_kerning('A', 'W', -1)

   font:set_kerning('A', 'Y', -1)

   font:set_char_xadvance('B', 15)
   font:set_char_yadvance('B', 0)
   font:set_char_xlead('B', 1)
   font:set_char_ylead('B', 0)

   font:set_char_xadvance('C', 15)
   font:set_char_yadvance('C', 0)
   font:set_char_xlead('C', 1)
   font:set_char_ylead('C', 0)

   font:set_char_xadvance('D', 16)
   font:set_char_yadvance('D', 0)
   font:set_char_xlead('D', 1)
   font:set_char_ylead('D', 0)

   font:set_char_xadvance('E', 14)
   font:set_char_yadvance('E', 0)
   font:set_char_xlead('E', 1)
   font:set_char_ylead('E', 0)

   font:set_char_xadvance('F', 13)
   font:set_char_yadvance('F', 0)
   font:set_char_xlead('F', 1)
   font:set_char_ylead('F', 0)

   font:set_kerning('F', 'a', -1)

   font:set_kerning('F', 'e', -1)

   font:set_kerning('F', 'o', -1)

   font:set_kerning('F', 'A', -1)

   font:set_kerning('F', '.', -1)

   font:set_kerning('F', ',', -1)

   font:set_char_xadvance('G', 15)
   font:set_char_yadvance('G', 0)
   font:set_char_xlead('G', 1)
   font:set_char_ylead('G', 0)

   font:set_char_xadvance('H', 18)
   font:set_char_yadvance('H', 0)
   font:set_char_xlead('H', 1)
   font:set_char_ylead('H', 0)

   font:set_char_xadvance('I', 8)
   font:set_char_yadvance('I', 0)
   font:set_char_xlead('I', 1)
   font:set_char_ylead('I', 0)

   font:set_char_xadvance('J', 8)
   font:set_char_yadvance('J', 0)
   font:set_char_xlead('J', -1)
   font:set_char_ylead('J', -4)

   font:set_kerning('J', '.', -1)

   font:set_kerning('J', ',', -1)

   font:set_char_xadvance('K', 16)
   font:set_char_yadvance('K', 0)
   font:set_char_xlead('K', 1)
   font:set_char_ylead('K', 0)

   font:set_kerning('K', 'y', -1)

   font:set_kerning('K', 'A', -1)

   font:set_char_xadvance('L', 13)
   font:set_char_yadvance('L', 0)
   font:set_char_xlead('L', 1)
   font:set_char_ylead('L', 0)

   font:set_kerning('L', 'T', -1)

   font:set_kerning('L', 'U', -1)

   font:set_kerning('L', 'V', -2)

   font:set_kerning('L', 'W', -1)

   font:set_kerning('L', 'Y', -1)

   font:set_char_xadvance('M', 21)
   font:set_char_yadvance('M', 0)
   font:set_char_xlead('M', 1)
   font:set_char_ylead('M', 0)

   font:set_char_xadvance('N', 17)
   font:set_char_yadvance('N', 0)
   font:set_char_xlead('N', 1)
   font:set_char_ylead('N', 0)

   font:set_kerning('N', '.', -1)

   font:set_kerning('N', ',', -1)

   font:set_char_xadvance('O', 16)
   font:set_char_yadvance('O', 0)
   font:set_char_xlead('O', 1)
   font:set_char_ylead('O', 0)

   font:set_kerning('O', '.', -1)

   font:set_kerning('O', ',', -1)

   font:set_char_xadvance('P', 14)
   font:set_char_yadvance('P', 0)
   font:set_char_xlead('P', 1)
   font:set_char_ylead('P', 0)

   font:set_kerning('P', 'A', -1)

   font:set_kerning('P', '.', -2)

   font:set_kerning('P', ',', -2)

   font:set_char_xadvance('Q', 16)
   font:set_char_yadvance('Q', 0)
   font:set_char_xlead('Q', 1)
   font:set_char_ylead('Q', -3)

   font:set_kerning('Q', '.', -1)

   font:set_kerning('Q', ',', -1)

   font:set_char_xadvance('R', 15)
   font:set_char_yadvance('R', 0)
   font:set_char_xlead('R', 1)
   font:set_char_ylead('R', 0)

   font:set_char_xadvance('S', 13)
   font:set_char_yadvance('S', 0)
   font:set_char_xlead('S', 1)
   font:set_char_ylead('S', 0)

   font:set_char_xadvance('T', 13)
   font:set_char_yadvance('T', 0)
   font:set_char_xlead('T', 0)
   font:set_char_ylead('T', 0)

   font:set_kerning('T', 'a', -1)

   font:set_kerning('T', 'c', -1)

   font:set_kerning('T', 'e', -1)

   font:set_kerning('T', 'o', -1)

   font:set_kerning('T', 'r', -1)

   font:set_kerning('T', 's', -1)

   font:set_kerning('T', 'u', -1)

   font:set_kerning('T', 'w', -1)

   font:set_kerning('T', 'y', -1)

   font:set_kerning('T', 'A', -1)

   font:set_kerning('T', '.', -2)

   font:set_kerning('T', ',', -1)

   font:set_char_xadvance('U', 17)
   font:set_char_yadvance('U', 0)
   font:set_char_xlead('U', 1)
   font:set_char_ylead('U', 0)

   font:set_kerning('U', '.', -1)

   font:set_kerning('U', ',', -1)

   font:set_char_xadvance('V', 14)
   font:set_char_yadvance('V', 0)
   font:set_char_xlead('V', 0)
   font:set_char_ylead('V', 0)

   font:set_kerning('V', 'a', -1)

   font:set_kerning('V', 'e', -1)

   font:set_kerning('V', 'o', -1)

   font:set_kerning('V', 'u', -1)

   font:set_kerning('V', 'y', -1)

   font:set_kerning('V', 'A', -1)

   font:set_kerning('V', '.', -2)

   font:set_kerning('V', ',', -2)

   font:set_char_xadvance('W', 20)
   font:set_char_yadvance('W', 0)
   font:set_char_xlead('W', 0)
   font:set_char_ylead('W', 0)

   font:set_kerning('W', 'a', -1)

   font:set_kerning('W', 'e', -1)

   font:set_kerning('W', 'o', -1)

   font:set_kerning('W', 'r', -1)

   font:set_kerning('W', 'u', -1)

   font:set_kerning('W', 'A', -1)

   font:set_kerning('W', '.', -2)

   font:set_kerning('W', ',', -2)

   font:set_char_xadvance('X', 14)
   font:set_char_yadvance('X', 0)
   font:set_char_xlead('X', 0)
   font:set_char_ylead('X', 0)

   font:set_char_xadvance('Y', 13)
   font:set_char_yadvance('Y', 0)
   font:set_char_xlead('Y', 0)
   font:set_char_ylead('Y', 0)

   font:set_kerning('Y', 'a', -1)

   font:set_kerning('Y', 'e', -1)

   font:set_kerning('Y', 'o', -1)

   font:set_kerning('Y', 'u', -1)

   font:set_kerning('Y', 'A', -1)

   font:set_kerning('Y', '.', -2)

   font:set_kerning('Y', ',', -2)

   font:set_char_xadvance('Z', 13)
   font:set_char_yadvance('Z', 0)
   font:set_char_xlead('Z', 1)
   font:set_char_ylead('Z', 0)

   font:set_char_xadvance('0', 13)
   font:set_char_yadvance('0', 0)
   font:set_char_xlead('0', 1)
   font:set_char_ylead('0', 0)

   font:set_char_xadvance('1', 13)
   font:set_char_yadvance('1', 0)
   font:set_char_xlead('1', 2)
   font:set_char_ylead('1', 0)

   font:set_char_xadvance('2', 13)
   font:set_char_yadvance('2', 0)
   font:set_char_xlead('2', 1)
   font:set_char_ylead('2', 0)

   font:set_char_xadvance('3', 13)
   font:set_char_yadvance('3', 0)
   font:set_char_xlead('3', 1)
   font:set_char_ylead('3', 0)

   font:set_char_xadvance('4', 13)
   font:set_char_yadvance('4', 0)
   font:set_char_xlead('4', 1)
   font:set_char_ylead('4', 0)

   font:set_char_xadvance('5', 13)
   font:set_char_yadvance('5', 0)
   font:set_char_xlead('5', 1)
   font:set_char_ylead('5', 0)

   font:set_char_xadvance('6', 13)
   font:set_char_yadvance('6', 0)
   font:set_char_xlead('6', 1)
   font:set_char_ylead('6', 0)

   font:set_char_xadvance('7', 13)
   font:set_char_yadvance('7', 0)
   font:set_char_xlead('7', 1)
   font:set_char_ylead('7', 0)

   font:set_char_xadvance('8', 13)
   font:set_char_yadvance('8', 0)
   font:set_char_xlead('8', 1)
   font:set_char_ylead('8', 0)

   font:set_char_xadvance('9', 13)
   font:set_char_yadvance('9', 0)
   font:set_char_xlead('9', 1)
   font:set_char_ylead('9', 0)

   font:set_char_xadvance('.', 5)
   font:set_char_yadvance('.', 0)
   font:set_char_xlead('.', 1)
   font:set_char_ylead('.', 0)

   font:set_char_xadvance('!', 8)
   font:set_char_yadvance('!', 0)
   font:set_char_xlead('!', 2)
   font:set_char_ylead('!', 0)

   font:set_char_xadvance('?', 11)
   font:set_char_yadvance('?', 0)
   font:set_char_xlead('?', 1)
   font:set_char_ylead('?', 0)

   font:set_char_xadvance(',', 6)
   font:set_char_yadvance(',', 0)
   font:set_char_xlead(',', 0)
   font:set_char_ylead(',', -3)

   font:set_char_xadvance("'", 6)
   font:set_char_yadvance("'", 0)
   font:set_char_xlead("'", 2)
   font:set_char_ylead("'", 8)

   font:set_char_xadvance('"', 9)
   font:set_char_yadvance('"', 0)
   font:set_char_xlead('"', 2)
   font:set_char_ylead('"', 8)

   font:set_char_xadvance('\\', 7)
   font:set_char_yadvance('\\', 0)
   font:set_char_xlead('\\', 0)
   font:set_char_ylead('\\', -2)

   font:set_char_xadvance('/', 7)
   font:set_char_yadvance('/', 0)
   font:set_char_xlead('/', 0)
   font:set_char_ylead('/', -2)

   return font
end

return _font
