WITH
  sampled_sales AS (
    SELECT *
    FROM tpcds.catalog_sales TABLESAMPLE BERNOULLI (10)
  ),
  full_join_cc AS (
    SELECT ss.*, cc.cc_name, cc.cc_class
    FROM sampled_sales ss
    FULL OUTER JOIN tpcds.call_center cc
      ON ss.cs_call_center_sk = cc.cc_call_center_sk
  ),
  agg_union AS (
    SELECT
      fj.cc_class,
      fj.cc_name,
      cd.cd_credit_rating,
      td.t_shift,
      SUM(fj.cs_ext_sales_price) AS total_sales,
      COUNT(*) AS sales_cnt
    FROM full_join_cc fj
    JOIN tpcds.customer_demographics cd
      ON fj.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.time_dim td
      ON fj.cs_sold_time_sk = td.t_time_sk
    WHERE fj.cc_class IN ('large', 'medium')
      AND cd.cd_credit_rating = 'Good'
      AND td.t_shift = 'first'
    GROUP BY fj.cc_class, fj.cc_name, cd.cd_credit_rating, td.t_shift

    UNION DISTINCT

    SELECT
      fj.cc_class,
      fj.cc_name,
      cd.cd_credit_rating,
      td.t_shift,
      SUM(fj.cs_ext_sales_price) AS total_sales,
      COUNT(*) AS sales_cnt
    FROM full_join_cc fj
    JOIN tpcds.customer_demographics cd
      ON fj.cs_ship_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.time_dim td
      ON fj.cs_sold_time_sk = td.t_time_sk
    WHERE fj.cc_class IN ('large', 'medium')
      AND cd.cd_credit_rating = 'Good'
      AND td.t_shift = 'first'
    GROUP BY fj.cc_class, fj.cc_name, cd.cd_credit_rating, td.t_shift
  ),
  final AS (
    SELECT
      ua.*,
      l.avg_quantity_per_group
    FROM agg_union ua
    LEFT JOIN LATERAL (
      SELECT AVG(fj.cs_quantity) AS avg_quantity_per_group
      FROM full_join_cc fj
      WHERE fj.cc_class = ua.cc_class
        AND fj.cc_name = ua.cc_name
    ) l ON TRUE
  )
SELECT
  f.cc_class,
  f.cc_name,
  f.cd_credit_rating,
  f.t_shift,
  f.total_sales,
  f.sales_cnt,
  f.avg_quantity_per_group
FROM final f
ORDER BY f.total_sales DESC
LIMIT 100
