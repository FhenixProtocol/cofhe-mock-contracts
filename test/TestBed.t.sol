// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {TestBed} from "../contracts/TestBed.sol";
import {CoFheTest} from "../contracts/CoFheTest.sol";
import {FHE, InEuint32, euint8} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

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

    function testOverflow() public {
        euint8 a = FHE.asEuint8(240);
        euint8 b = FHE.asEuint8(240);
        euint8 c = FHE.add(a, b);

        assertHashValue(euint8.unwrap(c), (240 + 240) % 256);
    }

    function testDivideByZero() public {
        euint8 a = FHE.asEuint8(240);
        euint8 b = FHE.asEuint8(0);
        euint8 c = FHE.div(a, b);

        assertHashValue(euint8.unwrap(c), type(uint8).max);
    }
}
