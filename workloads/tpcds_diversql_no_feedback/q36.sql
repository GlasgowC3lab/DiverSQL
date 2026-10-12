WITH agg AS (
  SELECT
    r.r_reason_id,
    r.r_reason_desc,
    cp.cp_catalog_number,
    cd.cd_demo_sk,
    cd.cd_gender,
    hd.hd_income_band_sk,
    hd.hd_vehicle_count,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_net_paid) AS total_net_paid,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN web_sales ws
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE cp.cp_catalog_number BETWEEN 10 AND 30
    AND cd.cd_gender = 'M'
    AND hd.hd_vehicle_count > 0
    AND r.r_reason_desc LIKE '%damaged%'
    AND cr.cr_return_amount > 5
    AND cr.cr_reason_sk IN (
      SELECT r2.r_reason_sk
      FROM reason r2
      WHERE r2.r_reason_desc LIKE '%damage%'
    )
  GROUP BY
    r.r_reason_id,
    r.r_reason_desc,
    cp.cp_catalog_number,
    cd.cd_demo_sk,
    cd.cd_gender,
    hd.hd_income_band_sk,
    hd.hd_vehicle_count
)
SELECT
  agg.r_reason_id,
  agg.r_reason_desc,
  agg.cp_catalog_number,
  agg.cd_gender,
  agg.hd_income_band_sk,
  agg.total_return_amount,
  agg.total_net_paid,
  agg.return_cnt,
  (
    SELECT SUM(ws2.ws_ext_discount_amt)
    FROM web_sales ws2
    WHERE ws2.ws_bill_cdemo_sk = agg.cd_demo_sk
  ) AS total_discount_for_customer_demo
FROM agg
WHERE agg.total_return_amount > 1000
  AND agg.return_cnt >= 10
  AND agg.hd_income_band_sk IS NOT NULL
  AND agg.cp_catalog_number <> 0
  AND EXISTS (
    SELECT 1
    FROM catalog_page cp3
    WHERE cp3.cp_description LIKE '%Urban%'
  )
ORDER BY agg.total_return_amount DESC
LIMIT 100
