// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CoFheTest} from "../contracts/CoFheTest.sol";
import {FHE, euint8, euint32, euint64, euint128, euint256} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

contract FixesTest is Test, CoFheTest {
    function setUp() public {}

    // ================================================================
    // Issue #10: FHE.random should not revert
    // ================================================================

    function testRandomEuint8() public {
        euint8 r = FHE.randomEuint8();
        // Should not revert. Value is derived from blockhash so we just
        // verify it exists in mock storage.
        assertTrue(inMockStorage(euint8.unwrap(r)));
    }

    function testRandomEuint32() public {
        euint32 r = FHE.randomEuint32();
        assertTrue(inMockStorage(euint32.unwrap(r)));
    }

    function testRandomEuint64() public {
        euint64 r = FHE.randomEuint64();
        assertTrue(inMockStorage(euint64.unwrap(r)));
    }

    function testRandomEuint128() public {
        euint128 r = FHE.randomEuint128();
        assertTrue(inMockStorage(euint128.unwrap(r)));
    }

    function testRandomEuint256() public {
        euint256 r = FHE.randomEuint256();
        assertTrue(inMockStorage(euint256.unwrap(r)));
    }

    // ================================================================
    // Issue #11: assertHashValue for euint256
    // ================================================================

    function testAssertHashValueEuint256() public {
        euint256 a = FHE.asEuint256(42);
        assertHashValue(a, 42);
    }

    function testAssertHashValueEuint256WithMessage() public {
        euint256 a = FHE.asEuint256(type(uint256).max);
        assertHashValue(a, type(uint256).max, "euint256 max value mismatch");
    }

    function testAssertHashValueEuint256Zero() public {
        euint256 a = FHE.asEuint256(0);
        assertHashValue(a, 0);
    }

    function testAssertHashValueEuint256Add() public {
        euint256 a = FHE.asEuint256(100);
        euint256 b = FHE.asEuint256(200);
        euint256 c = FHE.add(a, b);
        assertHashValue(c, 300);
    }

    // ================================================================
    // Issue #12: Comparison assertion helpers
    // ================================================================

    function testAssertHashGt() public {
        euint32 a = FHE.asEuint32(100);
        assertHashGt(euint32.unwrap(a), 50);
    }

    function testAssertHashGtWithMessage() public {
        euint32 a = FHE.asEuint32(100);
        assertHashGt(euint32.unwrap(a), 50, "should be greater than 50");
    }

    function testAssertHashGte() public {
        euint32 a = FHE.asEuint32(100);
        assertHashGte(euint32.unwrap(a), 100);
        assertHashGte(euint32.unwrap(a), 50);
    }

    function testAssertHashGteWithMessage() public {
        euint32 a = FHE.asEuint32(100);
        assertHashGte(euint32.unwrap(a), 100, "should be >= 100");
    }

    function testAssertHashLt() public {
        euint32 a = FHE.asEuint32(50);
        assertHashLt(euint32.unwrap(a), 100);
    }

    function testAssertHashLtWithMessage() public {
        euint32 a = FHE.asEuint32(50);
        assertHashLt(euint32.unwrap(a), 100, "should be less than 100");
    }

    function testAssertHashLte() public {
        euint32 a = FHE.asEuint32(100);
        assertHashLte(euint32.unwrap(a), 100);
        assertHashLte(euint32.unwrap(a), 200);
    }

    function testAssertHashLteWithMessage() public {
        euint32 a = FHE.asEuint32(100);
        assertHashLte(euint32.unwrap(a), 100, "should be <= 100");
    }

    function testAssertHashGtEncryptedVsEncrypted() public {
        euint32 a = FHE.asEuint32(200);
        euint32 b = FHE.asEuint32(100);
        assertHashGtEnc(euint32.unwrap(a), euint32.unwrap(b));
    }

    function testAssertHashLtEncryptedVsEncrypted() public {
        euint32 a = FHE.asEuint32(50);
        euint32 b = FHE.asEuint32(100);
        assertHashLtEnc(euint32.unwrap(a), euint32.unwrap(b));
    }

    function testAssertHashGteEncryptedVsEncrypted() public {
        euint32 a = FHE.asEuint32(100);
        euint32 b = FHE.asEuint32(100);
        assertHashGteEnc(euint32.unwrap(a), euint32.unwrap(b));
    }

    function testAssertHashLteEncryptedVsEncrypted() public {
        euint32 a = FHE.asEuint32(100);
        euint32 b = FHE.asEuint32(100);
        assertHashLteEnc(euint32.unwrap(a), euint32.unwrap(b));
    }

    function testComparisonWithFHEArithmetic() public {
        euint32 a = FHE.asEuint32(50);
        euint32 b = FHE.asEuint32(30);
        euint32 sum = FHE.add(a, b);

        // sum = 80, should be > 70 and < 90
        assertHashGt(euint32.unwrap(sum), 70);
        assertHashLt(euint32.unwrap(sum), 90);
        assertHashGte(euint32.unwrap(sum), 80);
        assertHashLte(euint32.unwrap(sum), 80);
        assertHashValue(sum, 80);
    }
}
