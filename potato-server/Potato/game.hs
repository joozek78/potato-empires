{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE FlexibleInstances #-}
module Potato.Game where 

import Data.Default
import Data.String
import Data.Text.Lazy (Text)
import Data.Text.Lazy.Encoding (decodeUtf8)
import qualified Control.Monad.State as S
import Control.Lens hiding (index, (.=))
import Data.Array
import Data.Array.IArray (amap)
import Data.Maybe
import Data.HashMap.Strict (union)


data Point = Point Int Int deriving (Show, Eq, Ord)
instance Ix Point where
    range ((Point minX minY), (Point maxX maxY)) = [(Point x y) | x <- [minX .. maxX], y <- [minY .. maxY]] 
    inRange ((Point minX minY), (Point maxX maxY)) (Point x y) = and [x >= minX, y >= minY, x <= maxX, y <= maxY] 
   
    -- implemented the same as default (a,b) Ix instance
    index r@((Point l1 l2), (Point u1 u2)) p@(Point i1 i2) | inRange r p = index (l1,u1) i1 * rangeSize (l2,u2) + index (l2,u2) i2 
                                                           | otherwise = error "Out of range"

data FieldType = Land | Water deriving (Show, Eq)

data City = City {
    _name :: String
} deriving (Show)

data Unit = Unit {
    _BattleValue :: BattleValue,
    _owner :: Player
} deriving (Show)

data MapField = MapField { 
    _FieldType :: FieldType,
    _city :: Maybe City,
    _unit :: Maybe Unit
}

type GameMap = Array Point MapField

type BattleValue = Int
data Player = Redosia | Bluegaria | Greenland | Shitloadnam deriving (Show, Eq, Ord, Enum)
type Timestamp = Int

data GameState = GameState {
    _GameMap :: GameMap,
    _CurrentPlayer :: Player,
    _timestamp :: Timestamp
}

makeLenses ''MapField
makeFields ''GameState
makeFields ''City
makeFields ''Unit
makeLenses ''GameState
makeLenses ''City
makeLenses ''Unit

data Move = Move Point Point deriving (Show, Eq)

isValid :: Player -> GameState -> Move -> Bool
isValid player game (Move start end) =
    and [isNotOutOfBounds, isValidUnitAtStart, isValidDestination, isNotTooFar]
    where
        gmap = game ^. gameMap
        
        isNotOutOfBounds = inRange (bounds gmap) start && inRange (bounds gmap) end

        isValidUnitAtStart = isJust $ (gmap ! start) ^. unit

        isValidDestination = (isNothing $ (gmap ! end) ^. unit) &&
                             ((== Land) $ (gmap ! end) ^. fieldType)

        isNotTooFar = (manhattanDistance start end) <= 3
            where manhattanDistance (Point x1 y1) (Point x2 y2) = abs (x2-x1) + abs (y2-y1)
      
-- |Returns Just new game state if the move is valid, nothing otherwise.
move :: Player -> Move -> GameState -> Maybe GameState
move p m@(Move start end) g = if (isValid p g m) then Just applyMove else Nothing
                               where
                                aUnit = (g ^. gameMap) ! start ^. unit
                                changeMap = (ix end . unit .~ aUnit) . 
                                            (ix start . unit .~ Nothing)
                                applyMove = g & gameMap %~ changeMap
                                				 & timestamp %~ (+1)
                                				 & currentPlayer %~ nextPlayer

nextPlayer :: Player -> Player
nextPlayer Shitloadnam = Redosia
nextPlayer x = succ x
                                
getFieldElemList elem game = elems
    where 
        gmap = game ^. gameMap
        pointsAndFields = (assocs gmap) ^.. traversed.(filtered (\(pos, field) -> isJust $ field ^. elem))
        elems = map (\(point, field) -> (point, fromJust $ field ^. elem)) pointsAndFields

getCitiesList = getFieldElemList city
getUnitsList = getFieldElemList unit

getFieldTypesList game = toListOfLists $ amap (view fieldType) gmap
    where gmap = game ^. gameMap
          toListOfLists a = [ row y | y <- [minY .. maxY]]
           where
              row y = [ a ! (Point x y) | x <- [minX .. maxX]]
              ((Point minX minY), (Point maxX maxY)) = bounds a
