WITH sp_profit AS (
    SELECT ss.ss_sold_date_sk AS d_date_sk, SUM(ss.ss_net_profit) AS store_profit
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk
),
cat_profit AS (
    SELECT cs.cs_sold_date_sk AS d_date_sk, SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_sold_date_sk
),
wp_profit AS (
    SELECT ws.ws_sold_date_sk AS d_date_sk, SUM(ws.ws_net_profit) AS web_profit
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk
),
aggregated_profit AS (
    SELECT d.d_date,
           d.d_date_sk,
           COALESCE(sp.store_profit, 0) AS store_profit,
           COALESCE(cp.catalog_profit, 0) AS catalog_profit,
           COALESCE(wp.web_profit, 0) AS web_profit,
           COALESCE(sp.store_profit, 0) + COALESCE(cp.catalog_profit, 0) + COALESCE(wp.web_profit, 0) AS total_profit,
           d.d_day_name,
           d.d_year
    FROM date_dim d
    LEFT JOIN sp_profit sp ON sp.d_date_sk = d.d_date_sk
    LEFT JOIN cat_profit cp ON cp.d_date_sk = d.d_date_sk
    LEFT JOIN wp_profit wp ON wp.d_date_sk = d.d_date_sk
),
top_item_global AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           SUM(cs.cs_net_profit) AS top_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_product_name
    ORDER BY top_profit DESC
    LIMIT 1
),
customer_purchase_stats AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COUNT(*) AS purchase_cnt,
        SUM(cs.cs_net_paid) AS total_spent,
        AVG(cs.cs_net_paid) AS avg_spent,
        MAX(cs.cs_sold_date_sk) AS last_purchase_sk,
        (SELECT SUM(cs2.cs_net_paid)
         FROM catalog_sales cs2
         WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
           AND cs2.cs_sold_date_sk = (
               SELECT MAX(cs3.cs_sold_date_sk)
               FROM catalog_sales cs3
               WHERE cs3.cs_bill_customer_sk = c.c_customer_sk
           )
        ) AS latest_spent
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customer AS (
    SELECT *
    FROM customer_purchase_stats
    ORDER BY total_spent DESC
    LIMIT 1
),
rare_returns AS (
    SELECT d.d_date,
           COUNT(*) AS return_cnt,
           SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN date_dim d ON d.d_date_sk = sr.sr_returned_date_sk
    WHERE sr.sr_return_quantity = 0
    GROUP BY d.d_date
),
union_loss AS (
    SELECT d_date,
           SUM(loss) AS combined_loss
    FROM (
        SELECT cr.cr_returned_date_sk AS d_date, SUM(cr.cr_net_loss) AS loss
        FROM catalog_returns cr
        GROUP BY cr.cr_returned_date_sk
        UNION ALL
        SELECT wr.wr_returned_date_sk AS d_date, SUM(wr.wr_net_loss) AS loss
        FROM web_returns wr
        GROUP BY wr.wr_returned_date_sk
        UNION ALL
        SELECT sr.sr_returned_date_sk AS d_date, SUM(sr.sr_net_loss) AS loss
        FROM store_returns sr
        GROUP BY sr.sr_returned_date_sk
    ) u
    GROUP BY d_date
)
SELECT
    a.d_date,
    a.store_profit,
    a.catalog_profit,
    a.web_profit,
    a.total_profit,
    GREATEST(a.store_profit, a.catalog_profit, a.web_profit) AS max_channel_profit,
    LEAST(a.store_profit, a.catalog_profit, a.web_profit) AS min_channel_profit,
    CASE
        WHEN a.d_day_name IN ('Saturday','Sunday') THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    CASE
        WHEN a.d_day_name IS NOT DISTINCT FROM 'Sunday' THEN 'Sun'
        ELSE a.d_day_name
    END AS day_name_norm,
    rr.return_cnt,
    rr.total_return_loss,
    ti.i_item_sk,
    ti.i_product_name,
    ti.top_profit AS top_category_profit,
    cs.full_name,
    cs.purchase_cnt,
    cs.total_spent,
    cs.avg_spent,
    CASE
        WHEN cs.last_purchase_sk = a.d_date_sk THEN 'MostRecent'
        ELSE NULL
    END AS recent_flag,
    (SELECT COUNT(*)
     FROM (
         SELECT sr.sr_store_sk
         FROM store_returns sr
         FULL OUTER JOIN store s ON sr.sr_store_sk = s.s_store_sk
         WHERE s.s_store_name IS NULL AND sr.sr_returned_date_sk = a.d_date_sk
     ) t) AS returns_without_store,
    ul.combined_loss AS union_combined_loss,
    SUM(a.total_profit) OVER (PARTITION BY CASE WHEN a.d_day_name IN ('Saturday','Sunday') THEN 'Weekend' ELSE 'Weekday' END) AS profit_by_day_type,
    NULLIF(p.p_promo_id, '') AS promo_id_or_null,
    CAST(a.d_date AS varchar) AS d_date_str,
    CONCAT(CAST(a.d_date AS varchar), ' ', CASE WHEN a.d_day_name IN ('Saturday','Sunday') THEN 'Weekend' ELSE 'Weekday' END) AS date_daytype_concat
FROM aggregated_profit a
LEFT JOIN rare_returns rr ON rr.d_date = a.d_date
CROSS JOIN top_item_global ti
CROSS JOIN top_customer cs
LEFT JOIN union_loss ul ON ul.d_date = a.d_date_sk
LEFT JOIN promotion p ON p.p_start_date_sk = a.d_date_sk
WHERE a.d_year = 2001
ORDER BY a.d_date
LIMIT 200
