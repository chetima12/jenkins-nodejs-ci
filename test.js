const { add } = require("./app");

if (add(2, 3) !== 5) {
    throw new Error("Test failed");
}

if (add(10, 20) !== 30) {
    throw new Error("Second addition test failed");
}


console.log("All tests passed!");
