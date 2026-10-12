WITH sales_data AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        'catalog' AS channel,
        cs.cs_item_sk AS item_sk,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_ext_discount_amt AS discount_amount,
        cs.cs_net_profit AS profit,
        cs.cs_sold_time_sk AS time_sk,
        cs.cs_call_center_sk AS call_center_sk,
        cs.cs_promo_sk AS promo_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq,
        'store',
        ss.ss_item_sk,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit,
        ss.ss_sold_time_sk,
        NULL,
        ss.ss_promo_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq,
        'web',
        ws.ws_item_sk,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_sold_time_sk,
        NULL,
        ws.ws_promo_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
),
returns_data AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        'catalog' AS channel,
        cr.cr_item_sk AS item_sk,
        cr.cr_return_amount AS return_amount,
        cr.cr_return_quantity AS return_quantity
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq,
        'store',
        sr.sr_item_sk,
        sr.sr_return_amt,
        sr.sr_return_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq,
        'web',
        wr.wr_item_sk,
        wr.wr_return_amt,
        wr.wr_return_quantity
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
),
item_info AS (
    SELECT
        i_item_sk,
        i_brand,
        i_class,
        i_category,
        i_color,
        i_size,
        i_units
    FROM item
),
promo_info AS (
    SELECT
        p_promo_sk,
        p_discount_active,
        p_promo_name,
        p_cost
    FROM promotion
),
call_center_info AS (
    SELECT
        cc_call_center_sk,
        cc_name,
        cc_state,
        cc_gmt_offset
    FROM call_center
),
time_info AS (
    SELECT
        t_time_sk,
        t_hour,
        t_meal_time
    FROM time_dim
),
sales_agg AS (
    SELECT
        s.d_year,
        s.month_seq,
        s.channel,
        i.i_brand,
        i.i_class,
        i.i_category,
        SUM(s.sales_amount) AS total_sales,
        SUM(s.profit) AS total_profit,
        SUM(s.discount_amount) AS total_discount,
        COUNT(*) AS sales_transactions,
        AVG(t.t_hour) AS avg_hour_of_day,
        COUNT(DISTINCT s.item_sk) AS distinct_items_sold,
        SUM(CASE WHEN s.call_center_sk IS NOT NULL THEN 1 ELSE 0 END) AS sales_with_call_center,
        SUM(COALESCE(p.p_cost, 0)) AS total_promo_cost
    FROM sales_data s
    LEFT JOIN item_info i ON s.item_sk = i.i_item_sk
    LEFT JOIN promo_info p ON s.promo_sk = p.p_promo_sk
    LEFT JOIN call_center_info cc ON s.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN time_info t ON s.time_sk = t.t_time_sk
    GROUP BY
        s.d_year,
        s.month_seq,
        s.channel,
        i.i_brand,
        i.i_class,
        i.i_category
),
returns_agg AS (
    SELECT
        r.d_year,
        r.month_seq,
        r.channel,
        i.i_brand,
        i.i_class,
        i.i_category,
        SUM(r.return_amount) AS total_returns,
        SUM(r.return_quantity) AS total_return_quantity,
        COUNT(*) AS return_transactions
    FROM returns_data r
    LEFT JOIN item_info i ON r.item_sk = i.i_item_sk
    GROUP BY
        r.d_year,
        r.month_seq,
        r.channel,
        i.i_brand,
        i.i_class,
        i.i_category
),
combined AS (
    SELECT
        s.d_year,
        s.month_seq,
        s.channel,
        s.i_brand,
        s.i_class,
        s.i_category,
        s.total_sales,
        s.total_profit,
        s.total_discount,
        s.sales_transactions,
        s.avg_hour_of_day,
        s.distinct_items_sold,
        s.sales_with_call_center,
        s.total_promo_cost,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(r.return_transactions, 0) AS return_transactions,
        CASE WHEN s.total_sales = 0 THEN 0
             ELSE COALESCE(r.total_returns, 0) / s.total_sales END AS return_rate,
        CASE WHEN s.sales_transactions = 0 THEN 0
             ELSE s.total_discount / s.sales_transactions END AS avg_discount_per_txn,
        ROW_NUMBER() OVER (
            PARTITION BY s.d_year, s.month_seq, s.channel
            ORDER BY s.total_profit DESC
        ) AS profit_rank_by_brand_class_category
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.d_year = r.d_year
        AND s.month_seq = r.month_seq
        AND s.channel = r.channel
        AND s.i_brand = r.i_brand
        AND s.i_class = r.i_class
        AND s.i_category = r.i_category
)
SELECT
    d_year,
    month_seq,
    channel,
    i_brand,
    i_class,
    i_category,
    total_sales,
    total_profit,
    total_discount,
    sales_transactions,
    avg_hour_of_day,
    distinct_items_sold,
    sales_with_call_center,
    total_promo_cost,
    total_returns,
    total_return_quantity,
    return_transactions,
    return_rate,
    avg_discount_per_txn,
    profit_rank_by_brand_class_category
FROM combined
WHERE profit_rank_by_brand_class_category <= 5
ORDER BY d_year, month_seq, channel, profit_rank_by_brand_class_category
