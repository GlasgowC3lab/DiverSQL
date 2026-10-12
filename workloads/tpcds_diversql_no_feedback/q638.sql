WITH
  sales_agg AS (
    SELECT
      cs_item_sk,
      cs_sold_date_sk,
      cs_sold_time_sk,
      SUM(cs_ext_sales_price) AS total_sales_amount,
      SUM(cs_quantity) AS total_quantity,
      SUM(cs_net_profit) AS total_net_profit
    FROM catalog_sales
    GROUP BY cs_item_sk, cs_sold_date_sk, cs_sold_time_sk
  ),
  agg AS (
    SELECT
      s.s_store_id,
      d.d_date,
      d.d_year,
      i.i_item_id,
      td.t_hour,
      SUM(sa.total_sales_amount) AS sales_amount,
      COALESCE(SUM(sr.sr_return_amt), 0) AS store_return_amount,
      COALESCE(SUM(wr.wr_return_amt), 0) AS web_return_amount,
      (SUM(sa.total_sales_amount) - COALESCE(SUM(sr.sr_return_amt), 0) - COALESCE(SUM(wr.wr_return_amt), 0)) AS net_revenue
    FROM sales_agg sa
    JOIN item i
      ON sa.cs_item_sk = i.i_item_sk
    JOIN date_dim d
      ON sa.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim td
      ON sa.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN store_returns sr
      ON sr.sr_item_sk = i.i_item_sk
      AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN time_dim td_sr
      ON sr.sr_return_time_sk = td_sr.t_time_sk
    LEFT JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN web_returns wr
      ON wr.wr_item_sk = i.i_item_sk
      AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN time_dim td_wr
      ON wr.wr_returned_time_sk = td_wr.t_time_sk
    LEFT JOIN reason r
      ON r.r_reason_sk = COALESCE(sr.sr_reason_sk, wr.wr_reason_sk)
    LEFT JOIN call_center cc
      ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp
      ON cp.cp_end_date_sk = d.d_date_sk
    LEFT JOIN promotion p
      ON p.p_start_date_sk = d.d_date_sk
      AND p.p_item_sk = i.i_item_sk
    LEFT JOIN customer c
      ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN customer_demographics cd
      ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN household_demographics hd
      ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN customer_address ca
      ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND cc.cc_market_manager = 'John Doe'
      AND p.p_discount_active = 'Y'
    GROUP BY GROUPING SETS (
      (s.s_store_id, d.d_date, d.d_year, i.i_item_id, td.t_hour),
      (s.s_store_id, d.d_date, d.d_year, td.t_hour),
      (s.s_store_id, d.d_year, td.t_hour)
    )
    HAVING SUM(sa.total_sales_amount) > 1000
  )
SELECT
  s_store_id,
  d_date,
  i_item_id,
  t_hour,
  sales_amount,
  store_return_amount,
  web_return_amount,
  net_revenue,
  RANK() OVER (PARTITION BY d_year ORDER BY net_revenue DESC) AS revenue_rank_year
FROM agg
ORDER BY net_revenue DESC
LIMIT 100
