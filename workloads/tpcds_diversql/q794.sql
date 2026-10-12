/*
   Goal: Compare store profitability by aggregating sales and return information, applying filters, sampling inventory, using distinct counts, a CASE expression, and set operations (UNION and EXCEPT) to produce a deduplicated ranked list of stores.
*/
WITH joined_data AS (
    SELECT
        ss.ss_quantity,
        ss.ss_net_profit,
        sr.sr_return_quantity,
        s.s_store_name,
        cd.cd_gender,
        i.i_brand,
        CASE WHEN cd.cd_gender = 'M' THEN ss.ss_net_profit ELSE 0 END AS male_profit,
        CASE WHEN cd.cd_gender = 'F' THEN ss.ss_net_profit ELSE 0 END AS female_profit
    FROM store_sales ss
    JOIN time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = ss.ss_item_sk
    JOIN catalog_returns cr
      ON cr.cr_item_sk = i.i_item_sk
     AND cr.cr_returned_time_sk = t.t_time_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN (
        SELECT *
        FROM inventory
        TABLESAMPLE BERNOULLI (10)
    ) AS inv1
      ON inv1.inv_item_sk = i.i_item_sk
     AND inv1.inv_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv2
      ON inv2.inv_item_sk = i.i_item_sk
     AND inv2.inv_warehouse_sk = w.w_warehouse_sk
)
SELECT *
FROM (
    SELECT
        s_store_name,
        SUM(ss_net_profit)                     AS total_profit,
        COUNT(DISTINCT cd_gender)               AS distinct_genders,
        COUNT(DISTINCT i_brand)                 AS distinct_brands,
        SUM(male_profit)                       AS male_profit_total,
        SUM(female_profit)                     AS female_profit_total
    FROM joined_data
    WHERE ss_quantity > 5
    GROUP BY s_store_name

    UNION

    SELECT
        s_store_name,
        SUM(ss_net_profit)                     AS total_profit,
        COUNT(DISTINCT cd_gender)               AS distinct_genders,
        COUNT(DISTINCT i_brand)                 AS distinct_brands,
        SUM(male_profit)                       AS male_profit_total,
        SUM(female_profit)                     AS female_profit_total
    FROM joined_data
    WHERE sr_return_quantity > 2
    GROUP BY s_store_name
) AS unioned
EXCEPT
SELECT
    s_store_name,
    SUM(ss_net_profit)                     AS total_profit,
    COUNT(DISTINCT cd_gender)               AS distinct_genders,
    COUNT(DISTINCT i_brand)                 AS distinct_brands,
    SUM(male_profit)                       AS male_profit_total,
    SUM(female_profit)                     AS female_profit_total
FROM joined_data
GROUP BY s_store_name
HAVING SUM(ss_net_profit) < 0
ORDER BY total_profit DESC
LIMIT 100
