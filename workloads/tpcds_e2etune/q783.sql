WITH sales_agg AS (
    SELECT
        p.p_purpose AS promo_purpose,
        d_sold.d_year AS year,
        d_sold.d_moy AS month,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_category = 'Electronics'
      AND d_sold.d_year = 2000
    GROUP BY p.p_purpose, d_sold.d_year, d_sold.d_moy
),
returns_agg AS (
    SELECT
        p.p_purpose AS promo_purpose,
        d_return.d_year AS year,
        d_return.d_moy AS month,
        SUM(sr.sr_return_quantity) AS total_return_quantity
    FROM store_returns sr
    JOIN date_dim d_return
        ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN item i2
        ON sr.sr_item_sk = i2.i_item_sk
    JOIN promotion p
        ON i2.i_item_sk = p.p_item_sk
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    WHERE i2.i_category = 'Electronics'
      AND d_return.d_date_sk BETWEEN d_start.d_date_sk AND d_end.d_date_sk
      AND d_return.d_year = 2000
    GROUP BY p.p_purpose, d_return.d_year, d_return.d_moy
)
SELECT
    s.promo_purpose,
    s.year,
    s.month,
    s.total_net_profit,
    s.total_quantity_sold,
    s.total_orders,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    (COALESCE(r.total_return_quantity, 0) * 1.0 / NULLIF(s.total_quantity_sold, 0)) AS return_rate,
    (s.total_net_profit / NULLIF(s.total_orders, 0)) AS avg_net_profit_per_order
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.promo_purpose = r.promo_purpose
   AND s.year = r.year
   AND s.month = r.month
WHERE (COALESCE(r.total_return_quantity, 0) * 1.0 / NULLIF(s.total_quantity_sold, 0)) < 0.05
  AND s.total_net_profit > 0
ORDER BY avg_net_profit_per_order DESC
LIMIT 10
