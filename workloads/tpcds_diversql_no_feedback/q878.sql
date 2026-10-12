WITH agg AS (
    SELECT
        cc.cc_name,
        s.s_store_name,
        ds.d_year,
        ds.d_month_seq,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(cs.cs_order_number) AS order_cnt,
        GROUPING(cc.cc_name)   AS grp_cc,
        GROUPING(s.s_store_name) AS grp_store,
        GROUPING(ds.d_year)    AS grp_year,
        GROUPING(ds.d_month_seq) AS grp_month
    FROM catalog_sales cs
    JOIN date_dim ds ON cs.cs_sold_date_sk = ds.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN store s ON s.s_closed_date_sk = ds.d_date_sk
    WHERE ds.d_year = 2001
      AND ds.d_weekend = 'N'
      AND cc.cc_state = 'CA'
      AND s.s_country = 'United States'
      AND cs.cs_quantity > 5
      AND cs.cs_ext_sales_price BETWEEN 1000 AND 5000
      AND s.s_floor_space > 8000000
    GROUP BY GROUPING SETS (
        (cc.cc_name, s.s_store_name),
        (ds.d_year, ds.d_month_seq)
    )
)
SELECT
    cc_name,
    s_store_name,
    d_year,
    d_month_seq,
    total_net_paid,
    order_cnt,
    CASE
        WHEN total_net_paid > 200000 THEN 'High'
        WHEN total_net_paid > 100000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    ROW_NUMBER() OVER (PARTITION BY grp_key ORDER BY total_net_paid DESC) AS sales_rank
FROM (
    SELECT
        *,
        CONCAT(
            CASE WHEN grp_cc = 1 THEN 'ALL_CC' ELSE COALESCE(cc_name, '') END, '|',
            CASE WHEN grp_store = 1 THEN 'ALL_STORE' ELSE COALESCE(s_store_name, '') END, '|',
            CASE WHEN grp_year = 1 THEN 'ALL_YEAR' ELSE CAST(d_year AS VARCHAR) END, '|',
            CASE WHEN grp_month = 1 THEN 'ALL_MONTH' ELSE CAST(d_month_seq AS VARCHAR) END
        ) AS grp_key
    FROM agg
) t
ORDER BY sales_rank ASC, total_net_paid DESC
LIMIT 100
