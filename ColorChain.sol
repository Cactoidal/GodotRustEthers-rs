// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract ColorChain {

    struct Color {
        uint16 r;
        uint16 g;
        uint16 b;
    }

    Color public blockColor;

    function setColor(uint16 _r, uint16 _g, uint16 _b) public {
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
