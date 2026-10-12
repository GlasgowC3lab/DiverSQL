WITH
store_agg AS (
    SELECT d.d_date_sk,
           d.d_date,
           d.d_year,
           SUM(ss.ss_net_paid) AS store_net
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE t.t_shift = 'first'
      AND d.d_year = 2001
    GROUP BY d.d_date_sk, d.d_date, d.d_year
),
catalog_agg AS (
    SELECT d.d_date_sk,
           d.d_date,
           d.d_year,
           w.w_county,
           SUM(cs.cs_net_paid) AS catalog_net
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE t.t_shift = 'first'
      AND d.d_year = 2001
    GROUP BY d.d_date_sk, d.d_date, d.d_year, w.w_county
),
returns_agg AS (
    SELECT d.d_date_sk,
           SUM(cr.cr_net_loss) AS returns_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_shift = 'first'
      AND d.d_year = 2001
    GROUP BY d.d_date_sk
),
web_pages_agg AS (
    SELECT d.d_date_sk,
           COUNT(DISTINCT wp.wp_web_page_sk) AS page_cnt
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date_sk
),
base_set AS (
    SELECT sa.d_date,
           sa.d_year,
           ca.w_county,
           sa.store_net,
           ca.catalog_net,
           ra.returns_loss,
           wa.page_cnt,
           CASE WHEN sa.store_net > ca.catalog_net THEN 'StoreHigher' ELSE 'CatalogHigher' END AS higher_source
    FROM store_agg sa
    JOIN catalog_agg ca ON sa.d_date_sk = ca.d_date_sk
    JOIN returns_agg ra ON sa.d_date_sk = ra.d_date_sk
    JOIN web_pages_agg wa ON sa.d_date_sk = wa.d_date_sk
    WHERE sa.store_net > 10000
),
alt_set AS (
    SELECT sa.d_date,
           sa.d_year,
           ca.w_county,
           sa.store_net,
           ca.catalog_net,
           ra.returns_loss,
           wa.page_cnt,
           CASE WHEN sa.store_net > ca.catalog_net THEN 'StoreHigher' ELSE 'CatalogHigher' END AS higher_source
    FROM store_agg sa
    JOIN catalog_agg ca ON sa.d_date_sk = ca.d_date_sk
    JOIN returns_agg ra ON sa.d_date_sk = ra.d_date_sk
    JOIN web_pages_agg wa ON sa.d_date_sk = wa.d_date_sk
    WHERE ca.catalog_net > 5000
      AND ca.w_county = 'Mobile County'
),
combined AS (
    SELECT * FROM base_set
    INTERSECT
    SELECT * FROM alt_set
),
final_set AS (
    SELECT * FROM combined
    EXCEPT
    SELECT *
    FROM base_set
    WHERE returns_loss > 2000
)
SELECT *
FROM final_set
LIMIT 100
