WITH profit_by_cc AS (
  SELECT
    cc.cc_call_center_sk,
    cc.cc_state,
    cc.cc_class,
    cc.cc_gmt_offset,
    cc.cc_hours,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_quantity) AS avg_quantity,
    SUM(cs.cs_ext_sales_price) AS total_sales_price
  FROM
    call_center cc
    JOIN catalog_sales cs
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE
    cc.cc_state IN ('TN', 'GA', 'MI')
    AND cc.cc_class = 'large'
    AND cc.cc_gmt_offset = -5.00
    AND cc.cc_hours = '8AM-4PM'
    AND cs.cs_sold_date_sk BETWEEN 2459000 AND 2459125
    AND cs.cs_net_paid > 100
  GROUP BY
    cc.cc_call_center_sk,
    cc.cc_state,
    cc.cc_class,
    cc.cc_gmt_offset,
    cc.cc_hours
)
SELECT
  state,
  class,
  gmt_offset,
  hours,
  order_cnt,
  total_net_paid,
  total_net_profit,
  avg_quantity,
  total_sales_price,
  profit_rank
FROM (
  SELECT
    pb.cc_state AS state,
    pb.cc_class AS class,
    pb.cc_gmt_offset AS gmt_offset,
    pb.cc_hours AS hours,
    pb.order_cnt,
    pb.total_net_paid,
    pb.total_net_profit,
    pb.avg_quantity,
    pb.total_sales_price,
    ROW_NUMBER() OVER (PARTITION BY pb.cc_state ORDER BY pb.total_net_profit DESC) AS profit_rank
  FROM profit_by_cc pb
) ranked
WHERE profit_rank <= 5
ORDER BY state, profit_rank
