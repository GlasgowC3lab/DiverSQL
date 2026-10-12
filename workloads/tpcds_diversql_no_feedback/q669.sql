WITH catalog_agg AS (
  SELECT
    i.i_category AS category,
    'catalog' AS return_type,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS cnt_returns,
    AVG(cr.cr_return_amount) AS avg_return_amount
  FROM catalog_returns cr
  JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN date_dim d_cc ON cc.cc_closed_date_sk = d_cc.d_date_sk
  WHERE d_ret.d_year = 2001
    AND i.i_brand_id IN (1, 2, 3)
    AND cc.cc_sq_ft > 1000000
    AND cc.cc_mkt_id BETWEEN 2 AND 5
  GROUP BY i.i_category
),
web_agg AS (
  SELECT
    i.i_category AS category,
    'web' AS return_type,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS cnt_returns,
    AVG(wr.wr_return_amt) AS avg_return_amount
  FROM web_returns wr
  JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN call_center cc ON cc.cc_closed_date_sk = d_ret.d_date_sk
  JOIN date_dim d_cc ON cc.cc_open_date_sk = d_cc.d_date_sk
  WHERE d_ret.d_month_seq BETWEEN 1200 AND 1220
    AND i.i_color = 'Red'
    AND cc.cc_mkt_desc LIKE '%Rich%'
    AND wr.wr_reversed_charge > 50
  GROUP BY i.i_category
),
unioned AS (
  SELECT DISTINCT category, return_type, total_net_loss, cnt_returns, avg_return_amount
  FROM (
    SELECT * FROM catalog_agg
    UNION
    SELECT * FROM web_agg
  ) u
),
final AS (
  SELECT
    category,
    SUM(total_net_loss) AS sum_net_loss,
    SUM(cnt_returns) AS total_returns,
    AVG(avg_return_amount) AS avg_return_amount_overall
  FROM unioned
  GROUP BY category
  HAVING SUM(total_net_loss) > 10000
)
SELECT
  category,
  sum_net_loss,
  total_returns,
  avg_return_amount_overall
FROM final
ORDER BY sum_net_loss DESC
LIMIT 100
