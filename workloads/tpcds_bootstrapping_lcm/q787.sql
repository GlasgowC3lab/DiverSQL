SELECT
    agg.cc_name,
    agg.cc_city,
    agg.s_store_name,
    agg.s_city,
    agg.cp_catalog_number,
    agg.cp_type,
    agg.sale_year,
    agg.sale_month,
    agg.total_net_paid,
    agg.total_net_profit,
    agg.distinct_orders,
    RANK() OVER (PARTITION BY agg.cp_catalog_number ORDER BY agg.total_net_paid DESC) AS sales_rank
FROM (
    SELECT
        cc.cc_name,
        cc.cc_city,
        s.s_store_name,
        s.s_city,
        cp.cp_catalog_number,
        cp.cp_type,
        sold_date.d_year AS sale_year,
        sold_date.d_moy AS sale_month,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim sold_date
      ON cs.cs_sold_date_sk = sold_date.d_date_sk
    JOIN date_dim ship_date
      ON cs.cs_ship_date_sk = ship_date.d_date_sk
    JOIN date_dim cc_open_date
      ON cc.cc_open_date_sk = cc_open_date.d_date_sk
    JOIN date_dim cc_closed_date
      ON cc.cc_closed_date_sk = cc_closed_date.d_date_sk
    JOIN date_dim cp_start_date
      ON cp.cp_start_date_sk = cp_start_date.d_date_sk
    JOIN date_dim cp_end_date
      ON cp.cp_end_date_sk = cp_end_date.d_date_sk
    JOIN store s
      ON s.s_closed_date_sk = ship_date.d_date_sk
    WHERE 
        sold_date.d_year = 2001
        AND cp.cp_type = 'PROMO'
        AND sold_date.d_date_sk BETWEEN cc_open_date.d_date_sk AND cc_closed_date.d_date_sk
        AND sold_date.d_date_sk BETWEEN cp_start_date.d_date_sk AND cp_end_date.d_date_sk
    GROUP BY
        cc.cc_name,
        cc.cc_city,
        s.s_store_name,
        s.s_city,
        cp.cp_catalog_number,
        cp.cp_type,
        sold_date.d_year,
        sold_date.d_moy
) agg
ORDER BY agg.total_net_paid DESC
LIMIT 100
