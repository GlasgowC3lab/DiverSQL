WITH shipping_sales AS (
    SELECT
        cs_ship_mode_sk AS ship_mode_sk,
        cs_ext_discount_amt AS discount_amt,
        cs_ext_sales_price AS sales_price,
        cs_net_profit AS profit,
        cs_ship_addr_sk AS ship_addr_sk,
        'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT
        ws_ship_mode_sk,
        ws_ext_discount_amt,
        ws_ext_sales_price,
        ws_net_profit,
        ws_ship_addr_sk,
        'web' AS channel
    FROM web_sales
),
agg_shipping AS (
    SELECT
        ss.ship_mode_sk,
        ss.channel,
        ca.ca_state,
        COUNT(*) AS total_shipments,
        AVG(ss.discount_amt) AS avg_discount_amt,
        AVG(ss.sales_price) AS avg_sales_price,
        AVG(ss.profit) AS avg_profit
    FROM shipping_sales ss
    JOIN customer_address ca ON ss.ship_addr_sk = ca.ca_address_sk
    GROUP BY ss.ship_mode_sk, ss.channel, ca.ca_state
    HAVING COUNT(*) > 10
)
SELECT
    a.ship_mode_sk,
    a.channel,
    a.ca_state,
    a.total_shipments,
    a.avg_discount_amt,
    a.avg_sales_price,
    a.avg_profit,
    CASE
        WHEN a.avg_profit = 0 THEN NULL
        ELSE a.avg_discount_amt / a.avg_profit
    END AS discount_to_profit_ratio,
    CASE
        WHEN a.avg_discount_amt / NULLIF(a.avg_profit, 0) > 0.05 THEN 'Inefficient'
        WHEN a.avg_discount_amt / NULLIF(a.avg_profit, 0) > 0.02 THEN 'Moderate'
        ELSE 'Efficient'
    END AS efficiency_label,
    DENSE_RANK() OVER (PARTITION BY a.channel ORDER BY a.avg_discount_amt DESC) AS discount_rank_channel,
    RANK() OVER (ORDER BY a.avg_discount_amt DESC) AS global_discount_rank
FROM agg_shipping a
ORDER BY a.channel, discount_rank_channel
LIMIT 50
