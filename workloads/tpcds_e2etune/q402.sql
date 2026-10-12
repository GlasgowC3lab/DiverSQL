WITH market_sales AS (
    SELECT
        s.s_market_id,
        s.s_state,
        w.web_name,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items
    FROM catalog_sales cs
    JOIN store s
        ON cs.cs_warehouse_sk = s.s_store_sk
    JOIN web_site w
        ON s.s_market_id = w.web_mkt_id
    WHERE cs.cs_ext_discount_amt > 500
      AND cs.cs_quantity > 1
      AND cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY s.s_market_id, s.s_state, w.web_name
)
SELECT
    s_market_id,
    s_state,
    web_name,
    total_net_paid_inc_tax,
    total_discount,
    avg_sales_price,
    total_quantity,
    distinct_items,
    RANK() OVER (ORDER BY total_net_paid_inc_tax DESC) AS market_rank
FROM market_sales
ORDER BY market_rank
LIMIT 20
