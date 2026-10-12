WITH combined_sales AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_call_center_sk AS call_center_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS profit,
        'catalog' AS sales_channel
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        NULL,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        'store'
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        NULL,
        ws.ws_promo_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        ws.ws_net_profit,
        'web'
    FROM web_sales ws
),
sales_with_dims AS (
    SELECT
        cs.date_sk,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        ca.ca_state,
        ca.ca_country,
        cs.sales_channel,
        cs.sales_amount,
        cs.net_paid,
        cs.profit,
        cs.quantity,
        cs.promo_sk,
        cs.call_center_sk,
        cs.customer_sk,
        COALESCE(p.p_promo_name, 'No Promotion') AS promo_name,
        COALESCE(cc.cc_name, 'N/A') AS call_center_name,
        ROW_NUMBER() OVER (PARTITION BY cs.date_sk, cs.sales_channel ORDER BY cs.sales_amount DESC) AS sales_rank
    FROM combined_sales cs
    LEFT JOIN date_dim d ON cs.date_sk = d.d_date_sk
    LEFT JOIN item i ON cs.item_sk = i.i_item_sk
    LEFT JOIN customer c ON cs.customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN promotion p ON cs.promo_sk = p.p_promo_sk
    LEFT JOIN call_center cc ON cs.call_center_sk = cc.cc_call_center_sk
),
aggregated AS (
    SELECT
        d_year,
        sales_channel,
        i_category,
        i_class,
        SUM(sales_amount) AS total_sales,
        SUM(profit) AS total_profit,
        COUNT(DISTINCT customer_sk) AS distinct_customers,
        AVG(sales_amount) FILTER (WHERE sales_amount > 0) AS avg_sales_per_txn,
        SUM(CASE WHEN sales_rank <= 10 THEN sales_amount ELSE 0 END) AS top_10_sales,
        SUM(CASE WHEN promo_sk IS NOT NULL THEN sales_amount ELSE 0 END) AS promo_sales,
        SUM(sales_amount) FILTER (WHERE profit > 0) AS profitable_sales,
        SUM(sales_amount) FILTER (WHERE profit <= 0) AS loss_sales
    FROM sales_with_dims
    WHERE d_year BETWEEN 1998 AND 2000
      AND i_category IN ('Sports', 'Electronics', 'Books')
    GROUP BY GROUPING SETS (
        (d_year, sales_channel, i_category, i_class),
        (d_year, sales_channel, i_category),
        (d_year, sales_channel),
        (sales_channel, i_category, i_class)
    )
)
SELECT *
FROM aggregated
ORDER BY d_year ASC, sales_channel ASC, total_sales DESC
LIMIT 200
