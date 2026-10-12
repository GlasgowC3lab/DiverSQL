WITH unified_sales AS (
    SELECT
        cs_sold_date_sk AS sold_date_sk,
        cs_item_sk AS item_sk,
        cs_bill_customer_sk AS customer_sk,
        cs_promo_sk AS promo_sk,
        cs_quantity AS quantity,
        cs_ext_sales_price AS ext_sales_price,
        cs_ext_discount_amt AS ext_discount_amt,
        cs_ext_tax AS ext_tax,
        cs_net_paid AS net_paid,
        cs_net_paid_inc_tax AS net_paid_inc_tax,
        cs_net_profit AS net_profit,
        'catalog' AS sales_channel
    FROM catalog_sales
    UNION ALL
    SELECT
        ss_sold_date_sk,
        ss_item_sk,
        ss_customer_sk,
        ss_promo_sk,
        ss_quantity,
        ss_ext_sales_price,
        ss_ext_discount_amt,
        ss_ext_tax,
        ss_net_paid,
        ss_net_paid_inc_tax,
        ss_net_profit,
        'store' AS sales_channel
    FROM store_sales
    UNION ALL
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_bill_customer_sk,
        ws_promo_sk,
        ws_quantity,
        ws_ext_sales_price,
        ws_ext_discount_amt,
        ws_ext_tax,
        ws_net_paid,
        ws_net_paid_inc_tax,
        ws_net_profit,
        'web' AS sales_channel
    FROM web_sales
),
joined_sales AS (
    SELECT
        s.sold_date_sk,
        s.item_sk,
        s.customer_sk,
        s.promo_sk,
        s.quantity,
        s.ext_sales_price,
        s.ext_discount_amt,
        s.ext_tax,
        s.net_paid,
        s.net_paid_inc_tax,
        s.net_profit,
        s.sales_channel,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        c.c_birth_year,
        cd.cd_gender,
        p.p_cost AS promo_cost
    FROM unified_sales s
    JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    LEFT JOIN customer c ON s.customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
),
sales_agg AS (
    SELECT
        d_year,
        d_month_seq,
        i_category,
        i_class,
        i_brand,
        sales_channel,
        cd_gender,
        SUM(ext_sales_price) AS total_sales,
        SUM(ext_discount_amt) AS total_discount,
        SUM(net_profit) AS total_profit,
        SUM(promo_cost) AS total_promo_cost,
        COUNT(DISTINCT item_sk) AS distinct_items_sold,
        COUNT(DISTINCT customer_sk) AS distinct_customers,
        AVG(CASE WHEN ext_sales_price <> 0 THEN ext_discount_amt / ext_sales_price END) AS avg_discount_rate,
        AVG(CASE WHEN c_birth_year IS NOT NULL THEN d_year - c_birth_year END) AS avg_customer_age,
        SUM(quantity) AS total_quantity
    FROM joined_sales
    GROUP BY
        d_year,
        d_month_seq,
        i_category,
        i_class,
        i_brand,
        sales_channel,
        cd_gender
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    i_class,
    i_brand,
    sales_channel,
    cd_gender,
    total_sales,
    total_discount,
    total_profit,
    total_promo_cost,
    distinct_items_sold,
    distinct_customers,
    avg_discount_rate,
    avg_customer_age,
    total_quantity,
    LAG(total_sales) OVER (PARTITION BY sales_channel, i_category, cd_gender ORDER BY d_year, d_month_seq) AS prev_month_sales,
    (total_sales - COALESCE(LAG(total_sales) OVER (PARTITION BY sales_channel, i_category, cd_gender ORDER BY d_year, d_month_seq), 0)) /
        NULLIF(COALESCE(LAG(total_sales) OVER (PARTITION BY sales_channel, i_category, cd_gender ORDER BY d_year, d_month_seq), 0), 0) AS sales_growth_ratio,
    RANK() OVER (PARTITION BY d_year, d_month_seq, sales_channel ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
WHERE d_year BETWEEN 1999 AND 2001
ORDER BY d_year, d_month_seq, sales_channel, profit_rank
LIMIT 200
