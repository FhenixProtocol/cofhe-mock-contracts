// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {TestBed} from "../contracts/TestBed.sol";
import {CoFheTest} from "../contracts/CoFheTest.sol";
import {FHE, InEuint32} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

contract TestBedTest is Test, CoFheTest {

    TestBed private testbed;

    address private user = makeAddr("user");

    function setUp() public {
        // optional ... enable verbose logging from fhe mocks
        // setLog(true);

        testbed = new TestBed();
    }

    function testSetNumberFuzz(uint32 n) public {
        InEuint32 memory number = createInEuint32(n, user);

        //must be the user who sends transaction
        //or else invalid permissions from fhe allow
        vm.prank(user);
        testbed.setNumber(number);

        assertHashValue(testbed.eNumber(), n);
    }
}
