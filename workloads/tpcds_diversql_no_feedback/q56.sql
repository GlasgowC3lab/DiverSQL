WITH cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    sub.s_store_id,
    sub.s_store_name,
    sub.d_date,
    sub.cs_order_number,
    sub.cs_net_paid,
    sub.ws_order_number,
    sub.ws_net_paid,
    sub.total_sales,
    sub.sale_category,
    sub.rn
FROM (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_sold.d_date,
        cs.cs_order_number,
        cs.cs_net_paid,
        ws.ws_order_number,
        ws.ws_net_paid,
        (cs.cs_net_paid + COALESCE(ws.ws_net_paid, 0)) AS total_sales,
        CASE WHEN cs.cs_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS sale_category,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY (cs.cs_net_paid + COALESCE(ws.ws_net_paid, 0)) DESC) AS rn
    FROM cs_sample cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_sold_date_sk = d_sold.d_date_sk
    WHERE
        d_sold.d_weekend = 'N'
        AND d_sold.d_year = 2001
        AND d_sold.d_date = DATE '2001-01-15'
        AND cs.cs_wholesale_cost > 20
        AND cs.cs_quantity >= 2
        AND s.s_state = 'CA'
        AND w.w_state = 'TX'
        AND (ws.ws_ext_sales_price > 500 OR ws.ws_ext_sales_price IS NULL)
) sub
WHERE sub.rn <= 5
ORDER BY sub.s_store_id, sub.rn
LIMIT 100
