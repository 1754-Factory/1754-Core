// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import {Title} from "@1754-factory/packages/src/ownership/title.sol";

contract TitleFab {
    function newTitle(string memory name, string memory symbol)
        public
        returns (address)
    {
        Title title = new Title(name, symbol);
        title.rely(msg.sender);
        title.deny(address(this));
        return address(title);
    }
}
