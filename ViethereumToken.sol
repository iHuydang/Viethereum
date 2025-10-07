// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // Import Chainlink Oracle

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        require(balances[newOwner] + OWNER_RESERVE <= _totalSupply, "New owner cannot maintain reserve"); // Đảm bảo reserve cho owner mới
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        emit OwnerReserveMaintained(newOwner, OWNER_RESERVE);
    }
}

abstract contract ERC20Basic {
    uint public _totalSupply;
    function totalSupply() public view virtual returns (uint);
    function balanceOf(address who) public view virtual returns (uint);
    function transfer(address to, uint value) public virtual;
    event Transfer(address indexed from, address indexed to, uint value);
}

abstract contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view virtual returns (uint);
    function transferFrom(address from, address to, uint value) public virtual;
    function approve(address spender, uint value) public virtual;
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract BasicToken is Ownable, ERC20Basic {
    mapping(address => uint) public balances;

    uint public basisPointsRate = 0;
    uint public maximumFee = 0;
    uint public constant OWNER_RESERVE = 100_000_000 * 10**18; // Owner luôn giữ 100M token (10% supply)

    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4, "Invalid payload size");
        _;
    }

    modifier maintainOwnerReserve() {
        require(balances[owner] >= OWNER_RESERVE, "Owner reserve below minimum");
        _;
    }

    function transfer(address _to, uint _value) public virtual override onlyPayloadSize(2 * 32) maintainOwnerReserve {
        uint fee = (_value * basisPointsRate) / 10000;
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        uint sendAmount = _value - fee;
        require(balances[msg.sender] >= _value, "Insufficient balance");
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + sendAmount;
        if (fee > 0) {
            balances[owner] = balances[owner] + fee;
            emit Transfer(msg.sender, owner, fee);
        }
        emit Transfer(msg.sender, _to, sendAmount);
    }

    function balanceOf(address _owner) public view virtual override returns (uint balance) {
        return balances[_owner];
    }

    function totalSupply() public view virtual override returns (uint) {
        return _totalSupply;
    }
}

