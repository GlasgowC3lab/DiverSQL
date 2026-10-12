WITH inventory_agg AS (
    SELECT inv_item_sk AS i_item_sk,
           SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    WHERE inv_date_sk BETWEEN 2450815 AND 2451053
    GROUP BY inv_item_sk
),
item_band AS (
    SELECT i.i_category,
           i.i_brand,
           i.i_item_sk,
           ib.ib_income_band_sk,
           ib.ib_lower_bound,
           ib.ib_upper_bound,
           inv_agg.total_quantity_on_hand
    FROM inventory_agg inv_agg
    JOIN item i ON inv_agg.i_item_sk = i.i_item_sk
    JOIN income_band ib ON inv_agg.total_quantity_on_hand BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
),
sales_agg AS (
    SELECT i.i_category,
           i.i_brand,
           ib.ib_income_band_sk,
           SUM(ws.ws_net_profit) AS total_net_profit,
           SUM(ws.ws_quantity) AS total_quantity_sold,
           AVG(ws.ws_ext_discount_amt) AS avg_discount,
           COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN item_band ib ON i.i_item_sk = ib.i_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451053
      AND ws.ws_net_paid > 0
    GROUP BY i.i_category, i.i_brand, ib.ib_income_band_sk
)
SELECT s.i_category,
       s.i_brand,
       s.ib_income_band_sk,
       s.total_net_profit,
       s.total_quantity_sold,
       s.avg_discount,
       s.distinct_customers,
       RANK() OVER (PARTITION BY s.ib_income_band_sk ORDER BY s.total_net_profit DESC) AS profit_rank_within_band
FROM sales_agg s
ORDER BY s.ib_income_band_sk, profit_rank_within_band
LIMIT 100
