#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

NUM_TO_GUESS=$(($RANDOM%1000 + 1))
GUESS_COUNT=0

echo "Enter your username:"
read USERNAME

USERNAME_FROM_DB=$($PSQL "SELECT name FROM users WHERE name='$USERNAME'")

if [[ $USERNAME_FROM_DB ]]
then
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE name='$USERNAME_FROM_DB'")
  BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE name='$USERNAME_FROM_DB'")
  echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
else
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  USERNAME_HAS_BEEN_INSERTED=$($PSQL "INSERT INTO users(name) VALUES('$USERNAME')")
fi
echo -e "\nGuess the secret number between 1 and 1000:"

GUESSING_PROCESS() {
  read GUESSED_NUM
  ((GUESS_COUNT++))
  if ! [[ $GUESSED_NUM =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    GUESSING_PROCESS
  elif [[ $GUESSED_NUM -lt $NUM_TO_GUESS ]]
  then
    echo "It's higher than that, guess again:"
    GUESSING_PROCESS
  elif [[ $GUESSED_NUM -gt $NUM_TO_GUESS ]]
  then
    echo "It's lower than that, guess again:"
    GUESSING_PROCESS
  elif [[ $GUESSED_NUM -eq $NUM_TO_GUESS ]]
  then
    NEW_GAME_COUNT=$((GAMES_PLAYED+1))
    UPDATE_GAME_COUNT=$($PSQL "UPDATE users SET games_played=$NEW_GAME_COUNT WHERE name='$USERNAME'")
    if [[ $BEST_GAME =~ [0-9]+ ]]
    then
      if [[ $GUESS_COUNT -lt $BEST_GAME ]]
      then
        UPDATE_BEST_GAME_DATA=$($PSQL "UPDATE users SET best_game=$GUESS_COUNT WHERE name='$USERNAME'")
        echo $UPDATE_BEST_GAME_DATA
      else
        echo "Your previous best game was $BEST_GAME."
      fi
    else
      UPDATE_BEST_GAME_DATA=$($PSQL "UPDATE users SET best_game=$GUESS_COUNT WHERE name='$USERNAME'")      
    fi
    echo -e "\nYou guessed it in $GUESS_COUNT tries. The secret number was $NUM_TO_GUESS. Nice job!"
    return
  fi
}
GUESSING_PROCESS
