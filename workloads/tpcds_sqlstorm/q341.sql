WITH sales_raw AS (
    SELECT 'store' AS channel,
           ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_customer_sk AS cust_sk,
           ss.ss_quantity AS quantity,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS profit,
           ss.ss_store_sk AS store_sk,
           CAST(NULL AS INTEGER) AS call_center_sk,
           CAST(NULL AS INTEGER) AS web_page_sk,
           ss.ss_promo_sk AS promo_sk
    FROM store_sales ss
    WHERE ss.ss_quantity > 0
    UNION ALL
    SELECT 'catalog' AS channel,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_bill_customer_sk AS cust_sk,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS profit,
           CAST(NULL AS INTEGER) AS store_sk,
           cs.cs_call_center_sk AS call_center_sk,
           CAST(NULL AS INTEGER) AS web_page_sk,
           cs.cs_promo_sk AS promo_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
    UNION ALL
    SELECT 'web' AS channel,
           ws.ws_sold_date_sk AS date_sk,
           ws.ws_item_sk AS item_sk,
           ws.ws_bill_customer_sk AS cust_sk,
           ws.ws_quantity AS quantity,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS profit,
           CAST(NULL AS INTEGER) AS store_sk,
           CAST(NULL AS INTEGER) AS call_center_sk,
           ws.ws_web_page_sk AS web_page_sk,
           ws.ws_promo_sk AS promo_sk
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
),
returns_raw AS (
    SELECT 'store' AS channel,
           sr.sr_returned_date_sk AS date_sk,
           sr.sr_item_sk AS item_sk,
           sr.sr_customer_sk AS cust_sk,
           -sr.sr_return_quantity AS quantity,
           -sr.sr_return_amt AS net_paid,
           -sr.sr_net_loss AS profit,
           sr.sr_store_sk AS store_sk,
           CAST(NULL AS INTEGER) AS call_center_sk,
           CAST(NULL AS INTEGER) AS web_page_sk,
           CAST(NULL AS INTEGER) AS promo_sk
    FROM store_returns sr
    UNION ALL
    SELECT 'catalog' AS channel,
           cr.cr_returned_date_sk AS date_sk,
           cr.cr_item_sk AS item_sk,
           cr.cr_refunded_customer_sk AS cust_sk,
           -cr.cr_return_quantity AS quantity,
           -cr.cr_refunded_cash AS net_paid,
           -cr.cr_net_loss AS profit,
           CAST(NULL AS INTEGER) AS store_sk,
           cr.cr_call_center_sk AS call_center_sk,
           CAST(NULL AS INTEGER) AS web_page_sk,
           CAST(NULL AS INTEGER) AS promo_sk
    FROM catalog_returns cr
    UNION ALL
    SELECT 'web' AS channel,
           wr.wr_returned_date_sk AS date_sk,
           wr.wr_item_sk AS item_sk,
           wr.wr_refunded_customer_sk AS cust_sk,
           -wr.wr_return_quantity AS quantity,
           -wr.wr_return_amt AS net_paid,
           -wr.wr_net_loss AS profit,
           CAST(NULL AS INTEGER) AS store_sk,
           CAST(NULL AS INTEGER) AS call_center_sk,
           wr.wr_web_page_sk AS web_page_sk,
           CAST(NULL AS INTEGER) AS promo_sk
    FROM web_returns wr
),
fact_combined AS (
    SELECT * FROM sales_raw
    UNION ALL
    SELECT * FROM returns_raw
),
enriched_fact AS (
    SELECT f.channel,
           d.d_year,
           d.d_month_seq,
           i.i_category,
           i.i_brand,
           i.i_product_name,
           f.item_sk,
           COALESCE(f.store_sk, f.call_center_sk, f.web_page_sk) AS location_sk,
           CASE
               WHEN f.channel = 'store' THEN COALESCE(s.s_store_name, 'UNKNOWN')
               WHEN f.channel = 'catalog' THEN COALESCE(cc.cc_name, 'UNKNOWN')
               WHEN f.channel = 'web' THEN COALESCE(wp.wp_url, 'UNKNOWN')
               ELSE 'UNKNOWN'
           END AS location_desc,
           f.cust_sk,
           f.quantity,
           f.net_paid,
           f.profit,
           f.promo_sk
    FROM fact_combined f
    LEFT JOIN date_dim d ON f.date_sk = d.d_date_sk
    LEFT JOIN item i ON f.item_sk = i.i_item_sk
    LEFT JOIN store s ON f.store_sk = s.s_store_sk
    LEFT JOIN call_center cc ON f.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN web_page wp ON f.web_page_sk = wp.wp_web_page_sk
    WHERE (d.d_year % 2 = 0 OR d.d_year IS NULL)
          AND (d.d_month_seq BETWEEN 1 AND 12)
          AND (d.d_holiday IS NULL OR d.d_holiday <> 'Y')
),
aggregated AS (
    SELECT
        channel,
        d_year,
        i_category,
        i_brand,
        location_desc,
        SUM(quantity) AS total_quantity,
        SUM(net_paid) AS total_net_paid,
        SUM(profit) AS total_profit,
        CASE WHEN SUM(quantity) <> 0 THEN SUM(net_paid) / SUM(quantity) ELSE NULL END AS avg_price_per_unit,
        array_join(
            array_agg(DISTINCT REGEXP_REPLACE(i_product_name, '[^A-Za-z0-9]', '')) FILTER (WHERE i_product_name IS NOT NULL),
            ', '
        ) AS product_names,
        COUNT(DISTINCT cust_sk) AS distinct_customers,
        SUM(profit) FILTER (WHERE profit > 0) AS positive_profit,
        ROW_NUMBER() OVER (PARTITION BY channel ORDER BY SUM(net_paid) DESC NULLS LAST) AS revenue_rank,
        LAG(SUM(net_paid)) OVER (PARTITION BY channel ORDER BY d_year) AS prior_year_net_paid,
        COUNT(DISTINCT item_sk) AS distinct_items
    FROM enriched_fact
    GROUP BY channel, d_year, i_category, i_brand, location_desc
    HAVING SUM(net_paid) > 0
),
top_customers AS (
    SELECT
        channel,
        d_year,
        cust_sk,
        SUM(net_paid) AS cust_total_spent,
        ROW_NUMBER() OVER (PARTITION BY channel, d_year ORDER BY SUM(net_paid) DESC) AS cust_rank
    FROM enriched_fact
    WHERE cust_sk IS NOT NULL
    GROUP BY channel, d_year, cust_sk
),
final_detail AS (
    SELECT
        a.channel,
        a.d_year,
        a.i_category,
        a.i_brand,
        a.location_desc,
        a.total_quantity,
        a.total_net_paid,
        a.total_profit,
        a.avg_price_per_unit,
        a.product_names,
        a.distinct_customers,
        a.revenue_rank,
        tc.cust_sk AS top_cust_sk,
        tc.cust_total_spent AS top_cust_spent,
        tc.cust_rank AS top_cust_rank,
        a.prior_year_net_paid,
        (SELECT i2.i_product_name
         FROM enriched_fact ef2
         JOIN item i2 ON ef2.item_sk = i2.i_item_sk
         WHERE ef2.channel = a.channel
           AND ef2.d_year = a.d_year
         ORDER BY ef2.profit DESC
         LIMIT 1) AS top_product_of_year
    FROM aggregated a
    LEFT JOIN top_customers tc
        ON a.channel = tc.channel
        AND a.d_year = tc.d_year
        AND tc.cust_rank = 1
)
SELECT *
FROM final_detail
WHERE try(CAST(total_net_paid AS double) / nullif(total_quantity, 0)) > 10
UNION ALL
SELECT
    'SUMMARY' AS channel,
    NULL AS d_year,
    NULL AS i_category,
    NULL AS i_brand,
    'OVERALL' AS location_desc,
    SUM(total_quantity) OVER () AS total_quantity,
    SUM(total_net_paid) OVER () AS total_net_paid,
    SUM(total_profit) OVER () AS total_profit,
    AVG(avg_price_per_unit) OVER () AS avg_price_per_unit,
    NULL AS product_names,
    MAX(distinct_customers) OVER () AS distinct_customers,
    NULL AS revenue_rank,
    NULL AS top_cust_sk,
    NULL AS top_cust_spent,
    NULL AS top_cust_rank,
    NULL AS prior_year_net_paid,
    NULL AS top_product_of_year
FROM final_detail
ORDER BY channel, d_year DESC NULLS LAST, revenue_rank
LIMIT 200
