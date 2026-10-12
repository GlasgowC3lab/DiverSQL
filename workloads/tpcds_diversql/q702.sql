/*
  Goal: Produce a per‑ship‑mode sales summary that demonstrates string processing, set subtraction, correlated and uncorrelated scalar subqueries, and multiple DISTINCT aggregates while joining the ship_mode and web_sales Iceberg tables.
*/
WITH ship_modes_to_keep AS (
    /* ship modes that appear in web_sales but are not of type 'REGULAR' */
    SELECT sm.sm_ship_mode_sk
    FROM tpcds.ship_mode sm
    WHERE sm.sm_ship_mode_sk IN (
        SELECT DISTINCT ws.ws_ship_mode_sk FROM tpcds.web_sales ws
    )
    EXCEPT
    SELECT sm.sm_ship_mode_sk FROM tpcds.ship_mode sm WHERE sm.sm_type = 'REGULAR'
),
max_profit AS (
    SELECT MAX(ws.ws_net_profit) AS max_net_profit FROM tpcds.web_sales ws
)
SELECT
    CONCAT(sm.sm_type, ':', sm.sm_code)            AS mode_desc,
    sm.sm_type,
    sm.sm_code,
    COUNT(DISTINCT ws.ws_item_sk)               AS distinct_item_cnt,
    COUNT(DISTINCT ws.ws_bill_customer_sk)      AS distinct_customer_cnt,
    SUM(ws.ws_net_profit)                       AS total_net_profit,
    /* correlated scalar subquery: average list price for the current ship mode */
    (SELECT AVG(ws2.ws_ext_list_price)
       FROM tpcds.web_sales ws2
      WHERE ws2.ws_ship_mode_sk = sm.sm_ship_mode_sk) AS avg_ext_list_price,
    /* indicate whether the contract code contains the letter 'A' */
    CASE WHEN sm.sm_contract LIKE '%A%' THEN 'HAS_A' ELSE 'NO_A' END AS contract_a_flag
FROM tpcds.ship_mode sm
JOIN tpcds.web_sales ws
     ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE
    sm.sm_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_modes_to_keep)               -- set subtraction result
    AND sm.sm_code LIKE 'A%'                                                          -- LIKE pattern
    AND regexp_like(sm.sm_contract, '^.{5}[A-Z]$')                                    -- regexp predicate
    AND ws.ws_wholesale_cost > 50                                                     -- numeric filter
    AND ws.ws_net_profit < (SELECT max_net_profit FROM max_profit)                  -- uncorrelated scalar subquery comparison
    AND EXISTS (
        SELECT 1 FROM tpcds.web_sales ws3
         WHERE ws3.ws_ship_mode_sk = sm.sm_ship_mode_sk
           AND ws3.ws_wholesale_cost > 80
    )                                                                                -- IN/EXISTS subquery
GROUP BY
    sm.sm_type,
    sm.sm_code,
    sm.sm_ship_mode_sk,
    sm.sm_contract
HAVING
    COUNT(*) > 5
ORDER BY
    total_net_profit DESC,
    distinct_customer_cnt ASC
LIMIT 100
