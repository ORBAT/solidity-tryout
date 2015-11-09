// Both of these contracts are extremely simplified, and were written for demonstration purposes only, not as
// examples of good coding practices

contract TemperatureOracle {
  mapping (uint => int8) hourlyTemperatures;
  
  address owner;

  function TemperatureOracle() {
    owner = msg.sender;
  }

  function set(int8 temperature) {
    if (owner == msg.sender)
      hourlyTemperatures[now - (now % 3600)] = temperature;
  }

  function get(uint time) constant returns (int8) {
    return hourlyTemperatures[time - (time % 3600)];
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

  TemperatureOracle private tempOracle;

  // end bet and reimburse both bets
  function kill() external {
    // only bettor1 or bettor2 can end the bet
    if(msg.sender != bettor1.addr && msg.sender != bettor2.addr) return;
    bettor1.addr.send(bettor1.value);
    bettor2.addr.send(bettor2.value);
    suicide();
  }

  // Create a new weather bet between bettor1 and bettor2 that will be resolved at _betEndTime
  // using temperature oracle at `_tempOracle`.
  function WeatherBet(uint _betEndTime, address _tempOracle, address _bettor1, address _bettor2) {
    betEndTime = _betEndTime;
    tempOracle = TemperatureOracle(_tempOracle);
    bettor1.addr = _bettor1;
    bettor2.addr = _bettor2;
    bettor1.temperature = 0;
    bettor2.temperature = 0;
  }

  function betOn(int8 temperature) external {
    if(winnerPaid || now > betEndTime) {
      // bet already over, reimburse sent value
      msg.sender.send(msg.value);
      return;
    }
    
    if(msg.sender == bettor1.addr && bettor1.value != 0) {
      // message was sent by bettor 1
      bettor1.temperature = temperature;
      bettor1.value = msg.value;
    } else if(msg.sender == bettor2.addr && bettor2.value != 0) {
      // message was sent by bettor 2
      bettor2.temperature = temperature;
      bettor2.value = msg.value;
    } else {
      // message wasn't sent by either bettor, return the money.
      msg.sender.send(msg.value);
    }
  }

  function abs(int8 n) internal constant returns (int8) {
    if(n >= 0) return n;
    return -n;
  }

  function payWinner() external {
    // the bet still has time left
    if(now < betEndTime) return;
    // the bet's already over and winner has been paid
    if(winnerPaid) return;

    // note that bettor1 or bettor2 may not have bet yet, but we don't
    // check for that to keep the code simple

    int8 temperature = tempOracle.get(betEndTime);

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
  }


  // automatically reimburse all ether that was directly sent to the contract outside of betOn()
  function() {
    msg.sender.send(msg.value);
  }

}