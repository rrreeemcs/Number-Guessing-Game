#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guessing_game -t --no-align -c"

# Global Variables (random number generation and number of guesses)
RANDOM_NUM=$(($RANDOM % 1000 + 1))
NUM_GUESSES=0

# Checking User Info
CHECK_INFO() {
  echo "Enter your username:"
  read USERNAME
  # Finding user info from user_info
  USER_RESULT=$($PSQL "SELECT games_played, best_game FROM user_info WHERE username = '$USERNAME'")
  echo $USER_RESULT | while IFS="|" read GAMES_PLAYED BEST_GAME
    do
      if [[ -z $USER_RESULT ]]
      then
        # if new user, display new welcome message
        echo "Welcome, $USERNAME! It looks like this is your first time here."
        NEW_USER=$($PSQL "INSERT INTO user_info(username) VALUES('$USERNAME')")
      else
        # otherwise, display user's currents stats
        echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
      fi
      USER_ID=$($PSQL "SELECT user_id FROM user_info WHERE username = '$USERNAME'")
      NEW_GAME=$($PSQL "INSERT INTO game_info(user_id) VALUES($USER_ID)")
    done
  
  # Jumping to getting guess
  echo "Guess the secret number between 1 and 1000:"
  NUMBER_GUESS_GAME
}

# Get guess function -> verifies if integer
NUMBER_GUESS_GAME() {
  read GUESS
  # Using regular expression to check if guess is NOT an integer
  while [[ ! $GUESS =~ ^[0-9]+$ ]]
  do
    echo "That is not an integer, guess again:"
    # ask again
    read GUESS
  done

  # ask for another guess from user -> goes back to GET_GUESS function
  if [[ $GUESS -gt $RANDOM_NUM ]]
  then
    # if greater, state random number is lower
    echo "It's lower than that, guess again:"
    NUM_GUESSES=$(($NUM_GUESSES + 1))
    NUMBER_GUESS_GAME
  elif [[ $GUESS -lt $RANDOM_NUM ]]
  then
    # if less, state random number is higher
    echo "It's higher than that, guess again:"
    NUM_GUESSES=$(($NUM_GUESSES + 1))
    NUMBER_GUESS_GAME
  else 
    NUM_GUESSES=$(($NUM_GUESSES + 1))
    # guess == random number, echo congratulation message & display total number of guesses
    SECRET_NUMBER=$RANDOM_NUM
    echo "You guessed it in $NUM_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

    # Gathering user info after completing their game
    USER_ID=$($PSQL "SELECT user_id FROM user_info WHERE username ='$USERNAME'")
    GAMES_PLAYED=$($PSQL "SELECT games_played FROM user_info WHERE user_id=$USER_ID")
    BEST_GAME=$($PSQL "SELECT best_game FROM user_info WHERE user_id=$USER_ID")
    GAME_ID=$($PSQL "SELECT game_id FROM game_info WHERE user_id=$USER_ID AND num_guesses=0")

    # Incrementing game total and checking if new best score
    NEW_GAME_TOTAL=$(($GAMES_PLAYED + 1))
    if [[ $NUM_GUESSES -lt $BEST_GAME ]]
    then
      NEW_BEST=$NUM_GUESSES
    else
      NEW_BEST=$BEST_GAME
    fi

    # Updating information
    UPDATE_USER_INFO=$($PSQL "UPDATE user_info SET games_played=$NEW_GAME_TOTAL, best_game=$NEW_BEST WHERE user_id=$USER_ID")
    UPDATE_GAME_INFO=$($PSQL "UPDATE game_info SET num_guesses=$NUM_GUESSES, secret_num=$SECRET_NUMBER where game_id=$GAME_ID")
  fi
}

CHECK_INFO