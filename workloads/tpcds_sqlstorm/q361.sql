WITH date_filtered AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
),
catalog_sales_agg AS (
    SELECT
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(*) AS total_transactions,
        MIN(cs_sold_date_sk) AS first_sold_date_sk,
        MAX(cs_sold_date_sk) AS last_sold_date_sk
    FROM catalog_sales cs
    JOIN date_filtered df ON cs.cs_sold_date_sk = df.d_date_sk
    GROUP BY cs_bill_customer_sk
),
store_sales_agg AS (
    SELECT
        ss_customer_sk AS customer_sk,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(*) AS total_transactions,
        MIN(ss_sold_date_sk) AS first_sold_date_sk,
        MAX(ss_sold_date_sk) AS last_sold_date_sk
    FROM store_sales ss
    JOIN date_filtered df ON ss.ss_sold_date_sk = df.d_date_sk
    GROUP BY ss_customer_sk
),
web_sales_agg AS (
    SELECT
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(*) AS total_transactions,
        MIN(ws_sold_date_sk) AS first_sold_date_sk,
        MAX(ws_sold_date_sk) AS last_sold_date_sk
    FROM web_sales ws
    JOIN date_filtered df ON ws.ws_sold_date_sk = df.d_date_sk
    GROUP BY ws_bill_customer_sk
),
combined_sales AS (
    SELECT
        customer_sk,
        total_net_profit,
        total_sales,
        total_transactions,
        first_sold_date_sk,
        last_sold_date_sk,
        'catalog' AS sales_channel
    FROM catalog_sales_agg
    UNION ALL
    SELECT
        customer_sk,
        total_net_profit,
        total_sales,
        total_transactions,
        first_sold_date_sk,
        last_sold_date_sk,
        'store' AS sales_channel
    FROM store_sales_agg
    UNION ALL
    SELECT
        customer_sk,
        total_net_profit,
        total_sales,
        total_transactions,
        first_sold_date_sk,
        last_sold_date_sk,
        'web' AS sales_channel
    FROM web_sales_agg
),
customer_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_current_addr_sk,
        COALESCE(c.c_first_name, '') || ' ' || COALESCE(c.c_last_name, '') AS full_name,
        COALESCE(SUM(cs.total_net_profit), 0) AS agg_net_profit,
        COALESCE(SUM(cs.total_sales), 0) AS agg_total_sales,
        COALESCE(SUM(cs.total_transactions), 0) AS agg_transactions,
        MIN(cs.first_sold_date_sk) AS first_purchase_date_sk,
        MAX(cs.last_sold_date_sk) AS last_purchase_date_sk,
        COUNT(DISTINCT cs.sales_channel) AS distinct_channels,
        CASE WHEN c.c_preferred_cust_flag IS NULL OR c.c_preferred_cust_flag = '' THEN 'N' ELSE c.c_preferred_cust_flag END AS preferred_flag,
        (SELECT COUNT(DISTINCT cr.cr_item_sk)
         FROM catalog_returns cr
         WHERE cr.cr_returning_customer_sk = c.c_customer_sk
           AND cr.cr_returned_date_sk IN (SELECT d_date_sk FROM date_filtered)
        ) AS distinct_returned_items
    FROM customer c
    LEFT JOIN combined_sales cs ON c.c_customer_sk = cs.customer_sk
    GROUP BY c.c_customer_sk, c.c_current_addr_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag
),
customer_ranked AS (
    SELECT
        ca.*,
        ROW_NUMBER() OVER (ORDER BY ca.agg_net_profit DESC) AS profit_rank,
        SUM(ca.agg_net_profit) OVER (PARTITION BY ca.preferred_flag) AS net_profit_by_preferred_flag,
        CASE WHEN ca.agg_total_sales > 0 THEN ca.agg_net_profit / ca.agg_total_sales ELSE NULL END AS profit_margin
    FROM customer_agg ca
),
final AS (
    SELECT
        cr.c_customer_sk,
        cr.full_name,
        cr.agg_net_profit,
        cr.agg_total_sales,
        cr.agg_transactions,
        date_first.d_date AS first_purchase_date,
        date_last.d_date AS last_purchase_date,
        cr.distinct_channels,
        cr.preferred_flag,
        cr.distinct_returned_items,
        cr.profit_rank,
        cr.net_profit_by_preferred_flag,
        cr.profit_margin,
        COALESCE(ca_addr.ca_city, 'UNKNOWN') || CASE WHEN ca_addr.ca_state IS NOT NULL THEN ', ' || ca_addr.ca_state ELSE '' END AS location
    FROM customer_ranked cr
    LEFT JOIN date_dim date_first ON cr.first_purchase_date_sk = date_first.d_date_sk
    LEFT JOIN date_dim date_last ON cr.last_purchase_date_sk = date_last.d_date_sk
    LEFT JOIN customer_address ca_addr ON cr.c_current_addr_sk = ca_addr.ca_address_sk
    WHERE cr.agg_net_profit > 0
      AND LOWER(cr.full_name) LIKE '%smith%'
)
SELECT *
FROM final
ORDER BY profit_rank
LIMIT 100
