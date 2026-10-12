WITH
    -- Aggregate store sales (right outer join to keep all stores)
    store_sales_agg AS (
        SELECT
            s.s_store_sk,
            s.s_store_name,
            SUM(ss.ss_net_paid) AS total_net_paid,
            SUM(ss.ss_net_profit) AS total_net_profit,
            COUNT(*) AS sales_cnt
        FROM store_sales ss
        RIGHT OUTER JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d
            ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN time_dim t
            ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN promotion p
            ON ss.ss_promo_sk = p.p_promo_sk
        LEFT JOIN date_dim d_closed
            ON s.s_closed_date_sk = d_closed.d_date_sk
        WHERE d.d_quarter_name = '1901Q3'
          AND d.d_weekend = 'N'
          AND t.t_second > 2
          AND p.p_discount_active = 'Y'
          AND s.s_state = 'CA'
        GROUP BY s.s_store_sk, s.s_store_name
    ),

    -- Aggregate catalog returns
    catalog_returns_agg AS (
        SELECT
            cr.cr_returned_date_sk,
            SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
            SUM(cr.cr_net_loss) AS total_net_loss
        FROM catalog_returns cr
        JOIN date_dim d
            ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN time_dim t
            ON cr.cr_returned_time_sk = t.t_time_sk
        WHERE d.d_quarter_name = '1901Q3'
          AND d.d_weekend = 'N'
          AND t.t_second > 2
        GROUP BY cr.cr_returned_date_sk
    ),

    -- Aggregate web returns
    web_returns_agg AS (
        SELECT
            wr.wr_returned_date_sk,
            SUM(wr.wr_return_amt_inc_tax) AS web_return_amount
        FROM web_returns wr
        JOIN date_dim d
            ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN time_dim t
            ON wr.wr_returned_time_sk = t.t_time_sk
        WHERE d.d_quarter_name = '1901Q3'
          AND d.d_weekend = 'N'
          AND t.t_second > 2
        GROUP BY wr.wr_returned_date_sk
    ),

    -- Full outer join of the two return streams
    full_returns AS (
        SELECT
            COALESCE(c.cr_returned_date_sk, w.wr_returned_date_sk) AS date_sk,
            c.total_return_amount,
            w.web_return_amount
        FROM catalog_returns_agg c
        FULL OUTER JOIN web_returns_agg w
            ON c.cr_returned_date_sk = w.wr_returned_date_sk
    ),

    -- Aggregate web sales (including web_page and web_site)
    web_sales_agg AS (
        SELECT
            ws.ws_web_site_sk,
            SUM(ws.ws_net_profit) AS web_net_profit,
            COUNT(*) AS web_sales_cnt
        FROM web_sales ws
        JOIN date_dim d
            ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN time_dim t
            ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN promotion p
            ON ws.ws_promo_sk = p.p_promo_sk
        JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site wit
            ON ws.ws_web_site_sk = wit.web_site_sk
        WHERE p.p_discount_active = 'Y'
          AND d.d_quarter_name = '1901Q3'
          AND t.t_second > 2
          AND wp.wp_type = 'product'
          AND wit.web_country = 'United States'
        GROUP BY ws.ws_web_site_sk
    ),

    -- Union of store and web_site profit figures
    union_all_entities AS (
        SELECT
            'store' AS entity_type,
            CAST(s.s_store_sk AS BIGINT) AS entity_id,
            s.total_net_profit AS net_amount
        FROM store_sales_agg s
        UNION DISTINCT
        SELECT
            'web_site' AS entity_type,
            CAST(w.ws_web_site_sk AS BIGINT) AS entity_id,
            w.web_net_profit AS net_amount
        FROM web_sales_agg w
    ),

    -- Ranking entities by profit
    final_ranked AS (
        SELECT
            entity_type,
            entity_id,
            net_amount,
            CASE
                WHEN net_amount >= 1000000 THEN 'High'
                WHEN net_amount >= 500000  THEN 'Medium'
                ELSE 'Low'
            END AS profit_category,
            RANK() OVER (PARTITION BY entity_type ORDER BY net_amount DESC) AS profit_rank
        FROM union_all_entities
    ),

    -- Small dimension for cross join (years 1998‑2000)
    year_seq AS (
        SELECT d.d_year
        FROM date_dim d
        WHERE d.d_year BETWEEN 1998 AND 2000
    ),
    seq_vals AS (
        SELECT 1 AS seq UNION ALL SELECT 2 UNION ALL SELECT 3
    ),
    cross_joined AS (
        SELECT y.d_year, s.seq
        FROM year_seq y
        CROSS JOIN seq_vals s
    )
SELECT
    fr.date_sk,
    fr.total_return_amount,
    fr.web_return_amount,
    dy.d_year,
    cj.seq,
    frk.entity_type,
    frk.entity_id,
    frk.net_amount,
    frk.profit_category,
    frk.profit_rank
FROM full_returns fr
LEFT JOIN date_dim dy
    ON fr.date_sk = dy.d_date_sk
CROSS JOIN final_ranked frk
CROSS JOIN cross_joined cj
WHERE dy.d_current_month = 'Y'
ORDER BY frk.profit_rank ASC, fr.date_sk DESC
LIMIT 100
