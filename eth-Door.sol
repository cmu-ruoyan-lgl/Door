// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Door is IERC20, AccessControl{
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) external auth { wards[guy] = 1; }
    function deny(address guy) external auth { wards[guy] = 0; }
    error noAuthorized(address);
    modifier auth{
        if(wards[msg.sender] != 1) revert noAuthorized(msg.sender);
        _;
    }

    // --- AWARD PUNISHMENT VALUES ---
    uint immutable private likeWeight = 5;
    uint immutable private reportWeight = 18;
    uint immutable private visitWeight = 1;
    uint immutable private initGoodValue = 100;
    uint immutable private initBadValue = 100;

    // --- ERC20 Data ---
    string public constant name   = "Doy";
    string public constant symbol = "DOY";
    string public constant version = "1";
    uint8 public decimals = 18;
    uint public totalSupply;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    // --- Token ---
    function mint(address usr, uint value) external auth {
        balanceOf[usr] = add(balanceOf[usr], value);
        totalSupply    = add(totalSupply, value);
        emit Transfer(address(0), usr, value);
    }

    function burn(address usr, uint value) external {
        require(balanceOf[usr] >= value, "User does not have enough balance");
        if (usr != msg.sender && allowance[usr][msg.sender] != type(uint).max) {
            require(allowance[usr][msg.sender] >= value, "Dai/insufficient-allowance");
            allowance[usr][msg.sender] = sub(allowance[usr][msg.sender], value);
        }
        balanceOf[usr] = sub(balanceOf[usr], value);
        totalSupply    = sub(totalSupply, value);
        emit Transfer(usr, address(0), value);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        return transferFrom(msg.sender, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool){
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from, 
        address to, 
        uint256 value
    ) public returns (bool){
        if(value > allowance[from][msg.sender]) return false;
        allowance[from][msg.sender] -= value;
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    // --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    // --- Image Data --- 
    Image[] public images;

    mapping(string => Image) public imageMap;
    mapping(address => mapping(string => bool)) visit; 
    mapping(address => string[]) userImgs;

    event ReportFalse(string _url, address sender);
    event LikeFalse(string _url, address sender);
    error ImageDoesNotExist(string _url);

    enum Attitude{
        nul,
        like,
        dislike
    }

    struct Image {
        string url;
        address owner;
        uint value;
        uint good;
        uint bad;
        address[] reporter;
        address[] liker;
        mapping(address => Attitude) isAction;
    }

    constructor() {
        wards[msg.sender] = 1;
    }

    modifier imageExistenceChecker(string memory _url) {
        Image storage img = imageMap[_url];
        if(img.value == 0) revert ImageDoesNotExist(_url);
        _;
    }

    function createImage(string memory _url ) external { 
        Image storage img = images.push();
        img.url = _url;
        img.owner = msg.sender;
        img.good = 100;
        img.bad = 0;

        userImgs[msg.sender].push(img.url);
    }

    function checkImage(string memory _url) public view imageExistenceChecker(_url) returns(bool f){
        Image storage img = imageMap[_url];
        uint good = img.good;
        uint bad = img.bad;        
        f = bad * 2 > good; 
    }

    function deleteImage(string memory _url) public imageExistenceChecker(_url) returns(bool f){
        Image storage img = imageMap[_url];
        for(uint i = 0; i < img.reporter.length; i++) 
            balanceOf[img.reporter[i]] += img.value / img.reporter.length;
        delete imageMap[_url];
        return true;
    }

    function likeAction(address sender, string memory _url) external imageExistenceChecker(_url) returns(bool){
        Image storage img = imageMap[_url];
        // if(img.value == 0) return false; 
        if(img.isAction[sender] == Attitude.dislike) img.bad -= reportWeight;
        img.good += likeWeight;
        img.isAction[sender] = Attitude.like;
        img.liker.push(msg.sender);
        return true;
    }

    function reportAction(string memory _url) external imageExistenceChecker(_url) returns(bool){
        Image storage img = imageMap[_url];
        if(img.isAction[msg.sender] == Attitude.like) img.good -= likeWeight;   
        img.bad += reportWeight;
        img.isAction[msg.sender] = Attitude.dislike;
        img.reporter.push(msg.sender);
        if(checkImage(_url)) deleteImage(_url);        
        return true;
    }

    function random(uint x, uint y) public view returns(uint num) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.prevrandao,  msg.sender))) % y + x;
    }

    function getRandomUrl() external returns(string memory _url) {
        uint len = images.length;
        uint randIndex;
        uint num = 0;
        
        while(num < 1000) {
            randIndex = random(0, len);
            Image storage image = images[randIndex];
            if(image.value == 0) {
                num ++;
                continue;
            }
            _url = image.url;
            if (visit[msg.sender][_url] == false) {
                visit[msg.sender][_url] = true;
                image.good += 1;
            }
            break;   
        }
    }
}

