local oo = require 'oo'
local util = require 'util'
local vector = require 'vector'
local constant = require 'constant'

local Timer = require 'Timer'
local Rect = require 'Rect'
local DynO = require 'DynO'
local Indicator = require 'Indicator'

local main_font = require 'dejavu_font'

local PSManager
local Explosion
local ExplosionManager
local Building
local BuildingPiece
local Terrain
local Bomb
local Player
local Engine
local Score
local Menu

local czor = game:create_object('Compositor')
local screen_rect = Rect(camera:viewport())
local screen_width = screen_rect:width()
local screen_height = screen_rect:height()

local terrain
local player
local explosions
local score
local max_attempts = 5

local sfx = {}

function load_sfx(kind, names)
   sfx[kind] = {}
   for ii, name in ipairs(names) do
      table.insert(sfx[kind], game:get_sound(name, 1.0))
   end
end

function play_sfx(kind)
   local snd = util.rand_choice(sfx[kind])
   game:play_sound(snd, 1)
end


function solid_mesh(points, color, mesh)
   if mesh then
      mesh:clear()
   else
      mesh = game:create_object('Mesh')
   end

   for ii = 1,#points,2 do
      mesh:add_point({points[ii], points[ii+1]}, color)
   end
   return mesh
end

function textured_mesh(points, entry, mesh)
   if mesh then
      mesh:clear()
   else
      mesh = game:create_object('Mesh')
   end

   mesh:entry(entry)

   for ii = 1,#points,4 do
      mesh:add_point_and_tcoord({points[ii], points[ii+1]}, {1,1,1,1},
                                {points[ii+2], points[ii+3]})
   end
   return mesh
end

function extend(tbl, pts)
   for ii = 1,#pts do
      table.insert(tbl, pts[ii])
   end
   return tbl
end

function background_stars(go)
   local _art = game:atlas_entry(constant.ATLAS, 'star1')
   local m = 3
   local params =
      {def=
          {n=200,
           layer=constant.BACKDROP,
           renderer={name='PSC_E2SystemRenderer',
                     params={entry=_art}},
           components={
              {name='PSConstantAccelerationUpdater',
               params={acc={0, 0}}},
              {name='PSBoxInitializer',
               params={initial={-_art.w, -_art.h,
                                screen_width + _art.w,
                                screen_height * m + _art.h},
                       refresh={screen_width + _art.w, - _art.h,
                                screen_width + _art.w, screen_height * m + _art.h},
                       minv={-1, 0},
                       maxv={-0.1, 0}}},
              {name='PSRandColorInitializer',
               params={min_color={0.8, 0.8, 0.8, 0.2},
                       max_color={1.0, 1.0, 1.0, 1.0}}},
              {name='PSRandScaleInitializer',
               params={min_scale=0.5,
                       max_scale=1.5}},
              {name='PSBoxTerminator',
               params={rect={-_art.w*2, -_art.h*2,
                             screen_width + _art.w * 2,
                             screen_height * m + _art.h * 2}}}}}}
   return go:add_component('CParticleSystem', params)
end

Score = oo.class(oo.Object)
function Score:init()
   self.world = game:create_world()
   self.go = self.world:create_go()
   self.indicator = Indicator(main_font(1), {screen_width/2, screen_height - 20}, {1,1,1,1}, self.go)
   self:reset()
end

function Score:reset()
   self.attempts = 1
   self.hits = 0
   self:update()
end

function Score:update(da, dh)
   da = da or 0
   dh = dh or 0
   self.attempts = self.attempts + da
   self.hits = self.hits + dh
   self.indicator:update('%d/%d DESTROYED', self.hits, self.attempts)
end

Menu = oo.class(oo.Object)
function Menu:init(font, options)
   local world = game:create_world()
   local go = world:create_go()
   local indicators = {}

   local y = screen_height / 2 + font:line_height() * #options / 2
   local x = screen_width / 2
   for ii = 1,#options do
      local bg = Indicator(font, {x-1, y-1}, {0,0,0,1}, go)
      local choice = Indicator(font, {x, y}, {0,0,0,0}, go)
      choice:update(options[ii][1])
      bg:update(options[ii][1])
      table.insert(indicators, choice)
      y = y - font:line_height()
   end

   self.world = world
   self.go = go
   self.indicators = indicators
   self.state = 1
   self.options = options
   self.up = util.rising_edge_trigger(false)
   self.down = util.rising_edge_trigger(false)
   self.select = util.falling_edge_trigger(false)
   go:add_component('CScripted', {update_thread=util.fthread(self:bind('update'))})
end

