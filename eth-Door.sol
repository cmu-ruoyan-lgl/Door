// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface Token {

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance the balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value)  external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender  , uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Standard_Token is Token {
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public totalSupply;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX

    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string  memory _tokenSymbol) {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(balances[msg.sender] >= _value, "token balance is lower than the value requested");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value, "token balance or allowance is lower than amount requested");
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract Door {
    address public owner;
    mapping(string => Image) public imageMap;
    mapping(address => User) public userMap;
    Image[] public images;
    User[] public users;

    event ReportFalse(string _url, address sender);
    event LikeFalse(string _url, address sender);
    
    enum there{
        nul,
        good,
        bad
    }

    enum city{
        nul,
        shanghai,
        beijing,
        guangzhou,
        shenzhen,
        chengdu,
        shenyang,
        hangzhou,
        xian,
        chongqing,
        tianjin,
        qingdao,
        shijiazhuang,
        haerbin,
        changchun,
        xian,
        yangzhou,
        zhengzhou
    }

    struct Image {
        string url;
        address owner;
        uint value;
        uint good;
        uint bad;
        address[] reporter;
        address[] liker;
        // mapping(address => bool) isReported;
        // mapping(address => bool) isLiked;

        mapping(address => there) isAction;
    }

    struct User {
        address id; // 对应用户的钱包地址
        string[] ownImg; // 用户拥有的图片
        uint money;
    }

    constructor() {
        owner = msg.sender;
    }

    // 上传图片 现在做法好像会有安全问题
    function addImg(string memory _url) external payable{ 
        // Image memory img = Image(_url, msg.sender, 50, 0);
        // users[msg.sender].ownImg.push(img.url);
    }


    // 检查图片是否达到 点赞和点踩的一定比例
    // true：删除图片 false：保留图片
    function checkImg(string memory _url) public view returns(bool f){
        Image storage Img = imageMap[_url];
        if(Img.value == 0) return false;
        address owner = Img.owner;
        uint good = Img.good;
        uint bad = Img.bad;        
        f = bad*2 > good; 
    }


    // 删除图片
    function delImg(string memory _url) public returns(bool f){
        // require(msg.sender == owner, "only owner can delete image");
        // todo:给后端发信息图床删图
        Image storage Img = imageMap[_url];
        if(Img.value == 0) return false;
        
        // owner.have - url
        for(uint i = 0; i < Img.reporter.length; i++) {
            userMap[Img.reporter[i]].money += Img.value / Img.reporter.length;
        }
        // Img.reporter
        // reporter.moner += img.money
        delete imageMap[_url];
        return true;
    }

    // 点赞
    function likeAction(address sender, string memory _url) external returns(bool){
        Image storage Img = imageMap[_url];
        if(Img.value == 0) return false; 
        if(Img.isAction[sender] == there.bad) {
            Img.bad -= 1;
            Img.isAction[sender] = there.good;
        }

        // Img.owner 不会有感觉
        // 

        return true;
    }

    // 举报
    function reportAction(address sender, string memory _url) external returns(bool){
        Image storage Img = imageMap[_url];
        if(Img.value == 0) return false; 

        if(Img.isAction[sender] == there.good) {
            Img.good -= 1;   
            // 删除喜欢的标记
            delete Img.liker
        } 

        Img.good += 1;
        Img.isAction[sender] = there.bad;

        // if(!Img.isReported[sender]) {
        //     Img.reporter.push(sender); 
        //     Img.isReported[sender] = true;
        //     Img
        // }
        // Img.isLiked(sender) = false;
        
        Img.bad += 1;
        checkImg(_url);
        return true;
    }

    // todo：打赏？


}