WITH sales_agg AS (
  SELECT
    cd.cd_demo_sk,
    cd.cd_gender,
    cd.cd_education_status,
    hd.hd_demo_sk,
    hd.hd_vehicle_count,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    COUNT(*) AS sales_cnt
  FROM store_sales ss
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451088
  GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_education_status,
           hd.hd_demo_sk, hd.hd_vehicle_count
),
returns_agg AS (
  SELECT
    cd.cd_demo_sk,
    cd.cd_gender,
    cd.cd_education_status,
    hd.hd_demo_sk,
    hd.hd_vehicle_count,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS returns_cnt
  FROM web_returns wr
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE wr.wr_returned_date_sk BETWEEN 2450815 AND 2451088
  GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_education_status,
           hd.hd_demo_sk, hd.hd_vehicle_count
)
SELECT
  s.cd_gender,
  s.cd_education_status,
  s.hd_vehicle_count,
  s.total_net_profit,
  COALESCE(r.total_net_loss, 0) AS total_net_loss,
  s.total_net_profit - COALESCE(r.total_net_loss, 0) AS net_margin,
  s.sales_cnt,
  COALESCE(r.returns_cnt, 0) AS returns_cnt,
  RANK() OVER (ORDER BY (s.total_net_profit - COALESCE(r.total_net_loss, 0)) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.cd_demo_sk = r.cd_demo_sk
 AND s.hd_demo_sk = r.hd_demo_sk
WHERE s.total_net_profit > 1000
ORDER BY net_margin DESC
LIMIT 100
