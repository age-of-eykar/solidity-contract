const Eykar = artifacts.require('Eykar');
const CoordinatesLib = artifacts.require('CoordinatesLib');

contract('Eykar', (accounts) => {

    it('should convert an id to a location on the spawn spiral', async () => {
        const coordinatesLib = await CoordinatesLib.deployed();
        const instance = await Eykar.deployed();

        for (let i = 0; i < 10; i++) {
            const result = await instance.findNextLocationOnSpiral(i, 3);
            const deserialized = await coordinatesLib.convertToCoordinates(result.location);
            assert.equal(deserialized.x.toNumber(), [0, 3, 3, 3, 0, -3, -3, -3, 0, 6][i]);
            assert.equal(deserialized.y.toNumber(), [0, 3, 0, -3, -3, -3, 0, 3, 3, 6][i]);
        }
    });

    it('should create and read colonies', async () => {
        const coordinatesLib = await CoordinatesLib.deployed();
        const instance = await Eykar.deployed();

        await instance.register("First player", { from: accounts[0] });
        const colonies = await instance.getColonies.call(accounts[0]);
        console.log(colonies);
    });

})