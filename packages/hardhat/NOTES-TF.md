## 12/27
Play functions work
- deploy mocks to run locally
    Can't seem to grab the subscriptionId properly, might not be creating one - might not be emitting event properly so can't grab, not sure  what is going on
- encrypt play choices
- add more getters


### Gameplay
Rock (0) beats Scissors (2):

Player chooses Rock (0), VRFCoordinator chooses Scissors (2).
(0 + 1) % 3 = 1. Since 1 is not equal to 2, the player wins.
Scissors (2) beats Paper (1):

Player chooses Scissors (2), VRFCoordinator chooses Paper (1).
(2 + 1) % 3 = 0. Since 0 is not equal to 1, the player wins.
Paper (1) beats Rock (0):

Player chooses Paper (1), VRFCoordinator chooses Rock (0).
(1 + 1) % 3 = 2. Since 2 is not equal to 0, the player wins.
In each of these cases, the player's move plus one, modulo three, gives a result that is not equal to the VRFCoordinator's move, indicating the player's win.

However, if the VRFCoordinator's move matches this calculation, it means the player loses. For example:

Player chooses Rock (0), VRFCoordinator chooses Paper (1).
(0 + 1) % 3 = 1. Since 1 is equal to 1, the player loses.
This logic is a compact way to determine the outcome of a rock-paper-scissors game without using multiple if-else conditions. The modulo operation ensures that the result cycles through the three possible moves.

## 1/30
Yearn Notes:
    Once a user's liquidity is withdrawn from the yVault, their yVault Token will be burned. yVault Tokens are ERC20, meaning they can be transferred and traded as any other common Ethereum token.