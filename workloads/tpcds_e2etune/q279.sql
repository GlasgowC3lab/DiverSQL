WITH returns_by_cc_hour AS (
  SELECT
    cc.cc_class,
    t.t_hour,
    COUNT(*) AS return_cnt,
    SUM(sr.sr_return_amt) AS total_return_amt,
    AVG(sr.sr_net_loss) AS avg_net_loss,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers
  FROM store_returns sr
  JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN call_center cc ON d_ret.d_date_sk = cc.cc_open_date_sk
  WHERE d_ret.d_year = 2022
    AND cc.cc_class IN ('large', 'medium')
  GROUP BY cc.cc_class, t.t_hour
),
page_views_by_cc AS (
  SELECT
    cc.cc_class,
    COUNT(*) AS page_view_cnt
  FROM web_page wp
  JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
  JOIN call_center cc ON wp.wp_creation_date_sk = cc.cc_open_date_sk
  JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
  WHERE d_access.d_year = 2022
    AND cc.cc_class IN ('large', 'medium')
  GROUP BY cc.cc_class
)
SELECT
  r.cc_class,
  r.t_hour,
  r.return_cnt,
  r.total_return_amt,
  r.avg_net_loss,
  r.distinct_customers,
  pv.page_view_cnt,
  RANK() OVER (ORDER BY r.total_return_amt DESC) AS total_return_amt_rank
FROM returns_by_cc_hour r
LEFT JOIN page_views_by_cc pv ON r.cc_class = pv.cc_class
ORDER BY r.total_return_amt DESC
LIMIT 20