function Menu:update()
   local input = util.input_state()
   local options = self.options
   local state = self.state
   local fire = false

   if self.up(input.updown > 0.1 or input.leftright < -0.1) then
      state = state - 1
      if state <= 0 then
         state = #options
      end
   elseif self.down(input.updown < -0.1 or input.leftright > 0.1) then
      state = state + 1
      if state > #options then
         state = 1
      end
   elseif self.select(input.action2) then
      fire = true
   end

   for ii = 1, #options do
      if ii == state then
         self.indicators[ii]:color({1,1,1,1})
      else
         local c = .4
         self.indicators[ii]:color({c,c,c,1})
      end
   end

   if fire then
      local option = self.options[state]
      option[2]()
   end

   self.state = state
end

function Menu:terminate()
   self.world:delete_me(1)
end

PSManager = oo.class(oo.Object)
function PSManager:init(n, ctor)
   self.n = n
   self.systems = {}
   for i = 1,n do
      table.insert(self.systems, ctor())
   end
end

function PSManager:activate(...)
   local psys = table.remove(self.systems, 1)
   psys:activate(...)
   table.insert(self.systems, psys)
   return psys
end

Thruster = oo.class(oo.Object)
function Thruster:init(go, offset, spd)
   self.go = go
   self.spd = spd
   self.offset = offset

   local _smoke = game:atlas_entry(constant.ATLAS, 'steam')
   local params =
      {def=
          {n=50,
           renderer={name='PSC_E2SystemRenderer',
                     params={entry=_smoke}},
           activator={name='PSConstantRateActivator',
                      params={rate=100}},
           components={
              {name='PSConstantAccelerationUpdater',
               params={acc={0,0}}},
              {name='PSTimeAlphaUpdater',
               params={time_constant=0.4,
                       max_scale=1.0}},
              {name='PSFireColorUpdater',
               params={max_life=0.8,
                       start_temperature=6000,
                       end_temperature=2000}},
              {name='PSBoxInitializer',
               params={initial={offset[1],offset[2],offset[1],offset[2]},
                       refresh={offset[1],offset[2],offset[1],offset[2]},
                       minv={-10,-10},
                       maxv={10,10}}},
              {name='PSTimeInitializer',
               params={min_life=0.4,
                       max_life=0.8}},
              {name='PSTimeTerminator'}}}}

   local system = go:add_component('CParticleSystem', params)
   local psbox = system:def():find_component('PSBoxInitializer')

   self.psbox = psbox
   self.timer = Timer(go)
   self:update()
end

function Thruster:update()
   -- update dirction
   local dir = vector.new_from_angle(self.go:angle())
   local off = dir * self.offset[1]
   self.psbox:refresh({off[1], off[2], off[1], off[2]})

   self.timer:reset(.1, self:bind('update'))
end

Explosion = oo.class(oo.Object)
function Explosion:init(lifetime)
   self.lifetime = lifetime

   local _smoke = game:atlas_entry(constant.ATLAS, 'steam')
   local params =
      {def=
          {n=50,
           renderer={name='PSC_E2SystemRenderer',
                     params={entry=_smoke}},
           activator={name='PSConstantRateActivator',
                      params={rate=0}},
           components={
              {name='PSConstantAccelerationUpdater',
               params={acc={0,0}}},
              {name='PSTimeAlphaUpdater',
               params={time_constant=0.4,
                       max_scale=1.0}},
              {name='PSFireColorUpdater',
               params={max_life=0.3,
                       start_temperature=9000,
                       end_temperature=500}},
              {name='PSBoxInitializer',
               params={initial={-16,-34,16,-30},
                       refresh={-16,-34,16,-30},
                       minv={0,0},
                       maxv={0,0}}},
              {name='PSTimeInitializer',
               params={min_life=0.2,
                       max_life=0.4}},
              {name='PSTimeTerminator'}}}}

   local system = stage:add_component('CParticleSystem', params)
   local activator = system:def():find_component('PSConstantRateActivator')
   local psbox = system:def():find_component('PSBoxInitializer')

   self.activator = activator
   self.psbox = psbox
   self.timer = Timer()
end

function Explosion:activate(center, w, h, speed)
   local rect = {center[1] - w/2, center[2] - h/2, center[1] + w/2, center[2] + h/2}
   self.psbox:initial(rect)
   self.psbox:refresh(rect)
   self.psbox:minv({-speed, -speed})
   self.psbox:maxv({speed, speed})
   self.activator:rate(1000)
   local term = function()
      self.activator:rate(0)
   end
   self.timer:reset(self.lifetime, term)
end

