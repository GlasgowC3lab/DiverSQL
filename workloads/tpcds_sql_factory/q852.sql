WITH unified_sales AS (
    SELECT
        cs_item_sk AS item_sk,
        cs_sold_date_sk AS sold_date_sk,
        cs_ext_sales_price AS sales_price,
        cs_ext_discount_amt AS discount_amt,
        cs_ext_list_price AS list_price,
        cs_net_profit AS net_profit,
        cs_ship_addr_sk AS ship_addr_sk,
        cs_bill_customer_sk AS customer_sk,
        'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT
        ws_item_sk,
        ws_sold_date_sk,
        ws_ext_sales_price,
        ws_ext_discount_amt,
        ws_ext_list_price,
        ws_net_profit,
        ws_ship_addr_sk,
        ws_bill_customer_sk,
        'web' AS channel
    FROM web_sales
),
agg_sales AS (
    SELECT
        us.item_sk,
        us.sold_date_sk,
        us.channel,
        ca.ca_state,
        SUM(us.sales_price) AS total_sales,
        SUM(us.discount_amt) AS total_discount,
        SUM(us.net_profit) AS total_profit,
        AVG(us.discount_amt / NULLIF(us.list_price, 0)) AS avg_discount_rate
    FROM unified_sales us
    JOIN customer_address ca ON us.ship_addr_sk = ca.ca_address_sk
    JOIN customer c ON us.customer_sk = c.c_customer_sk
    GROUP BY us.item_sk, us.sold_date_sk, us.channel, ca.ca_state
    HAVING SUM(us.sales_price) > 0
)
SELECT
    a.item_sk,
    a.sold_date_sk,
    a.channel,
    a.ca_state,
    a.total_sales,
    a.total_discount,
    a.total_profit,
    a.avg_discount_rate,
    CASE
        WHEN a.avg_discount_rate > 0.3 THEN 'High Discount'
        WHEN a.avg_discount_rate > 0.1 THEN 'Medium Discount'
        ELSE 'Low Discount'
    END AS discount_category,
    RANK() OVER (PARTITION BY a.sold_date_sk ORDER BY a.total_profit DESC) AS profit_rank_month,
    DENSE_RANK() OVER (ORDER BY a.total_profit DESC) AS global_profit_rank
FROM agg_sales a
ORDER BY a.sold_date_sk, profit_rank_month
LIMIT 100
