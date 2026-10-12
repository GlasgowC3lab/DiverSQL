WITH sales_keys AS (
    SELECT ss_store_sk AS store_sk
    FROM store_sales
    WHERE ss_ext_sales_price > 1000
    GROUP BY ss_store_sk
),
returns_keys AS (
    SELECT sr_store_sk AS store_sk
    FROM store_returns
    WHERE sr_return_amt > 500
    GROUP BY sr_store_sk
),
intersect_keys AS (
    SELECT store_sk FROM sales_keys
    INTERSECT
    SELECT store_sk FROM returns_keys
),
exclude_keys AS (
    SELECT sr_store_sk AS store_sk
    FROM store_returns
    WHERE sr_return_amt = 0
    GROUP BY sr_store_sk
),
valid_store_keys AS (
    SELECT store_sk FROM intersect_keys
    EXCEPT
    SELECT store_sk FROM exclude_keys
),
store_agg AS (
    SELECT
        s.s_store_sk,
        s.s_state,
        s.s_city,
        s.s_street_number,
        s.s_street_name,
        CONCAT(s.s_street_number, ' ', s.s_street_name) AS full_address,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(ss.ss_net_profit) - SUM(sr.sr_return_amt) AS net_profit,
        ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY (SUM(ss.ss_net_profit) - SUM(sr.sr_return_amt)) DESC) AS rn,
        LAG((SUM(ss.ss_net_profit) - SUM(sr.sr_return_amt))) OVER (PARTITION BY s.s_state ORDER BY (SUM(ss.ss_net_profit) - SUM(sr.sr_return_amt)) DESC) AS prev_state_profit,
        (
            SELECT SUM(sr3.sr_return_amt)
            FROM store_returns sr3
            WHERE sr3.sr_store_sk = s.s_store_sk
              AND sr3.sr_return_tax > 1.00
        ) AS total_return_tax_amount
    FROM store s
    JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    WHERE s.s_store_sk IN (SELECT store_sk FROM valid_store_keys)
      AND regexp_like(s.s_street_name, '(?i)mill|willow')
      AND s.s_street_name LIKE '%Mill%'
    GROUP BY
        s.s_store_sk,
        s.s_state,
        s.s_city,
        s.s_street_number,
        s.s_street_name
)
SELECT
    s_store_sk,
    s_state,
    s_city,
    full_address,
    total_sales_profit,
    total_return_amount,
    net_profit,
    prev_state_profit,
    total_return_tax_amount
FROM store_agg
WHERE rn <= 5
ORDER BY net_profit DESC
LIMIT 100
