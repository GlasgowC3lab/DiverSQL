WITH
    intersect_items AS (
        SELECT inv_item_sk AS item_sk FROM inventory
        INTERSECT
        SELECT wr_item_sk FROM web_returns
    ),
    inventory_sample AS (
        SELECT *
        FROM inventory
        TABLESAMPLE BERNOULLI (10)
    )
SELECT
    s.s_store_id,
    s.s_store_name,
    d_ship.d_year,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(sr.sr_return_amt) AS total_return_amount,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(cs.cs_net_profit) DESC) AS store_rank,
    ARRAY_AGG(DISTINCT t.word) AS item_description_words
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i_sales ON cs.cs_item_sk = i_sales.i_item_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
FULL OUTER JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    AND sr.sr_returned_date_sk = d_ship.d_date_sk
JOIN item i_sr ON sr.sr_item_sk = i_sr.i_item_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN inventory_sample inv ON inv.inv_item_sk = i_sales.i_item_sk
    AND inv.inv_date_sk = d_sold.d_date_sk
JOIN web_returns wr ON wr.wr_item_sk = i_sales.i_item_sk
    AND wr.wr_returned_date_sk = d_sold.d_date_sk
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN household_demographics hd_wr ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
CROSS JOIN UNNEST(split(i_sales.i_item_desc, ' ')) AS t(word)
WHERE d_sold.d_year = 2001
  AND cs.cs_item_sk IN (SELECT item_sk FROM intersect_items)
  AND NOT EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_item_sk = cs.cs_item_sk
          AND sr2.sr_returned_date_sk = cs.cs_sold_date_sk
    )
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_ship.d_year
ORDER BY store_rank
LIMIT 100
