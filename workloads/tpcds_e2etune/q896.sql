WITH store_agg AS (
    SELECT
        i.i_category AS i_category,
        t.t_shift AS t_shift,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txns,
        SUM(ss.ss_sales_price * ss.ss_quantity) AS store_sales,
        SUM(ss.ss_net_profit) AS store_profit
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE
        t.t_shift IN ('Morning', 'Afternoon')
        AND ca.ca_state = 'CA'
        AND ss.ss_sales_price > 20
    GROUP BY
        i.i_category,
        t.t_shift
),
catalog_agg AS (
    SELECT
        i.i_category AS i_category,
        t.t_shift AS t_shift,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        SUM(cs.cs_sales_price * cs.cs_quantity) AS catalog_sales,
        SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE
        t.t_shift IN ('Morning', 'Afternoon')
        AND ca.ca_state = 'CA'
        AND cs.cs_sales_price > 20
    GROUP BY
        i.i_category,
        t.t_shift
)
SELECT
    COALESCE(s.i_category, c.i_category) AS category,
    COALESCE(s.t_shift, c.t_shift) AS shift,
    COALESCE(s.store_sales, 0) AS store_sales,
    COALESCE(c.catalog_sales, 0) AS catalog_sales,
    (COALESCE(s.store_sales, 0) + COALESCE(c.catalog_sales, 0)) AS total_sales,
    COALESCE(s.store_profit, 0) AS store_profit,
    COALESCE(c.catalog_profit, 0) AS catalog_profit,
    COALESCE(s.store_txns, 0) AS store_txns,
    COALESCE(c.catalog_orders, 0) AS catalog_orders,
    (COALESCE(s.store_sales, 0) + COALESCE(c.catalog_sales, 0)) / NULLIF((COALESCE(s.store_txns, 0) + COALESCE(c.catalog_orders, 0)), 0) AS avg_sales_per_order,
    RANK() OVER (PARTITION BY COALESCE(s.t_shift, c.t_shift) ORDER BY (COALESCE(s.store_sales, 0) + COALESCE(c.catalog_sales, 0)) DESC) AS rank_in_shift
FROM store_agg s
FULL OUTER JOIN catalog_agg c
    ON s.i_category = c.i_category
    AND s.t_shift = c.t_shift
WHERE
    (COALESCE(s.store_sales, 0) + COALESCE(c.catalog_sales, 0)) > 20000
ORDER BY
    total_sales DESC
LIMIT 25