ExplosionManager = oo.class(PSManager)
function ExplosionManager:init(n)
   local ctor = function()
      return Explosion(0.2)
   end

   PSManager.init(self, n, ctor)
end

Building = oo.class(DynO)
function Building:init(building)
   local v1 = vector.new(building[1])
   local v2 = vector.new(building[2])
   local width = (v1 - v2):length()
   local height = util.rand_between(32,128)
   local w2 = width/2
   local h2 = height/2
   local center = vector.new({0,height/2}) + (v1 + v2) *.5

   DynO.init(self, center)

   local go = self:go()

   local points = {w2,h2,1,1, -w2,h2,0,1, -w2,-h2,0,0,
                   w2,h2,1,1, -w2,-h2,0,0, w2,-h2,1,0}
   local _art = game:atlas_entry(constant.ATLAS, 'building')
   self.sprite = go:add_component('CMesh', {mesh=textured_mesh(points, _art)})
   self:add_collider({fixture={type='rect', w=width, h=height}})
   self.width = width
   self.height = height
end

function fracture_tris(c, w, h, fractures)
   local tris = {}
   c = vector.new(c)
   local bl = c - w/2 - h/2

   for ii = 1,#fractures,6 do
      local p1 = bl + w * fractures[ii]   + h * fractures[ii+1]
      local t1 = {fractures[ii], fractures[ii+1]}

      local p2 = bl + w * fractures[ii+2] + h * fractures[ii+3]
      local t2 = {fractures[ii+2], fractures[ii+3]}

      local p3 = bl + w * fractures[ii+4] + h * fractures[ii+5]
      local t3 = {fractures[ii+4], fractures[ii+5]}

      table.insert(tris, {p1, t1, p2, t2, p3, t3})
   end
   return tris
end

local fracture_types = {
   { 1,1, 0,1, 0,0,  1,1, 0,0, 1,0 },
   { 0,1, 0,0, .5,1,  .5,1, 0,0, 1,0,  .5,1, 1,0, 1,1 }
}

function Building:bombed()
   local go = self:go()
   if go then
      -- spawn pieces and remove ourselves
      local v1 = vector.new({self.width, 0})
      local v2 = vector.new({0, self.height})
      local tris = fracture_tris(go:pos(), v1, v2, util.rand_choice(fracture_types))
      for ii = 1,#tris do
         BuildingPiece({tris[ii]})
      end

      explosions:activate(go:pos(), self.width, self.height, 200)
      score:update(0, 1)
      self:terminate()
   end
end

local Tri = oo.class(oo.class)
function Tri:init(a, b, c)
   if #a == 3 then
      -- given an array or tri
      b = a[2]
      c = a[3]
      a = a[1]
   end
   self[1] = vector.new(a)
   self[2] = vector.new(b)
   self[3] = vector.new(c)
end

function Tri:center()
   return (self[1] + self[2] + self[3]) / 3
end

function Tri:__add(v)
   return Tri(self[1] + v, self[2] + v, self[3] + v)
end

function Tri:__sub(v)
   return Tri(self[1] - v, self[2] - v, self[3] - v)
end

BuildingPiece = oo.class(DynO)
function BuildingPiece:init(tris_and_texs)
   local c = vector.new({0,0})
   local tris = {}
   for ii=1,#tris_and_texs do
      local tat = tris_and_texs[ii]
      local tri = Tri(tat[1], tat[3], tat[5])
      table.insert(tris, tri)
      c = c + tri:center()
   end
   c = c / #tris

   -- recenter the triangles and pack for mesh
   local points = {}
   for ii=1,#tris do
      tris[ii] = tris[ii] - c
      extend(points, tris[ii][1])
      extend(points, tris_and_texs[ii][2])
      extend(points, tris[ii][2])
      extend(points, tris_and_texs[ii][4])
      extend(points, tris[ii][3])
      extend(points, tris_and_texs[ii][6])
   end

   DynO.init(self, c)

   local go = self:go()
   go:vel(util.rand_vector(10,100))
   go:fixed_rotation(0)

   -- visual
   local _art = game:atlas_entry(constant.ATLAS, 'building')
   local mesh = textured_mesh(points, _art)
   self.mesh = go:add_component('CMesh', {mesh=mesh})
   self.tform = game:create_object('Matrix44')
   self.tform:identity()
   self.mesh:tform(self.tform)

   -- add colliders
   for ii=1,#tris do
      go:add_component('CSensor', {fixture={type='poly', points=tris[ii],
                                            density=1, friction=0.8}})
   end

   local timeout = function()
      self:terminate()
   end
   Timer(go):reset(10, timeout)
end

