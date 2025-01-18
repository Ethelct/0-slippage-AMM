# 0 Slippage Liquidity Pool (AMM)

This project implements a **Custom Automated Market Maker (AMM)** pool that introduces advanced logic to achieve **zero slippage** and **low fees**. The AMM is designed to enhance user experience and capital efficiency, making it suitable for large trades and institutional use.

***Forget about Centralized Exchanges when it comes to whale trades.***

## Key Features
- **Zero Slippage:** Innovative pricing logic ensures minimal or zero slippage for trades.
- **Low Fees:** Optimized fee structure to attract high-volume trades while maintaining profitability.
- **Introducing Intertoken:** You can now launch pools requiring **0** initial liquidity due to the Intertoken logic.
- **Composable Design:** Easily integrates with DeFi protocols, such as lending markets and arbitrage systems.

## How It Works

### Intertoken
The pool is built on the standard AMM model (`x * y = k`) formula. However the pair includes Intertoken.

We've got TokenA, TokenB and Intertoken inside the pool. Without Intertoken, the pair would be TokenA/TokenB, where x = TokenA, y = TokenB and x * y = k (also usually TokenB is a stable coin).

Now the pair is TokenA/Intertoken, where Intertoken is linked 1:1 to TokenB through a minting/burning mechanism.

### Let's go through an example...
Let's say I create X and I want to pair it with USDT 5:1.

I initialize the pool with 5,000,000,000 X and 1,000,000,000 Intertokens. Note that USDT liquidity is still **0**.

#### Swap TokenB for TokenA
Now I can try to swap USDT for X (even though there is no liquidity).

1. USDT is deposited from my wallet to the pool.
2. The fee is applied.
3. The remaining amount is held as USDT liquidity, and the same amount is minted as Intertoken (to remain `x * y = k`)
4. Finally from the AMM model is calculated the X reserve.
5. I get the X amount.

#### Swap TokenA for TokenB
Great, but now it is time to sell X.

1. X is deposited from my wallet to the pool.
2. The fee is applied.
3. The reserve of the remaining amount in USDT is calculated using `x * y = k`.
4. The exact amount of that reserve of Intertokens is burnt
5. I get USDT from the pool.

## Why use Intertoken?
* By controlling the initial liquidity on x * y = k model we can set such a high reserve that practically slippage is 0.

* There is no need for liquidity providers.

* There is no need for initial liquidity amount. Keep your USDT.

## Use Cases
- **Large Trades:** Designed for traders executing high-volume transactions with minimal price impact.
- **Arbitrage:** Attracts arbitrageurs by reducing costs and slippage.
- **Institutional Liquidity Provision:** Optimized for institutional-grade use cases.


# Scalibality
This pool will be scaled to double Intertoken pools that are linked to both tokens of the pool (ex. in an ETH/USDT, there will be (iETH/iUSDT) reserved linked to ETH and USDT liquidity inside the pool).