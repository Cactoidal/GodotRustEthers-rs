// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract ColorChain {

    struct Color {
        uint r;
        uint g;
        uint b;
    }

    Color public blockColor;

    function setColor(uint _r, uint _g, uint _b) public {
        require(_r >= 0 && _r <= 1000);
        require(_g >= 0 && _g <= 1000);
        require(_b >= 0 && _b <= 1000);
        Color memory newColor;
        newColor.r = _r;
        newColor.g = _g;
        newColor.b = _b;
        blockColor = newColor;
    }

    function getColor() public view returns(Color memory) {
        return blockColor;
    }


}
