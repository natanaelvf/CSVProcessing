{-# LANGUAGE DataKinds #-}
import System.IO
    ( hSetBuffering, stdin, stdout, BufferMode(NoBuffering) )
import System.Environment (getArgs)

import Test.QuickCheck

main :: IO ()
main = do
    hSetBuffering stdin NoBuffering
    hSetBuffering stdout NoBuffering
    flag <- getArgs                       -- we get (or not) the flag from the user

    if null flag then do                  -- if he didn't give any
        metric <- getLine                 -- we get the metric from the user
        decideForMe $ words metric        -- we call a decider to think for us

    else do                               -- if he gave any (in this case test) flag
        quickCheck prop_group_ints
        quickCheck prop_search
        quickCheck prop_new_transactions

-- First Stage : Decisions --

-- the decider gets the first line of the input,
-- where the user gives us the column, the metric and the groupby
-- as this is only given once, we must propagate those values throughout the code
-- we chose a tuple to store it
decideForMe :: [String] -> IO()
decideForMe metricsArray = do
    case metric of
        "exit"    -> return ()
        _         -> loop (column,metric,groupby) []

    where column = read $ metricsArray !! 1
          metric = head metricsArray
          groupby  = getGroupAsInts $ drop 2 metricsArray

-- this function turns ["groupby ", "2 ", "groupby",  "3" .."] into [2,3..]
getGroupAsInts :: [String] -> [Int]
getGroupAsInts = map read $ filter (/= "groupby") 

-- Second Stage : Looping --

-- here we decide wether to loop or not, based on the user input
loop :: (Int,String,[Int]) -> [([Float],[Float])] -> IO()
loop colmetricgroup mappy = do
    nextInput <- getLine
    case nextInput of 
        "exit" -> return ()
        _      -> stillGoing colmetricgroup mappy nextInput

-- Third Stage : Filtering and Storing --

-- in this stage, we read the next transaction and call a version of an insert
-- to store the "entries" as (groupBy, value)

stillGoing :: (Int,String,[Int]) -> [([Float],[Float])] -> String -> IO()
stillGoing (column,metric,groupby) mappy nextInput = 
    insert key value mappy (column,metric,groupby)

    -- we store the input as [Float] to later use it when dealing with average
    -- we also store "groupby" which is [Int] to propagate in our "map"; 
    -- as they were only given once as input by the user
    where 
        inputTransaction = map read (words nextInput) :: [Float]
        value = [inputTransaction !! column]        
        key = newTransactions groupby inputTransaction []

-- we sort through the transactions to see which matter
    -- as in, which transactions of index x appear in ys
newTransactions :: [Int] -> [Float] -> [Float] -> [Float]
newTransactions [ ]    _  result = result
newTransactions  _     []   _    = []
newTransactions (x:xs) ys result = newTransactions xs ys $ ys !! x : result

-- we store the values of the transactions that matter to us as a value,
-- its key being the chosen groupby(s)
insert :: [Float] -> [Float] -> [([Float], [Float])] -> (Int,String,[Int]) -> IO()
insert key value mappy colmetricgroup
 | key `elem` keys = choosePrinter colmetricgroup (value ++ values) ((key,value ++ values) : mappy)
 | otherwise       = choosePrinter colmetricgroup  value            ((key,value) : mappy)
    where
        keys = map fst mappy
        values = search key mappy

-- we must search for the value associated with the key
-- if AND ONLY IF the key is present
search :: [Float] -> [([Float],[Float])] -> [Float]
search _ [] = error "key not found!" -- nunca e lancado
search k ((key,value):mappy) = if k == key then value else search k mappy

-------- Last Stage : Printing and Looping ----------

-- earlier we propagated the metric so we could choose what to print here
choosePrinter :: (Int,String,[Int]) -> [Float] -> [([Float],[Float])] -> IO()
choosePrinter (column,metric,group) transactions mappy = do
    case metric of
        "sum"     -> printSumAndProceed (column,metric,group) transactions mappy
        "maximum" -> printMaxAndProceed (column,metric,group) transactions mappy
        "average" -> printAvgAndProceed (column,metric,group) transactions mappy
        _         -> return ()

printSumAndProceed :: (Int, String, [Int]) -> [Float] -> [([Float],[Float])] ->  IO()
printSumAndProceed colmetricgroup transactions mappy = do
    print $ sum transactions
    loop colmetricgroup mappy

printMaxAndProceed :: (Int, String, [Int])-> [Float] -> [([Float],[Float])] ->  IO()
printMaxAndProceed colmetricgroup transactions mappy = do
    print $ maximum transactions
    loop colmetricgroup mappy

-- this function required us to know all the previous values that were given,
-- in case the metric was "average", so that we could calculate it
printAvgAndProceed :: (Int, String, [Int]) -> [Float] -> [([Float],[Float])] ->  IO()
printAvgAndProceed colmetricgroup transactions mappy = do
    print $ soma / fromIntegral nrTransacoes
    loop colmetricgroup mappy

    where soma = sum transactions
          nrTransacoes = length transactions

-------- Post Stage : Testing --------

-- Testing getGroupAsInts --

-- we check if the length of a list of positive indexes
-- is equal to the length of the transformation of ["groupby ", "2 ", "groupby",  "3" .."] into [2,3..]
-- we use "actualIndexs" because these must be pusitive and we want to avoid the use of "Property"

    -- length indexs == length (getGroupAsInts listOfGroupByes)

prop_group_ints :: [Int] -> Bool
prop_group_ints indexs = length actualIndexs == length (getGroupAsInts listOfGroupByes)

    where listOfGroupByes = take (length actualIndexs) infiniteGroupByes
          infiniteGroupByes = foldl (\acc i -> acc ++ (["groupby "] ++ [show i])) [] actualIndexs
          actualIndexs = filter (>0) indexs

-- Testing newTransactions --

-- we check if the length of the filtered list is less or equal than the original list of transactions

    -- length (newTransactions indexs transactions []) <= length indexs
prop_new_transactions :: [Int] -> [Float] -> Bool
prop_new_transactions indexs transactions = length (newTransactions indexs transactions []) <= length indexs

-- Testing search --

-- we check if when inserting a value into the map, we can then search for it

    -- search key ((key, value):mappy) == value

prop_search :: [Float] -> [Float] -> [([Float],[Float])] -> Bool
prop_search key value mappy = search key ((key, value):mappy) == value