function BuildingPiece:update()
   local go = self:go()
   if go then
      self.tform:rotation(go:angle())
   end
end

Terrain = oo.class(DynO)
function Terrain:init(var, steps)
   DynO.init(self, {0,0})
   local go = self:go()
   go:body_type(constant.STATIC)

   self.var = var
   self.steps = steps
   self.coll = {}

   local wlevel = screen_height*1/4
   self.wlevel = wlevel

   local surf = self:generate(var, steps)
   self.comp = go:add_component('CMesh', {mesh=surf.mesh})
   self:update_colliders(surf.surfaces)
   self.b = self:building(surf.building)
   self.mesh = surf.mesh
   self.lasty = surf.lasty

   local water = solid_mesh({screen_width,wlevel,  0,wlevel,  0,0,
                             0,0,  screen_width,0,  screen_width, wlevel}, {0,0,.7,1})
   self.water = go:add_component('CMesh', {mesh=water, layer=constant.BACKGROUND})
   self.stars = background_stars(go)
end

function Terrain:reset()
   local surf = self:generate(self.var, self.steps, self.mesh, self.lasty)
   self.lasty = surf.lasty
   self:update_colliders(surf.surfaces)
   if self.b then
      self.b:terminate()
   end
   self.b = self:building(surf.building)
end

function Terrain:update_colliders(surfaces)
   local go = self:go()

   -- remove old colliders
   for ii = 1,#self.coll do
      self.coll[ii]:delete_me(1)
   end
   self.coll = {}

   -- add new colliders
   for ii = 1,#surfaces do
      local surface = surfaces[ii]
      table.insert(self.coll, go:add_component('CSensor', ({fixture={type='poly', points=surfaces[ii]}})))
   end
end

function Terrain:building(building)
   return Building(building)
end

function Terrain:generate(var, steps, mesh, lasty)
   local dx = screen_width / steps
   local lastx = 0
   local lasty = lasty or screen_height / 3

   local mpoints = {}
   local surfaces = {}
   local nbuilding = math.floor(util.rand_between(steps*4/9,steps*9/10)) + 1
   local building

   for ii = 1,steps do
      local x = dx * ii
      local y = lasty + world:random_gaussian() * var
      y = math.min(screen_height*2/3, math.max(screen_height/6, y))
      if nbuilding == ii then
         -- place our building if above water
         if lasty > self.wlevel then
            y = lasty
            building = {{lastx,lasty},  {x,y}}
         else
            -- raise the land level artificially
            y = self.wlevel + 10
            nbuilding = nbuilding + 1
         end
      end

      extend(mpoints, {x,y,1,1,  lastx,lasty,0,1,  lastx,0,0,0,
                       x,y,1,1,  lastx,0,0,0,      x,0,1,0})

      local surface = {{x,y}, {lastx,lasty}, {lastx,0}, {x,0}}
      table.insert(surfaces, surface)

      lasty = y
      lastx = x
   end

   local _art = game:atlas_entry(constant.ATLAS, 'terrain')
   return {mesh = textured_mesh(mpoints, _art, mesh),
           surfaces = surfaces,
           lasty = lasty,
           building = building}
end

Bomb = oo.class(DynO)
function Bomb:init(pos, vel)
   DynO.init(self, pos)
   local go = self:go()
   go:vel(vel)
   go:fixed_rotation(0)

   local _art = game:atlas_entry(constant.ATLAS, 'bomb')
   self.sprite = go:add_component('CStaticSprite', {entry=_art})
   self.sprite:angle_offset(math.pi/2)
   self:add_collider({fixture={type='rect', w=16, h=16, category=3, mask=1}})
end

function Bomb:started_colliding_with(other)
   if other:is_a(Building) then
      other:bombed()
   end

   local go = self:go()
   if go then
      explosions:activate(go:pos(), 16, 16, 30)
      self:terminate()
      play_sfx('expl')
   end
end

function Bomb:update()
   local go = self:go()
   if go then
      go:angle(vector.new(go:vel()):angle())
   end
end

Player = oo.class(DynO)
function Player:init()
   self.initial_height = screen_height*9/10
   DynO.init(self, {0,self.initial_height})
   local go = self:go()
   go:fixed_rotation(0)

   local w = 64
   local h = w/3
   local points = {-w/2,h/2, -w/2,-h/2, w/2,h/2,  w/2,h/2, -w/2,-h/2, w/2,-h/2}
   local _art = game:atlas_entry(constant.ATLAS, 'player')
   go:add_component('CStaticSprite', {entry=_art})
   self.coll = go:add_component('CSensor', {fixture={type='rect', w=w, h=h, density=2,
                                                     category=2}})
   self.bomb_trigger = util.rising_edge_trigger(false)
   go:vel({100,0})
   self.min_speed = 70
   self.max_speed = 300
   self.fired = false

   Thruster(go, {-w/2,0}, self.min_speed)

   -- reset the score counters
   attempts = 1
   hits = 0