contract StandardToken is BasicToken, ERC20 {
    mapping (address => mapping (address => uint)) public allowed;

    uint public constant MAX_UINT = 2**256 - 1;

    function transferFrom(address _from, address _to, uint _value) public virtual override onlyPayloadSize(3 * 32) maintainOwnerReserve {
        uint _allowance = allowed[_from][msg.sender];

        uint fee = (_value * basisPointsRate) / 10000;
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        if (_allowance < MAX_UINT) {
            require(_allowance >= _value, "Allowance exceeded");
            allowed[_from][msg.sender] = _allowance - _value;
        }
        uint sendAmount = _value - fee;
        require(balances[_from] >= _value, "Insufficient balance");
        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + sendAmount;
        if (fee > 0) {
            balances[owner] = balances[owner] + fee;
            emit Transfer(_from, owner, fee);
        }
        emit Transfer(_from, _to, sendAmount);
    }

    function approve(address _spender, uint _value) public virtual override onlyPayloadSize(2 * 32) {
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)), "Approve: reset allowance to 0 first");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public view virtual override returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract BlackList is Ownable, BasicToken {
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    mapping (address => bool) public isBlackListed;
    
    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    function destroyBlackFunds (address _blackListedUser) public onlyOwner maintainOwnerReserve {
        require(isBlackListed[_blackListedUser], "BlackList: address not blacklisted");
        uint dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
}

abstract contract UpgradedStandardToken is StandardToken{
    function transferByLegacy(address from, address to, uint value) public virtual;
    function transferFromByLegacy(address sender, address from, address spender, uint value) public virtual;
    function approveByLegacy(address from, address spender, uint value) public virtual;
}

contract ViethereumToken is Pausable, StandardToken, BlackList {
    string public name;
    string public symbol;
    uint public decimals;
    address public upgradedAddress;
    bool public deprecated;

    // Peg mechanism
    uint public pegPriceVND = 10000; // 1 VIETH = 10.000 VND
    uint public currentSpreadBasisPoints = 50; // Spread mặc định 0.5%
    address public usdVndOracle; // Chainlink USD/VND aggregator (thay bằng address thực tế trên mainnet/Sepolia)
    AggregatorV3Interface internal priceFeed; // Chainlink price feed
    uint public constant PEG_DEVIATION_THRESHOLD = 100; // Lệch 1% thì adjust
    uint public constant ADJUST_AMOUNT_BASIS = 1_000_000 * 10**18; // Adjust 1M token mỗi lần

    // Events cho peg
    event PegAdjustment(int256 deviation, uint mintedOrBurned, uint newPegPrice);
    event OwnerReserveMaintained(address indexed owner, uint reserveAmount);
    event DepositForPeg(address indexed depositor, uint vndEquivalent, uint mintedTokens);

    constructor(uint _initialSupply, string memory _name, string memory _symbol, uint _decimals, address _usdVndOracle) {
        _totalSupply = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        usdVndOracle = _usdVndOracle;
        priceFeed = AggregatorV3Interface(_usdVndOracle);
        
        // Owner nhận supply trừ reserve (reserve lock cho peg)
        balances[owner] = _initialSupply - OWNER_RESERVE;
        emit OwnerReserveMaintained(owner, OWNER_RESERVE);
        deprecated = false;
    }

    // Lấy giá từ oracle (USD/VND, approx USDT/VND)
    function getLatestVndPrice() public view returns (int) {
        (,int price,,,) = priceFeed.latestRoundData();
        return price; // Giá USD/VND (e.g., 25000)
    }

    // Adjust peg dựa trên spread và oracle price
    function adjustPeg(uint reportedSpreadBasis) public onlyOwner {
        require(reportedSpreadBasis <= 200, "Spread too high"); // Giới hạn spread 2%
        currentSpreadBasisPoints = reportedSpreadBasis;
        
        // Tính giá thị trường VIETH (giả sử dựa on-chain price, hoặc integrate Uniswap TWAP cho real price)
        int vndPrice = getLatestVndPrice(); // ~25.000 VND/USD
        uint marketPriceVND = uint(vndPrice) / 2500; // Approx peg USD equiv (1 VIETH ~0.4 USD -> 10k VND)
        int deviation = int(marketPriceVND) - int(pegPriceVND);
        
        uint adjustAmount = ADJUST_AMOUNT_BASIS;
        if (deviation > int(PEG_DEVIATION_THRESHOLD)) {
            // Overvalued: Burn từ owner reserve (NHNN bán để ổn định)
            require(balances[owner] >= adjustAmount + OWNER_RESERVE, "Cannot burn below reserve");
            _totalSupply -= adjustAmount;
            balances[owner] -= adjustAmount;
            emit PegAdjustment(deviation, adjustAmount, uint(deviation));
        } else if (deviation < -int(PEG_DEVIATION_THRESHOLD)) {
            // Undervalued: Mint vào owner reserve (NHNN mua để dự trữ, thương nhân arbitrage không lỗ vì spread > fee)
            uint newSupply = _totalSupply + adjustAmount;
            require(newSupply > _totalSupply, "Overflow");
            _totalSupply = newSupply;
            balances[owner] += adjustAmount;
            emit PegAdjustment(deviation, adjustAmount, uint(deviation));
        }
        // Adjust fee < spread để thương nhân/NHTM không lỗ arbitrage
        basisPointsRate = reportedSpreadBasisPoints / 2; // Fee = 50% spread
        emit Params(basisPointsRate, maximumFee);
    }

    // Deposit VND equivalent (off-chain verified, e.g., USDT) để mint VIETH (cho NHNN/thương nhân)
    function depositForPeg(address depositor, uint vndEquivalent) public onlyOwner {
        uint mintAmount = vndEquivalent / pegPriceVND; // Mint theo peg
        require(_totalSupply + mintAmount > _totalSupply, "Overflow");
        _totalSupply += mintAmount;
        balances[depositor] += mintAmount;
        emit DepositForPeg(depositor, vndEquivalent, mintAmount);
        emit Transfer(address(0), depositor, mintAmount);
    }

    // Các hàm override giữ nguyên, thêm whenNotPaused và blacklist check
    function transfer(address _to, uint _value) public override(BasicToken, ERC20Basic) whenNotPaused maintainOwnerReserve {
        require(!isBlackListed[msg.sender], "Transfer: sender is blacklisted");
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
        } else {
            return super.transfer(_to, _value);
        }
    }

    function transferFrom(address _from, address _to, uint _value) public override(StandardToken) whenNotPaused maintainOwnerReserve {
        require(!isBlackListed[_from], "TransferFrom: sender is blacklisted");
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }

    // ... (các hàm balanceOf, approve, allowance, deprecate, totalSupply giữ nguyên như cũ)

    function issue(uint amount) public onlyOwner maintainOwnerReserve {
        require(_totalSupply + amount > _totalSupply, "Issue: overflow");
        require(balances[owner] + amount > balances[owner], "Issue: overflow");
        balances[owner] += amount;
        _totalSupply += amount;
        emit Issue(amount);
    }

    function redeem(uint amount) public onlyOwner maintainOwnerReserve {
        require(_totalSupply >= amount, "Redeem: insufficient total supply");
        require(balances[owner] >= amount + OWNER_RESERVE, "Redeem: cannot go below owner reserve"); // Đảm bảo reserve
        _totalSupply -= amount;
        balances[owner] -= amount;
        emit Redeem(amount);
    }

    function setParams(uint newBasisPoints, uint newMaxFee) public onlyOwner maintainOwnerReserve {
        require(newBasisPoints < 20, "SetParams: basis points too high");
        require(newMaxFee < 50, "SetParams: max fee too high");
        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee * (10**decimals);
        emit Params(basisPointsRate, maximumFee);
    }

    // Events
    event Issue(uint amount);
    event Redeem(uint amount);
    event Deprecate(address newAddress);
    event Params(uint feeBasisPoints, uint maxFee);
    event OwnerReserveMaintained(address indexed owner, uint reserveAmount);
    event PegAdjustment(int256 deviation, uint mintedOrBurned, uint newPegPrice);
    event DepositForPeg(address indexed depositor, uint vndEquivalent, uint mintedTokens);
}
