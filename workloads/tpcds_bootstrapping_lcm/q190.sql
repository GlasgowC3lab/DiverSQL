WITH sales_daily AS (
    SELECT
        cs_sold_date_sk AS date_sk,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(cs_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT cs_order_number) AS distinct_orders
    FROM catalog_sales
    GROUP BY cs_sold_date_sk
),
inventory_daily AS (
    SELECT
        inv_date_sk AS date_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand,
        COUNT(DISTINCT inv_item_sk) AS distinct_inventory_items
    FROM inventory
    GROUP BY inv_date_sk
),
store_daily AS (
    SELECT
        s_closed_date_sk AS date_sk,
        COUNT(*) AS closed_store_cnt,
        AVG(s_tax_percentage) AS avg_store_tax_pct
    FROM store
    GROUP BY s_closed_date_sk
),
web_page_creation_daily AS (
    SELECT
        wp_creation_date_sk AS date_sk,
        COUNT(*) AS pages_created,
        COUNT(DISTINCT wp_web_page_sk) AS distinct_pages_created,
        AVG(wp_max_ad_count) AS avg_max_ad_per_page
    FROM web_page
    GROUP BY wp_creation_date_sk
),
web_page_access_daily AS (
    SELECT
        wp_access_date_sk AS date_sk,
        COUNT(*) AS page_accesses,
        COUNT(DISTINCT wp_web_page_sk) AS distinct_pages_accessed
    FROM web_page
    GROUP BY wp_access_date_sk
)
SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    COALESCE(sales_daily.total_net_paid, 0) AS total_net_paid,
    COALESCE(sales_daily.total_net_profit, 0) AS total_net_profit,
    COALESCE(sales_daily.total_discount, 0) AS total_discount,
    COALESCE(sales_daily.distinct_orders, 0) AS distinct_orders,
    COALESCE(inventory_daily.total_quantity_on_hand, 0) AS total_quantity_on_hand,
    COALESCE(inventory_daily.distinct_inventory_items, 0) AS distinct_inventory_items,
    COALESCE(store_daily.closed_store_cnt, 0) AS closed_store_cnt,
    COALESCE(store_daily.avg_store_tax_pct, 0) AS avg_store_tax_pct,
    COALESCE(web_page_creation_daily.pages_created, 0) AS pages_created,
    COALESCE(web_page_creation_daily.distinct_pages_created, 0) AS distinct_pages_created,
    COALESCE(web_page_creation_daily.avg_max_ad_per_page, 0) AS avg_max_ad_per_page,
    COALESCE(web_page_access_daily.page_accesses, 0) AS page_accesses,
    COALESCE(web_page_access_daily.distinct_pages_accessed, 0) AS distinct_pages_accessed,
    ROW_NUMBER() OVER (ORDER BY COALESCE(sales_daily.total_net_paid, 0) DESC) AS sales_rank
FROM date_dim d
LEFT JOIN sales_daily ON sales_daily.date_sk = d.d_date_sk
LEFT JOIN inventory_daily ON inventory_daily.date_sk = d.d_date_sk
LEFT JOIN store_daily ON store_daily.date_sk = d.d_date_sk
LEFT JOIN web_page_creation_daily ON web_page_creation_daily.date_sk = d.d_date_sk
LEFT JOIN web_page_access_daily ON web_page_access_daily.date_sk = d.d_date_sk
WHERE d.d_date IS NOT NULL
ORDER BY total_net_paid DESC
LIMIT 100
