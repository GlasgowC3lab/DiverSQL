WITH a AS (
    SELECT
        sr.sr_store_sk,
        s.s_market_id,
        SUM(sr.sr_return_amt_inc_tax) AS total_return,
        ROW_NUMBER() OVER (PARTITION BY s.s_market_id ORDER BY SUM(sr.sr_return_amt_inc_tax) DESC) AS market_rank
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_market_manager = 'Michael Redding'
      AND sr.sr_fee > 10
    GROUP BY sr.sr_store_sk, s.s_market_id
),
 b AS (
    SELECT
        sr.sr_store_sk,
        s.s_market_id,
        SUM(sr.sr_return_amt_inc_tax) AS total_return,
        ROW_NUMBER() OVER (PARTITION BY s.s_market_id ORDER BY SUM(sr.sr_return_amt_inc_tax) DESC) AS market_rank
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_market_manager = 'Dennis Glass'
      AND sr.sr_refunded_cash < 100
    GROUP BY sr.sr_store_sk, s.s_market_id
)
SELECT a.sr_store_sk,
       a.s_market_id,
       a.total_return,
       a.market_rank
FROM a
INTERSECT
SELECT b.sr_store_sk,
       b.s_market_id,
       b.total_return,
       b.market_rank
FROM b
ORDER BY total_return DESC
LIMIT 100
