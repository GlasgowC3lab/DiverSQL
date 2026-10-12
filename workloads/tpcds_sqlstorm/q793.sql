WITH
store_agg AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        ss.ss_sold_date_sk AS date_sk,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(*) AS store_txn_count,
        MAX(ss.ss_sold_date_sk) AS max_date_sk
    FROM store_sales ss
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
        AND ss.ss_sold_date_sk = sr.sr_returned_date_sk
    WHERE ss.ss_quantity > 0
    GROUP BY ss.ss_item_sk, ss.ss_sold_date_sk
),
catalog_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        cs.cs_sold_date_sk AS date_sk,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(*) AS catalog_txn_count
    FROM catalog_sales cs
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
        AND cs.cs_sold_date_sk = cr.cr_returned_date_sk
    WHERE cs.cs_quantity > 0
    GROUP BY cs.cs_item_sk, cs.cs_sold_date_sk
),
web_agg AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        ws.ws_sold_date_sk AS date_sk,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(*) AS web_txn_count
    FROM web_sales ws
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
        AND ws.ws_sold_date_sk = wr.wr_returned_date_sk
    WHERE ws.ws_quantity > 0
    GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk
),
combined_sales AS (
    SELECT
        COALESCE(s.item_sk, c.item_sk, w.item_sk) AS item_sk,
        COALESCE(s.date_sk, c.date_sk, w.date_sk) AS date_sk,
        COALESCE(s.store_net_paid, 0) + COALESCE(c.catalog_net_paid, 0) + COALESCE(w.web_net_paid, 0) AS total_net_paid,
        COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0) AS total_net_profit,
        COALESCE(s.store_txn_count, 0) + COALESCE(c.catalog_txn_count, 0) + COALESCE(w.web_txn_count, 0) AS total_txn_count,
        s.store_txn_count,
        c.catalog_txn_count,
        w.web_txn_count
    FROM store_agg s
    FULL OUTER JOIN catalog_agg c
        ON s.item_sk = c.item_sk AND s.date_sk = c.date_sk
    FULL OUTER JOIN web_agg w
        ON COALESCE(s.item_sk, c.item_sk) = w.item_sk AND COALESCE(s.date_sk, c.date_sk) = w.date_sk
),
item_detail AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        i.i_size,
        i.i_color,
        i.i_manager_id,
        CONCAT(i.i_category, '-', i.i_brand) AS cat_brand_key,
        COALESCE(i.i_color, 'UNKNOWN') AS item_color
    FROM item i
),
date_detail AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        d.d_week_seq,
        d.d_quarter_seq
    FROM date_dim d
    WHERE d.d_year BETWEEN 2000 AND 2002
),
promo_detail AS (
    SELECT
        p.p_promo_sk,
        p.p_item_sk,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_discount_active,
        CASE
            WHEN p.p_promo_name IS NULL THEN 'NO_PROMO'
            ELSE p.p_promo_name
        END AS promo_name
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
),
filtered_sales AS (
    SELECT
        cs.item_sk,
        cs.date_sk,
        cs.total_net_paid,
        cs.total_net_profit,
        cs.total_txn_count,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        i.cat_brand_key,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        pd.promo_name,
        CASE
            WHEN cs.total_net_paid = 0 THEN NULL
            ELSE cs.total_net_profit / nullif(cs.total_net_paid, 0)
        END AS profit_margin,
        CASE
            WHEN cs.total_txn_count >= 100 THEN 1 ELSE 0
        END AS high_volume_flag,
        ROW_NUMBER() OVER (PARTITION BY d.d_year, d.d_month_seq ORDER BY cs.total_net_profit DESC) AS monthly_profit_rank,
        SUM(cs.total_net_profit) OVER (PARTITION BY i.i_category ORDER BY d.d_month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS cat_3mo_rolling_profit,
        (SELECT AVG(cs2.total_net_profit)
         FROM combined_sales cs2
         JOIN date_detail d2
            ON cs2.date_sk = d2.d_date_sk
         WHERE cs2.item_sk = cs.item_sk
           AND d2.d_month_seq = d.d_month_seq) AS avg_monthly_profit_same_month,
        CASE
            WHEN regexp_like(i.i_product_name, '^.*(Pro|Deluxe).*$') THEN 'Premium'
            ELSE 'Standard'
        END AS product_type
    FROM combined_sales cs
    JOIN item_detail i
        ON cs.item_sk = i.i_item_sk
    JOIN date_detail d
        ON cs.date_sk = d.d_date_sk
    LEFT JOIN promo_detail pd
        ON i.i_item_sk = pd.p_item_sk
        AND d.d_date_sk BETWEEN pd.p_start_date_sk AND pd.p_end_date_sk
    WHERE
        (i.i_size IS NOT NULL AND i.i_color NOT LIKE '%BLACK%')
        AND (d.d_year = 2001 OR d.d_year = 2002)
        AND (cs.total_net_paid > 0 OR cs.total_net_profit > 0)
        AND (COALESCE(i.i_color, '') <> 'UNKNOWN' OR i.i_color IS NULL)
        AND ((i.i_brand = 'Brand#12' AND i.i_category = 'Sports')
             OR (i.i_brand <> 'Brand#12' AND i.i_category <> 'Sports'))
),
final_set AS (
    SELECT *
    FROM filtered_sales
    UNION ALL
    SELECT
        item_sk,
        date_sk,
        total_net_paid,
        total_net_profit,
        total_txn_count,
        i_product_name,
        i_category,
        i_brand,
        cat_brand_key,
        d_date,
        d_year,
        d_month_seq,
        'NO_PROMO' AS promo_name,
        profit_margin,
        high_volume_flag,
        monthly_profit_rank,
        cat_3mo_rolling_profit,
        avg_monthly_profit_same_month,
        product_type
    FROM filtered_sales
    WHERE high_volume_flag = 0 AND profit_margin IS NOT NULL
),
ordered_results AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS global_profit_rank,
        PERCENT_RANK() OVER (ORDER BY total_net_paid DESC) AS net_paid_percentile,
        NTILE(10) OVER (ORDER BY total_net_profit DESC) AS profit_decile
    FROM final_set
)
SELECT
    global_profit_rank,
    item_sk,
    i_product_name,
    i_category,
    i_brand,
    cat_brand_key,
    d_date,
    d_year,
    d_month_seq,
    total_net_paid,
    total_net_profit,
    profit_margin,
    profit_decile,
    high_volume_flag,
    promo_name,
    product_type,
    monthly_profit_rank,
    cat_3mo_rolling_profit,
    avg_monthly_profit_same_month,
    net_paid_percentile
FROM ordered_results
WHERE global_profit_rank <= 100
ORDER BY global_profit_rank
