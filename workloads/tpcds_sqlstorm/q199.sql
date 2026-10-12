WITH c_sales AS (
    SELECT
        cs_sold_date_sk AS date_sk,
        cs_item_sk AS item_sk,
        cs_bill_customer_sk AS customer_sk,
        cs_ext_sales_price AS sales_amount,
        cs_ext_discount_amt AS discount_amount,
        cs_net_profit AS profit,
        cs_promo_sk AS promo_sk,
        'catalog' AS channel
    FROM catalog_sales
),
s_sales AS (
    SELECT
        ss_sold_date_sk AS date_sk,
        ss_item_sk AS item_sk,
        ss_customer_sk AS customer_sk,
        ss_ext_sales_price AS sales_amount,
        ss_ext_discount_amt AS discount_amount,
        ss_net_profit AS profit,
        ss_promo_sk AS promo_sk,
        'store' AS channel
    FROM store_sales
),
w_sales AS (
    SELECT
        ws_sold_date_sk AS date_sk,
        ws_item_sk AS item_sk,
        ws_bill_customer_sk AS customer_sk,
        ws_ext_sales_price AS sales_amount,
        ws_ext_discount_amt AS discount_amount,
        ws_net_profit AS profit,
        ws_promo_sk AS promo_sk,
        'web' AS channel
    FROM web_sales
),
all_sales_raw AS (
    SELECT * FROM c_sales
    UNION ALL
    SELECT * FROM s_sales
    UNION ALL
    SELECT * FROM w_sales
),
promo_join AS (
    SELECT
        s.*,
        CASE WHEN p.p_promo_sk IS NOT NULL THEN 1 ELSE 0 END AS promo_active
    FROM all_sales_raw s
    LEFT JOIN promotion p
        ON s.promo_sk = p.p_promo_sk
        AND s.date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
),
sales_enriched AS (
    SELECT
        s.*,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class
    FROM promo_join s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
),
monthly_metrics AS (
    SELECT
        d_year,
        d_month_seq,
        i_category,
        i_class,
        channel,
        promo_active,
        SUM(sales_amount) AS total_sales,
        SUM(profit) AS total_profit,
        COUNT(DISTINCT customer_sk) AS unique_customers,
        AVG(discount_amount) AS avg_discount,
        approx_percentile(sales_amount, 0.5) AS median_sales
    FROM sales_enriched
    GROUP BY ROLLUP (d_year, d_month_seq, i_category, i_class, channel, promo_active)
    HAVING COALESCE(SUM(sales_amount), 0) > 0
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    i_class,
    channel,
    promo_active,
    total_sales,
    total_profit,
    unique_customers,
    avg_discount,
    median_sales,
    ROW_NUMBER() OVER (PARTITION BY d_year, channel ORDER BY total_sales DESC) AS rank_by_sales,
    AVG(total_sales) OVER (
        PARTITION BY i_category, channel
        ORDER BY d_year, d_month_seq
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS three_month_rolling_avg_sales
FROM monthly_metrics
ORDER BY d_year, d_month_seq, i_category, channel, total_sales DESC
