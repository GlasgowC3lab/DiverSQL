WITH unified_sales AS (
    SELECT
        ss_sold_date_sk AS sold_date_sk,
        ss_sold_time_sk AS sold_time_sk,
        ss_item_sk AS item_sk,
        ss_store_sk AS store_sk,
        ss_customer_sk AS cust_sk,
        'store' AS sales_channel,
        ss_quantity AS quantity,
        ss_ext_sales_price AS ext_sales_price,
        ss_ext_discount_amt AS ext_discount_amt,
        ss_ext_tax AS ext_tax,
        ss_net_profit AS net_profit,
        ss_promo_sk AS promo_sk
    FROM store_sales
    UNION ALL
    SELECT
        cs_sold_date_sk,
        cs_sold_time_sk,
        cs_item_sk,
        CAST(NULL AS integer) AS store_sk,
        cs_bill_customer_sk AS cust_sk,
        'catalog' AS sales_channel,
        cs_quantity,
        cs_ext_sales_price,
        cs_ext_discount_amt,
        cs_ext_tax,
        cs_net_profit,
        cs_promo_sk
    FROM catalog_sales
    UNION ALL
    SELECT
        ws_sold_date_sk,
        ws_sold_time_sk,
        ws_item_sk,
        CAST(NULL AS integer) AS store_sk,
        ws_bill_customer_sk AS cust_sk,
        'web' AS sales_channel,
        ws_quantity,
        ws_ext_sales_price,
        ws_ext_discount_amt,
        ws_ext_tax,
        ws_net_profit,
        ws_promo_sk
    FROM web_sales
),
monthly_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        COALESCE(s.s_store_id, 'ALL') AS store_id,
        i.i_category,
        i.i_brand,
        SUM(us.net_profit) AS total_net_profit,
        SUM(us.ext_sales_price) AS total_sales,
        SUM(us.quantity) AS total_quantity,
        AVG(CASE WHEN us.ext_sales_price > 0 THEN us.ext_discount_amt / us.ext_sales_price END) AS avg_discount_ratio,
        COUNT(DISTINCT us.item_sk) AS distinct_items_sold,
        COUNT(DISTINCT us.cust_sk) AS distinct_customers,
        approx_distinct(us.cust_sk) AS approx_distinct_customers
    FROM unified_sales us
    JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
    LEFT JOIN store s ON us.store_sk = s.s_store_sk
    JOIN item i ON us.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY
        d.d_year,
        d.d_month_seq,
        COALESCE(s.s_store_id, 'ALL'),
        i.i_category,
        i.i_brand
),
hourly_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        COALESCE(s.s_store_id, 'ALL') AS store_id,
        t.t_hour,
        SUM(us.net_profit) AS hour_net_profit,
        SUM(us.ext_sales_price) AS hour_sales,
        COUNT(*) AS hour_txn_count
    FROM unified_sales us
    JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
    LEFT JOIN store s ON us.store_sk = s.s_store_sk
    JOIN time_dim t ON us.sold_time_sk = t.t_time_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY
        d.d_year,
        d.d_month_seq,
        COALESCE(s.s_store_id, 'ALL'),
        t.t_hour
),
ranked AS (
    SELECT
        a.*,
        ROW_NUMBER() OVER (PARTITION BY a.store_id, a.d_year, a.d_month_seq ORDER BY a.total_net_profit DESC) AS profit_rank,
        PERCENT_RANK() OVER (PARTITION BY a.store_id ORDER BY a.total_net_profit) AS profit_percentile
    FROM monthly_agg a
),
moving_avg AS (
    SELECT
        r.*,
        SUM(r.total_net_profit) OVER (PARTITION BY r.store_id ORDER BY r.d_year, r.d_month_seq ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS profit_5_month_moving_sum
    FROM ranked r
)

SELECT
    m.d_year,
    m.d_month_seq,
    m.store_id,
    m.i_category,
    m.i_brand,
    m.total_net_profit,
    m.total_sales,
    m.total_quantity,
    m.avg_discount_ratio,
    m.distinct_items_sold,
    m.distinct_customers,
    m.approx_distinct_customers,
    m.profit_rank,
    m.profit_percentile,
    m.profit_5_month_moving_sum,
    hh.peak_hour_net_profit
FROM moving_avg m
LEFT JOIN (
    SELECT
        d_year,
        d_month_seq,
        store_id,
        MAX(hour_net_profit) AS peak_hour_net_profit
    FROM hourly_agg
    GROUP BY d_year, d_month_seq, store_id
) hh
ON m.d_year = hh.d_year AND m.d_month_seq = hh.d_month_seq AND m.store_id = hh.store_id
WHERE m.profit_rank <= 5
ORDER BY m.d_year, m.d_month_seq, m.store_id, m.profit_rank
