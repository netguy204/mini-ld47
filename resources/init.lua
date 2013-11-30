local oo = require 'oo'
local util = require 'util'
local vector = require 'vector'
local constant = require 'constant'

local Timer = require 'Timer'
local Rect = require 'Rect'
local DynO = require 'DynO'

local czor = game:create_object('Compositor')
local screen_rect = Rect(camera:viewport())
local screen_width = screen_rect:width()
local screen_height = screen_rect:height()

local terrain
local player
local explosions

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

function extend(tbl, pts)
   for ii = 1,#pts do
      table.insert(tbl, pts[ii])
   end
   return tbl
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

local Building = oo.class(DynO)
function Building:init(building)
   local v1 = vector.new(building[1])
   local v2 = vector.new(building[2])
   local width = (v1 - v2):length()
   local height = util.rand_between(32,128)

   local center = vector.new({0,height/2}) + (v1 + v2) *.5

   DynO.init(self, center)

   local go = self:go()
   go:fixed_rotation(0)

   go:add_component('CTestDisplay', {w=width, h=height})
   self:add_collider({fixture={type='rect', w=width, h=height}})
   self.width = width
   self.height = height
end

function Building:bombed()
   local go = self:go()
   if go then
      explosions:activate(go:pos(), self.width, self.height, 200)
      self:terminate()
   end
end

local Terrain = oo.class(DynO)
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

      extend(mpoints, {x,y,  lastx,lasty,  lastx,0,
                       x,y,  lastx,0,      x,0})

      local surface = {{x,y}, {lastx,lasty}, {lastx,0}, {x,0}}
      table.insert(surfaces, surface)

      lasty = y
      lastx = x
   end

   return {mesh = solid_mesh(mpoints, {0,1,0,1}, mesh),
           surfaces = surfaces,
           lasty = lasty,
           building = building}
end

local Bomb = oo.class(DynO)
function Bomb:init(pos, vel)
   DynO.init(self, pos)
   local go = self:go()
   go:vel(vel)
   go:fixed_rotation(0)

   self.sprite = go:add_component('CTestDisplay', {w=16,h=16,color={1,0,0,1}})
   self:add_collider({fixture={type='rect', w=16, h=16}})
end

function Bomb:started_colliding_with(other)
   if other:is_a(Building) then
      other:bombed()
   end

   local go = self:go()
   if go then
      explosions:activate(go:pos(), 16, 16, 30)
      self:terminate()
   end
end

local Player = oo.class(DynO)
function Player:init()
   self.initial_height = screen_height*9/10
   DynO.init(self, {0,self.initial_height})
   local go = self:go()

   go:body_type(constant.KINEMATIC)
   self.sprite = go:add_component('CTestDisplay', {w=64,h=64/3,
                                                     color={0,0,1,1}})
   self.bomb_trigger = util.rising_edge_trigger(false)
   go:vel({100,0})
end

function Player:update()
   local go = self:go()
   local pos = go:pos()

   if pos[1] > screen_width then
      -- reset terrain and position
      terrain:reset()
      DynO.terminate_all(Bomb)
      go:pos({0,self.initial_height})
   end

   local input = util.input_state()
   if self.bomb_trigger(input.action1) then
      Bomb(pos, go:vel())
   end
end

function background()
   czor:clear_with_color(util.rgba(0,0,15,255))
end

function game_init()
   util.install_basic_keymap()
   world:gravity({0,-45})

   local cam = stage:find_component('Camera', nil)
   cam:pre_render(util.fthread(background))

   terrain = Terrain(50, 20)
   player = Player()
   explosions = ExplosionManager(5)
end
