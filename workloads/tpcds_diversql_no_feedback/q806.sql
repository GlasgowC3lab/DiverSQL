/*
Goal: Identify the top‑selling items per web site (limited to the United States state of CA) that have never been returned, compute their net profit after accounting for any returns that did occur, classify profit level, rank them within each site, and return the highest‑profit rows.
The query joins all seven selected tables using only the allowed join keys, applies multiple filter predicates, samples the `item` table, uses an EXCEPT set operation to exclude returned items, incorporates a CASE expression, and employs a window function for ranking.
*/
WITH distinct_sold_items AS (
    SELECT ws_item_sk
    FROM web_sales
    EXCEPT
    SELECT wr_item_sk
    FROM web_returns
),
sampled_items AS (
    SELECT *
    FROM item TABLESAMPLE BERNOULLI (10)
),
sold_items AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        i.i_product_name,
        i.i_current_price,
        p.p_promo_name,
        cd.cd_gender,
        s.web_name,
        s.web_state
    FROM web_sales ws
    JOIN sampled_items i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_site s
        ON ws.ws_web_site_sk = s.web_site_sk
    WHERE i.i_current_price > 20
      AND p.p_channel_event = 'N'
      AND s.web_state = 'CA'
      AND ws.ws_item_sk IN (SELECT ws_item_sk FROM distinct_sold_items)
),
returned_items AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_order_number,
        wr.wr_return_amt
    FROM web_returns wr
    WHERE wr.wr_return_tax > 5
),
inventory_info AS (
    SELECT inv.inv_item_sk, inv.inv_quantity_on_hand
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand > 0
)
SELECT
    si.ws_web_site_sk,
    si.web_name,
    si.i_product_name,
    SUM(si.ws_ext_sales_price) AS total_sales_amount,
    COALESCE(SUM(ri.wr_return_amt), 0) AS total_return_amount,
    SUM(si.ws_net_profit) - COALESCE(SUM(ri.wr_return_amt), 0) AS net_profit,
    CASE WHEN (SUM(si.ws_net_profit) - COALESCE(SUM(ri.wr_return_amt), 0)) > 1000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY si.ws_web_site_sk ORDER BY (SUM(si.ws_net_profit) - COALESCE(SUM(ri.wr_return_amt), 0)) DESC) AS profit_rank
FROM sold_items si
LEFT JOIN returned_items ri
    ON si.ws_order_number = ri.wr_order_number
   AND si.ws_item_sk = ri.wr_item_sk
JOIN inventory_info inv
    ON si.ws_item_sk = inv.inv_item_sk
GROUP BY
    si.ws_web_site_sk,
    si.web_name,
    si.i_product_name
HAVING SUM(si.ws_ext_sales_price) > 500
ORDER BY net_profit DESC
LIMIT 100
