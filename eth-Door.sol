// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";

contract Door is IERC20{
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Doy";
    string public symbol = "DOY";
    uint public decimals = 18;

    function transfer(address to, uint256 value) external returns (bool) {
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
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
    ) external returns (bool){
        if(value > allowance[from][msg.sender]) return false;
        allowance[from][msg.sender] -= value;
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    address public owner;
    mapping(string => Image) public imageMap;
    mapping(address => User) public userMap;
    // mapping

    Image[] public images;
    User[] public users;

    enum Attitude{
        nul,
        like,
        dislike
    }

    event ReportFalse(string _url, address sender);
    event LikeFalse(string _url, address sender);
    error ImageDoesNotExist(string _url);

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

    struct User {
        address id; // 对应用户的钱包地址
        string[] ownimg; // 用户拥有的图片
        uint money;
        mapping(string => bool) visit;
    }

    constructor() {
        owner = msg.sender;
    }

    modifier userChecker() {
        User storage user = userMap[msg.sender];
        if(user.id == address(0)) {
            user.id = msg.sender;
        }
        _;
    }

    modifier imageExistenceChecker(string memory _url) {
        Image storage img = imageMap[_url];
        if(img.value == 0) revert ImageDoesNotExist(_url);
        _;
    }


    // 这个方法传参数后面要加图片的格式！！！
    function uploadImage() public userChecker returns(string memory _url) {
        // todo:上传图床功能
        // string memory _url = 上传图床();
    }

    // 上传图片 现在做法好像会有安全问题
    // 这个方法传参数后面要加图片的格式！！！
    function addimg() external userChecker returns(bool f) { 
        string memory _url = uploadImage();

        // 将图放到合约中图库
        Image storage img = images.push();
        img.url = _url;
        img.owner = msg.sender;
        img.good = 50;
        img.bad = 0;

        // images.push(img);
        // 注册用户持有图片
        userMap[msg.sender].ownimg.push(img.url);
    }


    // 检查图片是否达到 点赞和点踩的一定比例
    // true：要求删除图片 false：要求保留图片
    function checkimg(string memory _url) public view imageExistenceChecker(_url) returns(bool f){
        Image storage img = imageMap[_url];
        // if(img.value == 0) return false;
        // // address owner = img.owner;
        uint good = img.good;
        uint bad = img.bad;        
        f = bad * 2 > good; 
    }


    // 删除图片
    function delimg(string memory _url) public imageExistenceChecker(_url) returns(bool f){
        // require(msg.sender == owner, "only owner can delete image");
        // todo:给后端发信息图床删图
        Image storage img = imageMap[_url];
        // if(img.value == 0) return false;
        
        // owner.have - url
        for(uint i = 0; i < img.reporter.length; i++) {
            userMap[img.reporter[i]].money += img.value / img.reporter.length;
        }
        // img.reporter
        // reporter.moner += img.money
        delete imageMap[_url];
        return true;
    }

    // 点赞
    function likeAction(address sender, string memory _url) external userChecker imageExistenceChecker(_url) returns(bool){
        Image storage img = imageMap[_url];
        // if(img.value == 0) return false; 
        if(img.isAction[sender] == Attitude.dislike) {
            img.bad -= 1;
        }
        img.good += 1;
        img.isAction[sender] = Attitude.like;
        img.liker.push(msg.sender);
        return true;
    }

    // 举报
    function reportAction(string memory _url) external userChecker imageExistenceChecker(_url) returns(bool){
        Image storage img = imageMap[_url];
        // User storage user = userMap[msg.sender];
        if(img.value == 0) return false; 
        // 处理由点赞变成点踩的用户
        if(img.isAction[msg.sender] == Attitude.like) {
            img.good -= 1;   
            // 删除喜欢的标记 -todo：目前没找到合适的数据结构
            // delete img.like[]
        } 
        img.bad += 1;
        img.isAction[msg.sender] = Attitude.dislike;
        img.reporter.push(msg.sender);

        if(checkimg(_url)) {
            delimg(_url);
        }
        return true;
    }

    function random(uint x, uint y) public view returns(uint num) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  msg.sender))) % y + x;
    }

    function getRandomUrl() external userChecker returns(string memory _url) {
        // msg.sender
        // images
        uint len = images.length;
        uint randIndex;
        User storage user = userMap[msg.sender];
        while(true) {
            randIndex = random(0, len);
            Image storage image = images[randIndex];
            if(image.value == 0) {
                continue;
            }
            _url = image.url;
            if(user.visit[_url] == false) {
                user.visit[_url] = true;
                image.good += random(0, 4) / 10;
            }
            break;   
        }
    }

    // 转账功能 
    // transfer 引用合约20实现


    // todo：打赏？

}

/*
// 每个城市的限制100个 
每个省份限制100个，采用web前端获取用户ip判断所在地实现

*/

contract DoorCityNFT {
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
        yangzhou,
        zhengzhou
    }
}

/*

用户登陆就是能用用户的钱包调用合约！！！

todo task list
- 随机访问 finished
- 上传图床

- 所有城市的拼音名称 
*/
