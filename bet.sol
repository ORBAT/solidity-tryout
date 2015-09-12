contract TemperatureOracle {
  mapping (uint => int8) hourlyTemperatures;

  address owner;
  uint256 fee;

  function TemperatureOracle(uint256 _fee) {
      owner = msg.sender;
      fee = _fee;
  }

  function set(int8 temperature) {
      if (owner == msg.sender)
          hourlyTemperatures[now - (now % 3600)] = temperature;
  }

  function setFee(uint256 f) {
      if (owner == msg.sender)
          fee = f;
  }

  function get(uint time) returns (int8 v) {
      if (msg.value >= fee)
          v = hourlyTemperatures[time - (time % 3600)];
      else
          v = 0;
  }

  function getFee() constant returns (uint256) {
      return fee;
  }
}


contract WeatherBet {

  struct Bettor {
    address addr;
    int8 temperature;
    uint value;
  }

  bool private winnerPaid;
  
  Bettor private bettor1;
  Bettor private bettor2;

  uint private betEndTime;

  // 0xa7c8b790c94c496894ec617208aee8be48519dda in test net
  TemperatureOracle private tempOracle;

  function abs(int8 n) internal constant returns (int8) {
    if(n >= 0) return n;
    return -n;
  }

  // end bet and reimburse both bets
  function kill() external {
    if(msg.sender != bettor1.addr && msg.sender != bettor2.addr) return;
    bettor1.addr.send(bettor1.value);
    bettor2.addr.send(bettor2.value);
    suicide(msg.sender);
  }

  /// @notice Will create a new weather bet between `bettor1` and `bettor2` 
  /// that will be resolved at `_betEndTime` using temperature oracle at `_tempOracle`.
  function WeatherBet(uint _betEndTime, address _tempOracle, address bettor1, address bettor2) {
    betEndTime = _betEndTime;
    tempOracle = TemperatureOracle(_tempOracle);
    bettor1.addr = bettor1;
    bettor2.addr = bettor2;
  }

  function isBetOver() constant returns (bool) {
    return winnerPaid;
  }

  function payWinner() external {
    // the bet still has time left
    if(now < betEndTime) return;
    // the bet's already over and winner has been paid
    if(winnerPaid) return;

    int8 temperature = tempOracle.getTemperature(betEndTime);

    int8 bet1Diff = abs(temperature - bettor1.temperature);
    int8 bet2Diff = abs(temperature - bettor2.temperature);
    
    // the winner gets the whole balance of the contract
    uint payOut = address(this).balance;

    // both bets are equally close, reimburse bets
    if(bet1Diff == bet2Diff) {
      bettor1.addr.send(bettor1.value);
      bettor2.addr.send(bettor2.value);
    // bet 1 is closer
    } else if(bet1Diff < bet2Diff) {
      bettor1.addr.send(payOut);
    // bet 2 must be the closest
    } else {
      bettor2.addr.send(payOut);
    }
    
    winnerPaid = true;
    return;
  }

  function betOn(int8 temperature) external {
    // bet already over, reimburse sent value
    if(winnerPaid) {
      msg.sender.send(msg.value);
      return;
    }
    
    // message was sent by bettor 1
    if(msg.sender == bettor1.addr) {
      
      // bettor 1 has already made a bet
      if(bettor1.temperature != 0) {
        msg.sender.send(msg.value);
        return;
      }

      bettor1.temperature = temperature;
      bettor1.value = msg.value;
    // message was sent by bettor 1
    } else if(msg.sender == bettor2.addr) {
      
      // bettor 2 has already made a bet
      if(bettor2.temperature != 0) {
        msg.sender.send(msg.value);
        return;
      }

      bettor2.temperature = temperature;
      bettor2.value = msg.value;
    }
    // message wasn't sent by either bettor, return the money.
    msg.sender.send(msg.value);
  }
}