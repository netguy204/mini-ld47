local oo = require 'oo'
local util = require 'util'
local vector = require 'vector'
local constant = require 'constant'

local Timer = require 'Timer'
local Rect = require 'Rect'
local DynO = require 'DynO'

local PSManager
local Explosion
local ExplosionManager
local Building
local BuildingPiece
local Terrain
local Bomb
local Player
local Engine

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

Building = oo.class(DynO)
function Building:init(building)
   local v1 = vector.new(building[1])
   local v2 = vector.new(building[2])
   local width = (v1 - v2):length()
   local height = util.rand_between(32,128)

   local center = vector.new({0,height/2}) + (v1 + v2) *.5

   DynO.init(self, center)

   local go = self:go()
   go:fixed_rotation(0)

   self.sprite = go:add_component('CTestDisplay', {w=width, h=height})
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
      local p2 = bl + w * fractures[ii+2] + h * fractures[ii+3]
      local p3 = bl + w * fractures[ii+4] + h * fractures[ii+5]
      table.insert(tris, {p1, p2, p3})
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
function BuildingPiece:init(tris)
   local c = vector.new({0,0})
   for ii=1,#tris do
      tris[ii] = Tri(tris[ii])
      c = c + tris[ii]:center()
   end
   c = c / #tris

   -- recenter the triangles and pack for mesh
   local points = {}
   for ii=1,#tris do
      tris[ii] = tris[ii] - c
      extend(points, tris[ii][1])
      extend(points, tris[ii][2])
      extend(points, tris[ii][3])
   end

   DynO.init(self, c)

   local go = self:go()
   go:vel(util.rand_vector(10,100))
   go:fixed_rotation(0)

   -- visual
   local mesh = solid_mesh(points, {1,0,1,1})
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

Bomb = oo.class(DynO)
function Bomb:init(pos, vel)
   DynO.init(self, pos)
   local go = self:go()
   go:vel(vel)
   go:fixed_rotation(0)

   self.sprite = go:add_component('CTestDisplay', {w=16,h=16,color={1,0,0,1}})
   self:add_collider({fixture={type='rect', w=16, h=16, mask=1}})
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

Player = oo.class(DynO)
function Player:init()
   self.initial_height = screen_height*9/10
   DynO.init(self, {0,self.initial_height})
   local go = self:go()
   go:fixed_rotation(0)

   local w = 64
   local h = w/3
   local points = {-w/2,h/2, -w/2,-h/2, w/2,h/2,  w/2,h/2, -w/2,-h/2, w/2,-h/2}
   self.tform = game:create_object('Matrix44')
   self.tform:identity()
   self.mesh = go:add_component('CMesh', {mesh=solid_mesh(points,{1,1,1,1}), tform=self.tform})
   self.coll = go:add_component('CSensor', {fixture={type='rect', w=w, h=h, density=2,
                                                     category=2}})
   self.bomb_trigger = util.rising_edge_trigger(false)
   go:vel({100,0})
   self.min_speed = 70
   self.max_speed = 200
end

function Player:update()
   local go = self:go()
   local pos = vector.new(go:pos())
   local vel = vector.new(go:vel())

   -- set rotation
   local angle = go:angle()
   self.tform:rotation(angle)

   -- compute lift
   local ahead = vector.new_from_angle(angle)
   local vahead = math.abs(vel:dot(ahead))
   local lift_angle = angle + math.pi/2
   local lift_dir = vector.new_from_angle(lift_angle)
   local lift = lift_dir * vahead * screen_height/pos[2] * 0.10
   go:apply_force(lift)

   -- thrust
   if vahead < self.max_speed then
      go:apply_force(ahead * (self.max_speed - vahead) * 0.8)
   end

   -- drag. increases as total force due to air pressure increases
   local drag_factor = .1 + 0.6 * (math.abs(vel:dot(lift_dir)) / vel:length())
   local drag = vel * -drag_factor
   go:apply_force(drag)

   if pos[1] > screen_width then
      -- reset terrain and position
      DynO.terminate_all(Bomb)
      DynO.terminate_all(BuildingPiece)
      DynO.terminate_all(Building)
      terrain:reset()
      go:pos({0,pos[2]})
   end

   local input = util.input_state()
   if self.bomb_trigger(input.action1) then
      Bomb(pos, go:vel())
   end

   if math.abs(input.leftright) > 0.1 then
      go:angle_rate(0)
      go:angle(angle - input.leftright * world:dt())
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
