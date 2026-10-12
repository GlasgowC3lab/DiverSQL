WITH
sales_union AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_sold_date_sk AS sold_date_sk,
        d.d_date,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_ext_discount_amt AS ext_discount_amt,
        cs.cs_ext_tax AS ext_tax,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        COALESCE(c.c_first_name, '') || ' ' || COALESCE(c.c_last_name, '') AS customer_name,
        i.i_product_name AS product_name,
        i.i_category AS category,
        i.i_brand AS brand,
        CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_sign,
        'catalog' AS source
    FROM catalog_sales cs
    LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
    UNION ALL
    SELECT
        ss.ss_ticket_number AS order_number,
        ss.ss_sold_date_sk AS sold_date_sk,
        d.d_date,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS ext_sales_price,
        ss.ss_ext_discount_amt AS ext_discount_amt,
        ss.ss_ext_tax AS ext_tax,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        COALESCE(c.c_first_name, '') || ' ' || COALESCE(c.c_last_name, '') AS customer_name,
        i.i_product_name AS product_name,
        i.i_category AS category,
        i.i_brand AS brand,
        CASE WHEN ss.ss_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_sign,
        'store' AS source
    FROM store_sales ss
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2000
),
sales_ranked AS (
    SELECT
        su.*,
        ROW_NUMBER() OVER (PARTITION BY source, customer_name ORDER BY net_profit DESC NULLS LAST) AS profit_rank,
        SUM(net_profit) OVER (PARTITION BY source, d_date ORDER BY net_profit ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
        LAG(net_profit, 1) OVER (PARTITION BY source ORDER BY d_date) AS prev_day_profit,
        CASE WHEN net_profit IS NOT DISTINCT FROM LAG(net_profit) OVER (PARTITION BY source ORDER BY d_date) THEN 1 ELSE 0 END AS profit_repeat_flag,
        CASE WHEN net_profit > 0 THEN 'POSITIVE' ELSE 'NONPOSITIVE' END AS profit_category
    FROM sales_union su
),
returns_agg AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        CASE WHEN cr.cr_return_amount IS NULL THEN 'UNKNOWN' ELSE 'KNOWN' END AS return_status,
        cr.cr_reason_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 0
),
return_counts AS (
    SELECT
        cr_order_number,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    GROUP BY cr_order_number
),
sales_with_returns AS (
    SELECT
        sr.*,
        ra.return_status,
        ra.cr_net_loss,
        rc.return_cnt,
        COALESCE(ra.return_status, 'NO_RETURN') AS return_indicator,
        CASE
            WHEN ra.cr_net_loss IS NULL THEN NULL
            WHEN ra.cr_net_loss > 0 THEN 'LOSS'
            ELSE 'GAIN'
        END AS return_impact
    FROM sales_ranked sr
    LEFT JOIN returns_agg ra ON sr.order_number = ra.cr_order_number
    LEFT JOIN return_counts rc ON sr.order_number = rc.cr_order_number
),
catalog_top_customers AS (
    SELECT DISTINCT customer_name FROM sales_with_returns WHERE profit_rank = 1 AND source = 'catalog'
),
store_top_customers AS (
    SELECT DISTINCT customer_name FROM sales_with_returns WHERE profit_rank = 1 AND source = 'store'
),
common_top_customers AS (
    SELECT customer_name FROM catalog_top_customers
    INTERSECT
    SELECT customer_name FROM store_top_customers
),
aggregated_totals AS (
    SELECT
        'TOTAL' AS customer_name,
        source,
        d_date,
        SUM(net_profit) AS net_profit,
        SUM(cumulative_profit) AS cumulative_profit,
        'AGGREGATED' AS return_indicator,
        NULL AS return_impact,
        NULL AS return_cnt,
        'AGGREGATE' AS profit_category
    FROM sales_with_returns
    GROUP BY source, d_date
),
final_set AS (
    SELECT
        customer_name,
        source,
        d_date,
        net_profit,
        cumulative_profit,
        return_indicator,
        return_impact,
        return_cnt,
        profit_category
    FROM sales_with_returns
    UNION ALL
    SELECT
        customer_name,
        source,
        d_date,
        net_profit,
        cumulative_profit,
        return_indicator,
        return_impact,
        return_cnt,
        profit_category
    FROM aggregated_totals
)
SELECT
    fs.customer_name,
    fs.source,
    fs.d_date,
    fs.net_profit,
    fs.cumulative_profit,
    fs.return_indicator,
    fs.return_impact,
    fs.return_cnt,
    CASE
        WHEN fs.net_profit IS NULL THEN 'NULL_NET'
        WHEN fs.net_profit = 0 THEN 'ZERO'
        ELSE CAST(fs.net_profit AS VARCHAR)
    END AS net_profit_str,
    CONCAT('Profit_', CAST(ROW_NUMBER() OVER (PARTITION BY fs.source ORDER BY fs.d_date) AS VARCHAR)) AS profit_seq,
    TRY_CAST(fs.return_impact AS VARCHAR) AS safe_return_impact,
    COALESCE(NULLIF(fs.return_cnt, 0), -1) AS safe_return_cnt,
    (SELECT AVG(net_profit) FROM sales_ranked sr2 WHERE sr2.customer_name = fs.customer_name) AS customer_avg_profit,
    REPLACE(fs.customer_name, ' ', '_') AS customer_name_underscored,
    MOD(COALESCE(fs.net_profit, 0), 5) AS net_profit_mod_5,
    CASE
        WHEN fs.profit_category = 'POSITIVE' AND fs.return_indicator = 'KNOWN' THEN TRUE
        ELSE FALSE
    END AS fancy_flag
FROM final_set fs
WHERE fs.customer_name IN (SELECT customer_name FROM common_top_customers)
  AND (fs.net_profit > 0 OR (fs.net_profit IS NULL AND fs.return_indicator = 'NO_RETURN'))
ORDER BY fs.source, fs.d_date, fs.customer_name NULLS LAST