end

function Player:update()
   local go = self:go()
   local pos = vector.new(go:pos())
   local vel = vector.new(go:vel())

   -- set rotation
   local angle = go:angle()
   local spd = vel:length()

   -- compute lift
   local ahead = vector.new_from_angle(angle)
   local vahead = math.abs(vel:dot(ahead))
   local lift_angle = angle + math.pi/2
   local lift_dir = vector.new_from_angle(lift_angle)
   local lift = lift_dir * vahead * screen_height/pos[2] * 0.10
   go:apply_force(lift)

   -- thrust decreases with height
   if vahead < self.max_speed then
      go:apply_force(ahead * (self.max_speed - vahead) * screen_height/pos[2] * .5)
   end

   -- drag. increases as total force due to air pressure
   -- increases. decreases as you go up
   local drag_factor = .1 * (screen_height / pos[2]) + 1.5 * (math.abs(vel:dot(lift_dir)) / vel:length())
   local drag = vel * -drag_factor
   go:apply_force(drag)

   local input = util.input_state()
   if (not self.fired) and self.bomb_trigger(input.action1) then
      Bomb(pos, go:vel())
      self.fired = true
   end

   if math.abs(input.leftright) > 0.1 then
      go:angle_rate(0)
      go:angle(angle - input.leftright * world:dt())
   end

   -- make sure that the player is on the screen and near the top
   local miny = math.max(0, pos[2] - screen_height*7/8)
   local maxy = miny + screen_height
   camera:world2camera():orthographic_proj(0, screen_width, miny, maxy, -1, 1)

   -- reset if we go off the screen
   local reset = false
   if pos[1] > screen_width then
      -- reset terrain and position
      reset = true
      go:pos({0,pos[2]})
   elseif pos[1] < 0 then
      reset = true
      go:pos({screen_width,pos[2]})
   end

   if reset then
      self.fired = false
      DynO.terminate_all(Bomb)
      DynO.terminate_all(BuildingPiece)
      DynO.terminate_all(Building)
      if score.attempts == max_attempts then
         end_game()
      else
         terrain:reset()
         score:update(1, 0)
      end
   end
end

function background()
   czor:clear_with_color(util.rgba(0,0,30,255))
end

function game_init()
   Timer():reset(0, safe_init)
end

function classic_init()
   player = Player()

   if score then
      score:reset()
   else
      score = Score()
   end

   if not explosions then
      explosions = ExplosionManager(5)
   end
end

function end_game()
   player:terminate()

   local menu
   local main_menu = function()
      menu:terminate()
      show_main()
   end
   menu = Menu(main_font(3), {{'Press ENTER to continue', main_menu}})
end

function show_main()
   local menu
   local main_menu

   local start = function()
      menu:terminate()
      classic_init()
      terrain:reset()
   end

   local instructions = function()
      menu:terminate()
      local font = main_font(2)
      local options = {{'Ascend and descend using the LEFT and RIGHT arrow keys.', main_menu},
                       {'Press SPACE to drop bombs.', main_menu},
                       {'Destroy as many buildings as possible in 5 screens.', main_menu},
                       {'You only get 1 bomb per screen.', main_menu},
                       {'Press enter to continue.', main_menu}}

      menu = Menu(font, options)
   end

   local credits = function()
      menu:terminate()
      local font = main_font(2)
      local options = {{'Music by DST.', main_menu},
                       {'Sound created in CFXR.', main_menu},
                       {'Art, code, concept by @netguy204.', main_menu},
                       {'Press enter to continue.', main_menu}}

      menu = Menu(font, options)
   end

   main_menu = function()
      if menu then
         menu:terminate()
      end
      menu = Menu(main_font(3), {{'Instructions', instructions},
                                 {'Start', start},
                                 {'Credits', credits}})

   end

   main_menu()
end

function safe_init()
   util.install_basic_keymap()
   world:gravity({0,-45})

   local expl = {'resources/expl1.ogg', 'resources/expl3.ogg'}
   load_sfx('expl', expl)

   local songs = {'resources/DST-1990.ogg'}
   util.loop_music(util.rand_shuffle(songs))
   local cam = stage:find_component('Camera', nil)
   cam:pre_render(util.fthread(background))

   terrain = Terrain(50, 20)

   show_main()
end
