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

  // 0x56f4a306023c0932717d55405d50ce72da2cd688 in test net
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

  function b2() constant returns (int8 temp, address addr, uint value) {
    temp = bettor2.temperature;
    addr = bettor2.addr;
    value = bettor2.value;
    return;
  }

  function b1() constant returns (int8 temp, address addr, uint value) {
    temp = bettor1.temperature;
    addr = bettor1.addr;
    value = bettor1.value;
    return;
  }

  function payWinner() external {
    // the bet still has time left
    if(now < betEndTime) return;
    // the bet's already over and winner has been paid
    if(winnerPaid) return;

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
    return;
  }

  function betOn(int8 temperature) external {
    if(winnerPaid || now > betEndTime) {
      // bet already over, reimburse sent value
      msg.sender.send(msg.value);
      return;
    }
    
    if(msg.sender == bettor1.addr) {
      // message was sent by bettor 1
      bettor1.temperature = temperature;
      bettor1.value = msg.value;
    } else if(msg.sender == bettor2.addr) {      
      // message was sent by bettor 1
      bettor2.temperature = temperature;
      bettor2.value = msg.value;
    } else {
      // message wasn't sent by either bettor, return the money.
      msg.sender.send(msg.value);
    }
  }
}