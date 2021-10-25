const CoordinatesLib = artifacts.require('CoordinatesLib');

contract('CoordinatesLib', (accounts) => {
    it('should split bytes32 in two bytes16', async () => {
        const instance = await CoordinatesLib.deployed();
        const result = await instance.split('0x0123456789012345012345678901234500000000000000000000000000000000');
        assert.equal(result.x, '0x01234567890123450123456789012345')
        assert.equal(result.y, '0x00000000000000000000000000000000')
    });

    it('should extract bytes32 to two coordinates', async () => {
        const instance = await CoordinatesLib.deployed();
        const result = await instance.convertToCoordinates('0x00000000000000000000000000000001ffffffffffffffffffffffffffffffff');
        assert.equal(result.x.toString(10), "1");
        assert.equal(result.y.toString(10), "-1");
    });

    it('should merge two coordinates in one bytes32', async () => {
        const instance = await CoordinatesLib.deployed();
        const result = await instance.convertFromCoordinates(1, -1);
        assert.equal(result, '0x00000000000000000000000000000001ffffffffffffffffffffffffffffffff');
    });
})