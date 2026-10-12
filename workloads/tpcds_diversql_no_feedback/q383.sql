WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451545 AND 2451580
    GROUP BY i.i_item_sk, i.i_product_name
)
SELECT
    u.sales_channel,
    u.date_key,
    u.net_paid,
    u.i_product_name,
    u.i_category,
    u.distinct_orders,
    u.distinct_sales_price_sum,
    dim.cp_catalog_page_id,
    dim.cp_department,
    isales.total_catalog_sales,
    isales.distinct_customers
FROM (
    SELECT
        'catalog' AS sales_channel,
        cs.cs_sold_date_sk AS date_key,
        cs.cs_net_paid AS net_paid,
        i.i_product_name,
        i.i_category,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(DISTINCT cs.cs_ext_sales_price) AS distinct_sales_price_sum,
        i.i_item_sk
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451545 AND 2451547
    GROUP BY cs.cs_sold_date_sk, cs.cs_net_paid, i.i_product_name, i.i_category, i.i_item_sk

    UNION ALL

    SELECT
        'store' AS sales_channel,
        ss.ss_sold_date_sk AS date_key,
        ss.ss_net_paid AS net_paid,
        i.i_product_name,
        i.i_category,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_orders,
        SUM(DISTINCT ss.ss_ext_sales_price) AS distinct_sales_price_sum,
        i.i_item_sk
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451547
    GROUP BY ss.ss_sold_date_sk, ss.ss_net_paid, i.i_product_name, i.i_category, i.i_item_sk
) u
CROSS JOIN (
    SELECT cp.cp_catalog_page_id, cp.cp_department
    FROM catalog_page cp
    WHERE cp.cp_catalog_page_number <= 5
) dim
LEFT JOIN item_sales isales ON isales.i_item_sk = u.i_item_sk
LIMIT 100
