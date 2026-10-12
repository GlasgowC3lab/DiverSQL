WITH
    catalog_sales_cte AS (
        SELECT
            cs.cs_sold_date_sk AS date_sk,
            cs.cs_item_sk AS item_sk,
            cs.cs_bill_customer_sk AS customer_sk,
            cs.cs_quantity AS quantity,
            cs.cs_net_paid AS net_paid,
            cs.cs_net_profit AS net_profit,
            p.p_promo_id AS promo_id,
            'catalog' AS channel,
            cd.cd_gender AS gender,
            i.i_item_desc AS item_desc,
            d.d_year,
            d.d_month_seq,
            ROW_NUMBER() OVER (PARTITION BY cs.cs_sold_date_sk ORDER BY cs.cs_net_profit DESC) AS rn
        FROM catalog_sales cs
        LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
        LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE cs.cs_quantity > 0
          AND (i.i_color IS NOT NULL OR i.i_size = 'M')
    ),
    store_sales_cte AS (
        SELECT
            ss.ss_sold_date_sk AS date_sk,
            ss.ss_item_sk AS item_sk,
            ss.ss_customer_sk AS customer_sk,
            ss.ss_quantity AS quantity,
            ss.ss_net_paid AS net_paid,
            ss.ss_net_profit AS net_profit,
            p.p_promo_id AS promo_id,
            'store' AS channel,
            cd.cd_gender AS gender,
            i.i_item_desc AS item_desc,
            d.d_year,
            d.d_month_seq,
            ROW_NUMBER() OVER (PARTITION BY ss.ss_sold_date_sk ORDER BY ss.ss_net_profit DESC) AS rn
        FROM store_sales ss
        LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
        LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE ss.ss_quantity > 0
          AND (i.i_color = 'RED' OR i.i_formulation LIKE '%organic%')
    ),
    web_sales_cte AS (
        SELECT
            ws.ws_sold_date_sk AS date_sk,
            ws.ws_item_sk AS item_sk,
            ws.ws_bill_customer_sk AS customer_sk,
            ws.ws_quantity AS quantity,
            ws.ws_net_paid AS net_paid,
            ws.ws_net_profit AS net_profit,
            p.p_promo_id AS promo_id,
            'web' AS channel,
            cd.cd_gender AS gender,
            i.i_item_desc AS item_desc,
            d.d_year,
            d.d_month_seq,
            ROW_NUMBER() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY ws.ws_net_profit DESC) AS rn
        FROM web_sales ws
        LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
        LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE ws.ws_quantity > 0
          AND (i.i_size = 'L' OR i.i_color IS NOT NULL)
    ),
    catalog_returns_cte AS (
        SELECT
            cr.cr_returned_date_sk AS date_sk,
            cr.cr_item_sk AS item_sk,
            cr.cr_refunded_customer_sk AS customer_sk,
            cr.cr_return_quantity AS quantity,
            cr.cr_return_amount AS net_paid,
            -cr.cr_net_loss AS net_profit,
            p.p_promo_id AS promo_id,
            'catalog_return' AS channel,
            cd.cd_gender AS gender,
            i.i_item_desc AS item_desc,
            d.d_year,
            d.d_month_seq,
            ROW_NUMBER() OVER (PARTITION BY cr.cr_returned_date_sk ORDER BY -cr.cr_net_loss DESC) AS rn
        FROM catalog_returns cr
        LEFT JOIN promotion p ON cr.cr_reason_sk = p.p_promo_sk
        LEFT JOIN item i ON cr.cr_item_sk = i.i_item_sk
        LEFT JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE cr.cr_return_quantity > 0
          AND (cr.cr_return_amount IS NOT NULL OR cr.cr_fee = 0)
    ),
    combined_cte AS (
        SELECT * FROM catalog_sales_cte
        UNION ALL
        SELECT * FROM store_sales_cte
        UNION ALL
        SELECT * FROM web_sales_cte
        UNION ALL
        SELECT * FROM catalog_returns_cte
    ),
    aggregated_base_cte AS (
        SELECT
            date_sk,
            channel,
            item_sk,
            SUM(net_profit) AS total_profit,
            SUM(net_paid) AS total_paid,
            SUM(quantity) AS total_quantity
        FROM combined_cte
        GROUP BY date_sk, channel, item_sk
    ),
    aggregated_cte AS (
        SELECT
            *,
            ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_profit DESC) AS rank_in_channel
        FROM aggregated_base_cte
    ),
    enriched_cte AS (
        SELECT
            a.date_sk,
            a.channel,
            a.item_sk,
            a.total_profit,
            a.total_paid,
            a.total_quantity,
            a.rank_in_channel,
            d.d_year,
            d.d_month_seq,
            i.i_product_name,
            i.i_color,
            i.i_item_desc,
            CASE WHEN a.total_paid = 0 THEN NULL ELSE a.total_profit / a.total_paid END AS profit_to_paid_ratio,
            CASE WHEN a.total_quantity = 0 THEN NULL ELSE a.total_profit / a.total_quantity END AS profit_per_unit,
            CONCAT(CAST(a.rank_in_channel AS VARCHAR), ':', COALESCE(i.i_color,'NONE')) AS rank_color,
            REPLACE(REVERSE(COALESCE(i.i_product_name,'')), 'A', '@') AS reversed_product_name,
            CASE WHEN i.i_product_name LIKE '%special%' THEN 'SPECIAL' ELSE 'NORMAL' END AS product_type,
            CASE WHEN REGEXP_LIKE(i.i_product_name, '\\d{4}') THEN 'HAS4DIGIT' ELSE 'NO4DIGIT' END AS product_name_digit_flag,
            (SELECT MAX(b2.total_profit)
             FROM aggregated_base_cte b2
             WHERE b2.item_sk = a.item_sk) AS max_item_profit,
            LAG(a.total_profit) OVER (PARTITION BY a.item_sk ORDER BY d.d_year, d.d_month_seq) AS prev_month_profit,
            CASE
                WHEN LAG(a.total_profit) OVER (PARTITION BY a.item_sk ORDER BY d.d_year, d.d_month_seq) IS NULL THEN NULL
                ELSE (a.total_profit - LAG(a.total_profit) OVER (PARTITION BY a.item_sk ORDER BY d.d_year, d.d_month_seq))
                     / NULLIF(LAG(a.total_profit) OVER (PARTITION BY a.item_sk ORDER BY d.d_year, d.d_month_seq),0)
            END AS profit_monthly_growth,
            SUM(CASE WHEN a.channel = 'catalog' THEN a.total_profit ELSE 0 END) OVER (PARTITION BY d.d_year) AS catalog_year_profit,
            SUM(CASE WHEN a.channel = 'store' THEN a.total_profit ELSE 0 END) OVER (PARTITION BY d.d_year) AS store_year_profit,
            CASE WHEN d.d_year IS NULL THEN 'UNKNOWN_YEAR' ELSE CAST(d.d_year AS VARCHAR) END AS year_str
        FROM aggregated_cte a
        LEFT JOIN date_dim d ON a.date_sk = d.d_date_sk
        LEFT JOIN item i ON a.item_sk = i.i_item_sk
        WHERE a.rank_in_channel <= 5
    )
SELECT
    year_str,
    d_month_seq,
    channel,
    rank_in_channel,
    item_sk,
    i_product_name,
    i_color,
    total_quantity,
    total_paid,
    total_profit,
    profit_to_paid_ratio,
    profit_per_unit,
    rank_color,
    reversed_product_name,
    product_type,
    product_name_digit_flag,
    max_item_profit,
    prev_month_profit,
    profit_monthly_growth,
    catalog_year_profit,
    store_year_profit
FROM enriched_cte
ORDER BY year_str DESC NULLS LAST, channel, rank_in_channel
